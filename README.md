# ScamShield

## Summary
ScamShield: A Natural Language Processing-Based Suspicious Message
Classification and Risk Screening System for Messages. Users paste a
suspicious message and receive a risk screening (classification, risk level,
confidence, explanation). This first checkpoint contains only the Flutter Web
starter: Home (S-01 baseline) and Login (S-04 baseline) screens.

## Current stack
- Implemented: Flutter Web / Dart (starter UI, routing, reusable widgets)
- Planned (not implemented): FastAPI REST API, PostgreSQL

## Run locally
```
flutter pub get
flutter run -d chrome
```

## Source layout (`lib/`)
- `main.dart` – entry point
- `app.dart` – MaterialApp, theme, routing setup
- `screens/` – Home, Login, Not Found
- `widgets/` – AppButton, AppTextField
- `services/` – future API client
- `models/` – client-side data models
- `routes/` – route names and generator
- `constants/` – app-wide constants (no secrets)

## Team
Jian Rainier C. Dablo · Ashley Joyd C. Pullos · Ronel S. Silvosa

## First Checkpoint
Date: October 15, 2026 Commit: 113b29f
