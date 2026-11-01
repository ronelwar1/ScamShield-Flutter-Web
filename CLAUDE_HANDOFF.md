# ScamShield — Claude Handoff / Project Brief

## Project identity and scope
ScamShield is a Flutter application for screening suspicious messages using natural language processing (NLP). Do not describe it as multilingual unless multilingual datasets and evaluations are added. The current initial scope is text classification, warning-signal explanations, and user safety guidance. The interface has a cheerful teal/mint theme with sunshine and coral accents.

## What was added in this build
- `backend/app.py`: FastAPI NLP API with `/health` and `/analyze` endpoints.
- `backend/data/messages.csv`: 61 small, illustrative examples labeled `scam` or `normal`. This is only starter/training data, not a research-quality dataset.
- `backend/train.py`: train and save a TF-IDF word/character n-gram + Logistic Regression baseline.
- `backend/model.joblib`: generated local model artifact (retrain with `python train.py` when data changes).
- `backend/evaluate.py`: simple stratified hold-out evaluation using classification report and confusion matrix.
- `backend/tests/`: API smoke tests.
- `lib/services/scam_analysis_service.dart`: Flutter HTTP client and result parsing.
- `lib/main.dart`: chat submit now calls the API and displays the model response; it explicitly reports connection errors rather than fabricating a verdict.
- `pubspec.yaml`: adds `http` dependency.
- `README.md`, `COMPLETION_ROADMAP.md`, this handoff guide.

## Current architecture
Flutter client -> HTTP POST `/analyze` -> FastAPI -> scikit-learn pipeline (TF-IDF word and char n-grams + Logistic Regression) -> label/probability, simple text-pattern signals, safety advice, limitations -> Flutter chat result.

API request: `{"text":"Your account is blocked. Send your OTP now."}`
API response contains `label`, `label_text`, `risk_score`, `model_scam_probability`, `signals`, `advice`, `model`, `limitations`.

Labels are `likely_scam`, `suspicious`, `no_obvious_scam_indicators`. Risk thresholds in `backend/app.py` are provisional and must be calibrated with a held-out validation set. `risk_score` is a model score, not a calibrated real-world probability. Never state that a low score proves safety.

## Run backend on Windows
Open PowerShell:
```powershell
cd backend
py -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
pip install -r requirements.txt
python train.py
uvicorn app:app --reload --host 0.0.0.0 --port 8000
```
Check `http://127.0.0.1:8000/health` and interactive API docs at `http://127.0.0.1:8000/docs`.

## Run Flutter
Open a second terminal at the project root:
```powershell
flutter pub get
flutter run -d chrome
```
For Android emulator, the client uses `http://10.0.2.2:8000`. For a physical phone, find the computer's LAN IP, ensure both devices share a network, and pass the URL when launching, for example:
```powershell
flutter run --dart-define=SCAMSHIELD_API_URL=http://192.168.1.25:8000
```
Replace the sample IP with the computer's actual LAN IP. Windows Firewall may need a local development rule for port 8000. Use HTTPS and restrictive CORS for deployment; do not deploy this prototype API openly as-is.

## Tests
From project root, after installing backend requirements:
```powershell
python -m pytest backend/tests -q
python backend/evaluate.py
```
Current backend smoke tests passed in the build environment. Flutter SDK was unavailable in the build environment, so Flutter compilation and browser/device integration have NOT been verified here. Run `flutter pub get`, `flutter analyze`, and `flutter test` locally.

## Known limitations / do not misrepresent
1. Dataset is only 61 hand-written illustrative examples. It is not enough to establish performance or a capstone result.
2. Model generalization will be weak and predictions may be overconfident. Replace/augment with a documented, licensed, labeled dataset and manually inspect data quality.
3. Only binary `normal` vs `scam` training labels currently exist; output's middle band is a threshold-based presentation category, not a separately trained class.
4. Language support is not guaranteed. Filipino/Taglish/Cebuano support must be tested with sufficient examples; no multilingual claim yet.
5. URL/sensitive-info/urgency/money/threat signals are rule-based supporting explanations, not proof of a scam.
6. Login/register UI is still UI-only. There is no backend account system, password storage, session handling, or password reset.
7. Report form is still not connected to durable storage. No scan-history database, admin dashboard, OCR/image upload, email/SMS reporting, or deployed hosting has been implemented.
8. No production rate limiting, audit controls, user authorization, or robust privacy/retention workflow. Avoid sending private messages to external services without consent.
9. The current CORS default is permissive for local development. Restrict it before deployment.
10. Risk score is not calibrated and should not be presented as the exact chance a message is a scam.

