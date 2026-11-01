# ScamShield — Current Status and Completion Roadmap

## Status (revision 3)

Done:
- Responsive Flutter app (phone / tablet / desktop) in a cheerful teal-mint theme with sunshine and coral accents.
- Features: message checker with highlighted warning phrases, scam-type detection, link checker, "How scams work" reference (no quiz or game), "I think I got scammed" recovery checklists, on-device history with privacy switch, consent-based report form. Five tabs: Check, Links, Guide, History, Help.
- Backend: `nlp.py` (model + 16 rule signals + URL analysis + trusted-site handling + redaction), `app.py` (FastAPI, rate limit), `storage.py` (reports only; PostgreSQL optional, SQLite fallback).
- Revision 3 fixed everyday messages and links to well-known sites (YouTube, Zoom, Google Drive...) being flagged as suspicious: trusted-site allowlist, benign link/chat training data, a noisy-OR blend, and a cap on what the model can add when no rule fired.
- Dataset v3 (542 rows, 194 template groups), grouped-CV `evaluate.py`, 50 passing NLP tests (+ API tests that need FastAPI installed, skipped otherwise).

Not verified in the build sandbox (no PyPI / Flutter SDK access): the PostgreSQL path, the FastAPI TestClient tests, and every Flutter compile/run step. Run `flutter pub get`, `flutter analyze`, `flutter test`, `python -m pytest backend/tests -q` locally first.

Still missing: real labelled dataset + held-out test; real authentication; admin review workflow for stored reports; OCR/image input; production hardening/deployment; Filipino/Taglish evaluation.

---
# Previous revision notes (kept for history)


## What is implemented in this revision

- Cheerful teal/mint theme with sunshine, coral, and sky-blue accent tokens.
- Flutter chat now calls a Python FastAPI endpoint rather than returning a fabricated placeholder verdict.
- `lib/services/scam_analysis_service.dart` provides HTTP request handling, timeout/error handling, and typed parsing of analysis results.
- `backend/app.py` provides `/health` and `/analyze` endpoints.
- Baseline NLP pipeline: TF-IDF word and character n-grams + Logistic Regression.
- Transparent rule-based warning signals for URLs, urgency, credentials, financial requests/rewards, and threats.
- A small starter dataset, reproducible training script, evaluation script, API smoke tests, and Claude handoff guide.

## Current model status — important

`backend/data/messages.csv` has only 61 hand-written illustrative examples. It proves the end-to-end training and API path, but it is not a research-quality dataset and cannot support credible claims of accuracy or real-world reliability. The model's risk score is not calibrated as a real-world probability. Thresholds are provisional. The UI must never imply that a low score proves a message is safe.

This project is scoped as NLP, not automatically multilingual. Language coverage is not guaranteed. Do not claim Filipino, Taglish, or Cebuano support until the model has sufficient representative data and evaluation for those language groups.

## Implemented vs still missing

### Implemented at prototype level
- Flutter chat-style interface and cheerful responsive theme.
- Text entry and call to a real local API.
- FastAPI request validation, `/health`, `/analyze`, CORS setting, model inference.
- Baseline model training and model artifact generation.
- Basic rule-based explanations and safety guidance.
- API smoke tests and an illustrative evaluation script.

### Still missing or incomplete
1. **Research-quality dataset:** a documented, licensed, representative dataset with inspected labels and class-balance review.
2. **Credible model evaluation:** leakage-resistant train/validation/test split, threshold tuning, per-class precision/recall/F1, confusion matrix, error analysis, and a written model card.
3. **Real account system:** login/register remains UI-only. There is no password hashing, session handling, password reset, or authorization.
4. **Report persistence:** the report form is still not connected to a database or durable report endpoint.
5. **History and privacy controls:** no persisted scan history, consent flow, retention policy, or user-driven deletion.
6. **Production API protection:** no rate limiting, abuse protection, production HTTPS configuration, or restrictive CORS allowlist. Current settings are for local development.
7. **OCR/image upload:** not implemented; optional and should follow core text classification.
8. **Admin/review workflow:** no report review dashboard or status tracking.
9. **Flutter verification:** Flutter SDK was unavailable during this build; run `flutter pub get`, `flutter analyze`, and `flutter test` locally.
10. **Deployment:** no hosted backend/frontend configuration, production monitoring, or privacy policy.

## Run locally

See `README.md` for Windows setup. Start the backend first, then the Flutter app. The API is local-only by default for development.

## Recommended build order

### Phase 0 — Verify integration
- Install dependencies and start the backend.
- Test `/health` and `/docs`.
- Run backend tests.
- Run Flutter `pub get`, `analyze`, and `test`; resolve any compile/runtime issues.

### Phase 1 — Improve the NLP research
- Obtain a properly licensed and relevant labeled dataset.
- Document provenance, allowed use, labels, preprocessing, deduplication, and class balance.
- Split data before model tuning; avoid near-duplicate leakage.
- Compare TF-IDF + Logistic Regression with at least one reasonable baseline.
- Tune thresholds on validation data and report final metrics on held-out test data.
- Include false-positive and false-negative analysis.

### Phase 2 — Make results more useful
- Improve result cards, copy/share controls, and accessible color/labels.
- Make the risk score wording explicitly experimental unless calibrated.
- Add tests for empty, short, long, normal, scam-like, and uncertain messages.
- Keep safe next steps prominent; never auto-open suspicious links.

### Phase 3 — Complete reports and privacy
- Decide whether reports need persistence for the capstone.
- Add backend validation and database only if required.
- Explain data collection, minimize retained message content, and add deletion controls.
- Add rate limiting and access controls before any public deployment.

### Phase 4 — Optional features
- Add OCR for screenshots only after the core model works.
- Add real authentication only if required, using a reputable auth provider or properly designed secure backend.
- Add an admin review queue only if the research workflow requires it.
- Add more languages only when supported by data and measured evaluation.

## Definition of done
- A submitted message reaches the actual NLP model and the UI displays its response.
- API and Flutter tests cover success, error, timeout, and validation states.
- Dataset provenance and license are documented.
- Model evaluation is reproducible and reports metrics without exaggeration.
- Users see limitations and actionable safety advice.
- Any stored personal data has a clear purpose, consent, retention, and deletion mechanism.
- Production deployment uses HTTPS, restrictive CORS, secrets management, rate limits, and monitoring.
