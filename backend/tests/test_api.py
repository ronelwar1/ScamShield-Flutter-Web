import sys
from pathlib import Path

import pytest

pytest.importorskip("fastapi")
pytest.importorskip("httpx")
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from fastapi.testclient import TestClient  # noqa: E402


@pytest.fixture()
def client(tmp_path, monkeypatch):
    monkeypatch.setenv("SCAMSHIELD_DB", str(tmp_path / "reports.db"))
    monkeypatch.setenv("SCAMSHIELD_RATE_LIMIT", "0")
    for name in ("storage", "app"):
        sys.modules.pop(name, None)
    import app as app_module
    return TestClient(app_module.app)


def test_health(client):
    r = client.get("/health")
    assert r.status_code == 200 and r.json()["status"] == "ok"


def test_analyze_returns_guidance(client):
    r = client.post("/analyze", json={"text": "Your account is blocked. Send your OTP immediately to claim your prize."})
    assert r.status_code == 200
    data = r.json()
    assert data["label"] in {"likely_scam", "suspicious", "no_obvious_scam_indicators"}
    assert 0 <= data["risk_score"] <= 100 and data["signals"] and data["advice"]
    assert "does not prove" in data["limitations"]


def test_rejects_too_short_message(client):
    assert client.post("/analyze", json={"text": "a"}).status_code == 422


def test_check_link(client):
    r = client.post("/check-link", json={"url": "http://secure-bdo-verify.top/login"})
    assert r.status_code == 200 and r.json()["verdict"] == "high_risk"


def test_report_requires_consent(client):
    r = client.post("/reports", json={"message": "Send your OTP now please", "consent_to_store": False})
    assert r.status_code == 422


def test_report_is_stored_redacted_and_counted(client):
    r = client.post("/reports", json={"title": "Odd SMS", "message": "Send OTP 482913 to 09171234567 now", "channel": "sms", "consent_to_store": True})
    assert r.status_code == 201
    body = r.json()
    assert "482913" not in body["stored_text"] and "09171234567" not in body["stored_text"]
    summary = client.get("/reports/summary").json()
    assert summary["total"] == 1 and summary["by_channel"]["sms"] == 1


def test_rate_limit(client, monkeypatch):
    import app as app_module
    monkeypatch.setattr(app_module, "RATE_LIMIT", 2)
    app_module._hits.clear()
    codes = [client.post("/check-link", json={"url": "example.com"}).status_code for _ in range(3)]
    assert codes == [200, 200, 429]