## Recommended order to finish
P0: install and verify app + backend; run tests; fix integration issues.
P1: acquire a quality licensed dataset, document sources, deduplicate, inspect labels, split train/validation/test without leakage; report precision/recall/F1 and confusion matrix.
P2: improve error states, loading, copyable results, safe links handling, accessibility; tune thresholds on validation data.
P3: persist reports and optional scan history with consent, deletion controls, and backend validation.
P4: add real auth only if required, using a secure established provider/password hashing and sessions rather than homemade plaintext storage.
P5: optional OCR; extract text locally or clearly disclose processing; never auto-open detected links.
P6: deployment with HTTPS, secrets/config management, CORS allowlist, rate limiting, monitoring, dependency pinning, privacy policy and abuse controls.
P7: only then test additional languages if supported by the research objective and dataset.

## How Claude should work on this repository
- Inspect the actual code before editing; do not rewrite the project from scratch without reason.
- Make small changes, explain changed files, and run tests after each meaningful step.
- Do not fabricate evaluation results or claim model accuracy without a reproducible test.
- Keep the app honest: if API unavailable, show connection failure, not a fake classification.
- Keep data privacy and safe-use guidance prominent.

## Revision 2 summary (read this first)
- Backend now: `backend/nlp.py` (all NLP logic, framework-free), `app.py` (thin FastAPI), `storage.py` (PostgreSQL via `SCAMSHIELD_DATABASE_URL`, SQLite fallback), `data/build_dataset.py` (synthetic grouped dataset; `data/seed_messages.csv` = original 61 rows), `evaluate.py` (GroupKFold), `schema.sql`, `run_backend.ps1`.
- API: `/analyze` (adds highlights, links, scam_type, top_terms, notes, rule_score), `/check-link`, `/reports` (needs `consent_to_store: true`; text redacted before storing), `/reports/summary`, `/model-info`, `/health`.
- Flutter: `lib/screens/*` (app_shell responsive layout with five destinations, scan, link checker, guide, history, recovery, report, auth UI-only), `lib/widgets/*`, `lib/services/*` (API client, HistoryStore via shared_preferences, Prefill bus), `lib/data/scam_knowledge.dart` (offline "how scams work" content, tips and recovery checklists). Removed stale `main - Copy.dart`, duplicate `login_screen.dart`, `home_screen.dart`.
- The database is PostgreSQL (the owner installed it). Reports are the only server-side data; scan history is on-device.
- Unverified here: Postgres path, FastAPI tests, all Flutter compilation. A read-through review found no compile errors but nothing was compiled. `InputDecorationTheme` in `lib/theme/app_theme.dart` may need to become `InputDecorationThemeData` on very new Flutter.
- Rule signals were tuned after seeing a small probe set, so `tests/test_nlp.py` is a regression suite, not an unbiased accuracy estimate. Do not quote the CV numbers as real-world accuracy.


## Revision 3 summary (latest)
- **Owner feedback addressed:** (1) everything, even YouTube, was being flagged suspicious; (2) no game: the Spot the Scam quiz is removed and "Learn the tricks" is now a plain "How scams work" reference (`lib/screens/guide_screen.dart`, `lib/data/scam_knowledge.dart`). Do not re-add quizzes, scores or streaks. (3) The owner asked what PostgreSQL is for: it only stores reports sent from the Report form, with consent. It is optional.
- **Cause of the false positives:** training data tied "has a link" to "scam", and the model sits near 0.5 on text it has not seen. Fixes in `backend/nlp.py`: `TRUSTED_DOMAINS` + `normalize_for_model` (trusted URLs become the token `trustedsite` at train and predict time), benign link/chat templates in `data/build_dataset.py`, `blend()` is now noisy-OR with a model-only cap (0.30, or 0.40 if p >= 0.9) when `rules < 0.10`, thresholds 0.33 / 0.50.
- **Regression tests** in `tests/test_nlp.py` cover everyday messages, YouTube/Zoom/Drive/Wikipedia/school links, look-alike domains that must still be caught, and "a known site does not excuse an OTP request". They were written after the fix, so they are regression tests, not proof of real-world accuracy.
- **Still unverified here:** all Flutter compilation (no SDK in the sandbox; the Dart was reviewed by hand only), the PostgreSQL path, and the FastAPI TestClient tests.
- The trusted-site list is a hand-picked allowlist and will miss legitimate sites that are not on it; extend it in `nlp.py` rather than loosening the thresholds.
