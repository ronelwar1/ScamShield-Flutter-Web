# Starts the ScamShield API on Windows PowerShell.
# Usage (from the backend folder):  .\run_backend.ps1 -DbPassword "your_postgres_password"
param(
    [string]$DbPassword = "",
    [string]$DbName = "scamshield",
    [string]$DbUser = "postgres",
    [string]$DbHost = "localhost",
    [int]$DbPort = 5432
)
if (-not (Test-Path .venv)) {
    py -m venv .venv
}
. .\.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
pip install -r requirements.txt
if ($DbPassword -ne "") {
    $env:SCAMSHIELD_DATABASE_URL = "postgresql://${DbUser}:${DbPassword}@${DbHost}:${DbPort}/${DbName}"
    Write-Host "Using PostgreSQL database '$DbName' on ${DbHost}:${DbPort}"
} else {
    Write-Host "No -DbPassword given: reports will use the local SQLite fallback (reports.db)."
}
python train.py
uvicorn app:app --reload --host 0.0.0.0 --port 8000
