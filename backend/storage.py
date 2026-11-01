"""Report storage. PostgreSQL when SCAMSHIELD_DATABASE_URL is set, otherwise a local SQLite file (dev/tests).

Example:  SCAMSHIELD_DATABASE_URL=postgresql://postgres:YOUR_PASSWORD@localhost:5432/scamshield
Text is redacted BEFORE it reaches this module.
"""
from __future__ import annotations

import os
import sqlite3
from contextlib import closing
from datetime import datetime, timezone
from pathlib import Path


def _database_url() -> str:
    return os.getenv("SCAMSHIELD_DATABASE_URL", "").strip()


def backend_name() -> str:
    return "postgresql" if _database_url() else "sqlite"


SQLITE_PATH = Path(os.getenv("SCAMSHIELD_DB", str(Path(__file__).resolve().parent / "reports.db")))

PG_SCHEMA = """
CREATE TABLE IF NOT EXISTS reports (
    id          BIGSERIAL PRIMARY KEY,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    title       TEXT NOT NULL,
    message     TEXT NOT NULL,
    channel     TEXT NOT NULL,
    label       TEXT NOT NULL,
    risk_score  INTEGER NOT NULL
)
"""

SQLITE_SCHEMA = """
CREATE TABLE IF NOT EXISTS reports (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    created_at TEXT NOT NULL,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    channel TEXT NOT NULL,
    label TEXT NOT NULL,
    risk_score INTEGER NOT NULL
)
"""


def _pg_connect():
    import psycopg  # imported lazily so SQLite-only setups do not need it

    conn = psycopg.connect(_database_url(), connect_timeout=5)
    conn.execute(PG_SCHEMA)
    conn.commit()
    return conn


def _sqlite_connect() -> sqlite3.Connection:
    conn = sqlite3.connect(SQLITE_PATH)
    conn.execute(SQLITE_SCHEMA)
    return conn


def save_report(title: str, message: str, channel: str, label: str, risk_score: int) -> int:
    if _database_url():
        with closing(_pg_connect()) as conn, conn.transaction():
            row = conn.execute(
                "INSERT INTO reports (title, message, channel, label, risk_score) VALUES (%s, %s, %s, %s, %s) RETURNING id",
                (title, message, channel, label, risk_score),
            ).fetchone()
            return int(row[0])
    with closing(_sqlite_connect()) as conn, conn:
        cur = conn.execute(
            "INSERT INTO reports (created_at, title, message, channel, label, risk_score) VALUES (?, ?, ?, ?, ?, ?)",
            (datetime.now(timezone.utc).isoformat(timespec="seconds"), title, message, channel, label, risk_score),
        )
        return int(cur.lastrowid)


def summary() -> dict:
    """Aggregate counts only. Stored message text is deliberately not exposed through the API."""
    if _database_url():
        with closing(_pg_connect()) as conn:
            total = conn.execute("SELECT COUNT(*) FROM reports").fetchone()[0]
            by_label = {r[0]: r[1] for r in conn.execute("SELECT label, COUNT(*) FROM reports GROUP BY label").fetchall()}
            by_channel = {r[0]: r[1] for r in conn.execute("SELECT channel, COUNT(*) FROM reports GROUP BY channel").fetchall()}
    else:
        with closing(_sqlite_connect()) as conn:
            total = conn.execute("SELECT COUNT(*) FROM reports").fetchone()[0]
            by_label = {r[0]: r[1] for r in conn.execute("SELECT label, COUNT(*) FROM reports GROUP BY label")}
            by_channel = {r[0]: r[1] for r in conn.execute("SELECT channel, COUNT(*) FROM reports GROUP BY channel")}
    return {"total": total, "by_label": by_label, "by_channel": by_channel, "database": backend_name()}


def check() -> dict:
    """Used by /health. Never raises."""
    try:
        summary()
        return {"database": backend_name(), "database_ok": True}
    except Exception as exc:  # noqa: BLE001
        return {"database": backend_name(), "database_ok": False, "database_error": type(exc).__name__}
