"""ScamShield NLP API (FastAPI). Thin HTTP layer over nlp.py. Prototype; not a guarantee of safety."""
from __future__ import annotations

import json
import os
import time
from collections import defaultdict, deque
from typing import Any, Literal, Optional

from fastapi import Depends, FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

import nlp
import storage

MAX_CHARS = 5000
RATE_LIMIT = int(os.getenv("SCAMSHIELD_RATE_LIMIT", "60"))  # requests per minute per client
VERSION = "0.2.0"

app = FastAPI(
    title="ScamShield NLP API",
    description="Experimental natural-language screening service for suspicious messages and links.",
    version=VERSION,
)
app.add_middleware(
    CORSMiddleware,
    # Development default is permissive. Set SCAMSHIELD_CORS_ORIGINS to a comma-separated allow-list when deploying.
    allow_origins=[o.strip() for o in os.getenv("SCAMSHIELD_CORS_ORIGINS", "*").split(",") if o.strip()],
    allow_credentials=False,
    allow_methods=["GET", "POST"],
    allow_headers=["*"],
)

model = nlp.load_model()

# ---- very small in-memory rate limiter (per process; use a real gateway in production) ----
_hits: dict[str, deque[float]] = defaultdict(deque)


def rate_limit(request: Request) -> None:
    if RATE_LIMIT <= 0:
        return
    client = request.client.host if request.client else "unknown"
    now = time.monotonic()
    window = _hits[client]
    while window and now - window[0] > 60:
        window.popleft()
    if len(window) >= RATE_LIMIT:
        raise HTTPException(status_code=429, detail="Too many requests. Please wait a minute and try again.")
    window.append(now)


# ---- schemas ----
class AnalyzeRequest(BaseModel):
    text: str = Field(min_length=3, max_length=MAX_CHARS)


class SpanOut(BaseModel):
    start: int
    end: int


class SignalOut(BaseModel):
    id: str
    name: str
    explanation: str
    severity: Literal["high", "medium", "low", "info"]
    spans: list[SpanOut] = []


class HighlightOut(BaseModel):
    start: int
    end: int
    signals: list[str]


class FindingOut(BaseModel):
    name: str
    explanation: str
    severity: Literal["high", "medium", "low"]


class LinkOut(BaseModel):
    url: str
    host: str
    registered_domain: str
    verdict: Literal["high_risk", "suspicious", "no_obvious_issues"]
    verdict_text: str
    findings: list[FindingOut]


class ScamTypeOut(BaseModel):
    id: str
    name: str
    summary: str


class AnalyzeResponse(BaseModel):
    label: Literal["likely_scam", "suspicious", "no_obvious_scam_indicators"]
    label_text: str
    risk_score: int
    model_scam_probability: float
    rule_score: float
    signals: list[SignalOut]
    highlights: list[HighlightOut]
    links: list[LinkOut]
    scam_type: Optional[ScamTypeOut] = None
    top_terms: list[str]
    advice: list[str]
    notes: list[str]
    model: str
    limitations: str


class LinkRequest(BaseModel):
    url: str = Field(min_length=3, max_length=2048)


class ReportRequest(BaseModel):
    title: str = Field(default="", max_length=120)
    message: str = Field(min_length=5, max_length=MAX_CHARS)
    channel: Literal["sms", "email", "social", "call", "other"] = "other"
    consent_to_store: bool = Field(description="Must be true. The text is stored (with codes/numbers masked) to help improve ScamShield.")


# ---- routes ----
@app.get("/health")
def health() -> dict[str, Any]:
    return {"status": "ok", "service": "ScamShield NLP API", "version": VERSION, "model_loaded": model is not None, **storage.check()}


@app.post("/analyze", response_model=AnalyzeResponse, dependencies=[Depends(rate_limit)])
def analyze(request: AnalyzeRequest) -> dict[str, Any]:
    text = request.text.strip()
    if len(text) < 3:
        raise HTTPException(status_code=422, detail="Please provide a message with at least 3 characters.")
    try:
        return nlp.analyze_message(model, text)
    except RuntimeError as exc:
        raise HTTPException(status_code=500, detail=str(exc)) from exc


@app.post("/check-link", response_model=LinkOut, dependencies=[Depends(rate_limit)])
def check_link(request: LinkRequest) -> dict[str, Any]:
    """Static inspection of a URL string. The link is never opened or fetched."""
    return nlp.link_to_dict(nlp.analyze_url(request.url))


@app.post("/reports", status_code=201, dependencies=[Depends(rate_limit)])
def create_report(request: ReportRequest) -> dict[str, Any]:
    if not request.consent_to_store:
        raise HTTPException(status_code=422, detail="Consent is required before a report can be stored.")
    redacted = nlp.redact_sensitive(request.message.strip())
    result = nlp.analyze_message(model, request.message.strip())
    title = request.title.strip() or "Untitled report"
    report_id = storage.save_report(nlp.redact_sensitive(title), redacted, request.channel, result["label"], result["risk_score"])
    return {"id": report_id, "status": "received", "label": result["label"], "risk_score": result["risk_score"],
            "stored_text": redacted,
            "note": "Thank you. Codes, emails and long numbers were masked before saving."}


@app.get("/reports/summary", dependencies=[Depends(rate_limit)])
def reports_summary() -> dict[str, Any]:
    return storage.summary()


@app.get("/model-info")
def model_info() -> dict[str, Any]:
    path = nlp.ROOT / "metrics.json"
    metrics = json.loads(path.read_text()) if path.exists() else None
    return {"model": nlp.MODEL_NAME, "limitations": nlp.LIMITATIONS, "metrics": metrics,
            "thresholds": {"likely_scam": nlp.LIKELY_THRESHOLD, "suspicious": nlp.SUSPICIOUS_THRESHOLD}}
