-- Optional: the API creates this table automatically on first use. Run manually if you prefer.
-- psql -U postgres -c "CREATE DATABASE scamshield;"
-- psql -U postgres -d scamshield -f schema.sql
CREATE TABLE IF NOT EXISTS reports (
    id          BIGSERIAL PRIMARY KEY,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    title       TEXT NOT NULL,
    message     TEXT NOT NULL,      -- already redacted by the API (codes, emails, long numbers masked)
    channel     TEXT NOT NULL,      -- sms | email | social | call | other
    label       TEXT NOT NULL,      -- likely_scam | suspicious | no_obvious_scam_indicators
    risk_score  INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS reports_created_at_idx ON reports (created_at DESC);
