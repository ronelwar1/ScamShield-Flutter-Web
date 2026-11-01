# ScamShield 🛡️

A cheerful Flutter app (phone, tablet and web) that screens suspicious messages and links using **natural language processing (NLP)**, explains the warning signs in plain language, and tells you what to do next.

> **Experimental prototype.** A low score never proves a message is safe. The model is English-first: Filipino/Taglish wording is only lightly covered and has **not** been evaluated, so this project does not claim multilingual support.

## Features

| Feature | What it does |
|---|---|
| **Check a message** | Paste text and get a risk indicator (0-100), a likely scam type, the warning phrases highlighted in your message, an explanation for each signal, and tailored advice. Copy the result or report it. |
| **Link checker** | Static analysis of a URL: shorteners, raw IPs, look-alike brand domains (e.g. `gcash-verify.top`), punycode, hidden `@` destinations, suspicious endings. It never opens the link. |
| **How scams work** | An offline reference, not a game: the usual pattern behind scams, why they work on careful people, and 8 scam types explained step by step. |
| **I think I got scammed** | Step-by-step checklists (shared a code, sent money, clicked a link, gave remote access, shared ID). |
| **History** | Past checks saved **on the device only**, with a switch to turn it off and a clear-all button. |
| **Report form** | Optional. Sends a message to the server only with explicit consent; emails, long numbers and OTP-like codes are masked before storage. |
| **Responsive** | Bottom bar on phones, navigation rail on tablets, side bar on desktop and web. |

## How it works

```
Flutter app ──HTTP──> FastAPI (backend/app.py)
                        ├─ nlp.py      TF-IDF word + character n-grams + Logistic Regression,
                        │              blended with transparent rule signals and URL analysis
                        └─ storage.py  user-submitted reports only: PostgreSQL if configured, else SQLite
```

- Checking a message or link **never touches the database**. The database only holds reports someone chose to send from the Report form. Check history stays on the device.
- **Score:** `score = 1 - (1 - rules) x (1 - 0.6 x model_part)`. If no rule fires, the model alone can raise the score only to "be careful", never to "likely scam", so ordinary messages are not flagged just because the model is unsure. Thresholds: 0.33 suspicious, 0.50 likely scam (provisional, not calibrated).
- **Well-known sites** (YouTube, Google, Zoom, Wikipedia and similar, plus `.gov.ph` and `.edu.ph`) are treated as ordinary links. Look-alikes of them (`youtube.com.evil.top`) are still flagged, and a known site does not excuse a message that asks for your OTP or password.
- **Endpoints:** `GET /health`, `POST /analyze`, `POST /check-link`, `POST /reports`, `GET /reports/summary`, `GET /model-info`. Interactive docs at `/docs`.

## Project layout

```
lib/                 Flutter app (screens, widgets, services, offline content)
backend/
  nlp.py             all NLP logic (model, rules, link analysis, redaction)
  app.py             FastAPI layer
  storage.py         report storage (PostgreSQL / SQLite)
  train.py           trains and saves the model
  evaluate.py        grouped cross-validation, writes metrics.json
  data/              messages.csv + build_dataset.py (+ original seed_messages.csv)
  tests/             pytest suite
test/                Flutter tests
```

## Run it (Windows)

You need Python 3.10+, the Flutter SDK, and optionally PostgreSQL.

### 1. Database (optional)

Skip this and reports go to a local SQLite file (`backend/reports.db`); everything else works the same. pgAdmin is **not** needed to run the app, it is only a viewer.

To use PostgreSQL, make sure the PostgreSQL service is running, then create an empty database (pgAdmin or `psql`):

```sql
CREATE DATABASE scamshield;
```

The API creates the `reports` table itself (`backend/schema.sql` is there if you prefer to run it by hand).

### 2. Backend (PowerShell, `backend` folder)

```powershell
.\run_backend.ps1 -DbPassword "YOUR_POSTGRES_PASSWORD"
```

That script creates the virtual environment, installs requirements, trains the model and starts the server. Or do it manually:

```powershell
py -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
$env:SCAMSHIELD_DATABASE_URL = "postgresql://postgres:YOUR_PASSWORD@localhost:5432/scamshield"
python train.py
uvicorn app:app --reload --host 0.0.0.0 --port 8000
```

Open `http://127.0.0.1:8000/health`. It should show `"database": "postgresql"` and `"database_ok": true`. If it shows `"sqlite"`, the variable was not set in the terminal that started the server (the backend does not read `.env` files by itself).

### 3. Flutter (project root, second terminal)

```powershell
flutter pub get
flutter run -d chrome
```

The Android emulator uses `http://10.0.2.2:8000` automatically. For a physical phone use your computer's LAN IP and allow port 8000 in Windows Firewall:

```powershell
flutter run --dart-define=SCAMSHIELD_API_URL=http://192.168.1.25:8000
```

### Configuration

| Variable | Purpose |
|---|---|
| `SCAMSHIELD_DATABASE_URL` | PostgreSQL connection string. Unset means SQLite. |
| `SCAMSHIELD_DB` | Path of the SQLite file when PostgreSQL is not used. |
| `SCAMSHIELD_CORS_ORIGINS` | Allowed web origins. Set an allow-list before any public deployment. |
| `SCAMSHIELD_RATE_LIMIT` | Requests per minute per IP. |

Never commit real passwords. `.env.example` shows the format.

## Tests and evaluation

```powershell
python -m pytest backend/tests -q     # NLP core + API (API tests are skipped if fastapi/httpx are missing)
python backend/evaluate.py            # grouped cross-validation, writes backend/metrics.json
flutter analyze
flutter test
```

## Dataset

`backend/data/messages.csv` is **synthetic**: 542 messages (253 scam, 289 normal) in 194 template groups, built from 61 hand-written seed rows plus template variants by `backend/data/build_dataset.py`. Columns: `text`, `label`, `group`, `category`. Almost all of it is English.

## Honest limitations

- The dataset is synthetic and the rules were written by the same author, so the metrics describe fit to *this* data, not real-world accuracy. A research claim needs a documented, licensed real dataset and a held-out test set.
- The score is **not** a calibrated probability. Rule signals and link checks are heuristics, not proof, and the link check is text-only (it cannot see the page).
- The trusted-site list is hand-picked and incomplete: an unfamiliar legitimate site can still be flagged, and a hijacked account on a trusted site is invisible to this check.
- Login/register is UI-only (no accounts backend). The app works fully as a guest.
- No admin review dashboard, OCR or production hardening yet. Rate limiting is a simple per-process limiter; use HTTPS, an origin allow-list and real authentication before any public deployment.
- Messages you check are sent to *your* ScamShield server. Reports are stored only after the user consents, with secrets masked.
- The Flutter code and the PostgreSQL path were written without a compiler or database in the build environment. Run `flutter analyze` and `flutter test` locally and report anything that fails.

See `CLAUDE_HANDOFF.md` and `COMPLETION_ROADMAP.md` for status and next steps.