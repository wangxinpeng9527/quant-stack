#!/usr/bin/env bash
set -euo pipefail

# ==================================================
# Resolve BASE dir (bats/.. → collector)
# ==================================================
BASE="$(cd "$(dirname "$0")/.." && pwd)"

# ====== Config ======
CDP_PORT="${CDP_PORT:-9222}"
CHROME_BIN="${CHROME_BIN:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"
CHROME_PROFILE="${CHROME_PROFILE:-/tmp/chrome-cdp}"

PY="$BASE/.venv/bin/python"
MODULE="app.main"

LOGDIR="$BASE/logs"
CONSOLE_LOG="$LOGDIR/collector.console.log"

export CDP_JSON="http://127.0.0.1:${CDP_PORT}/json"
export ENGINE_PUSH_URL="${ENGINE_PUSH_URL:-http://localhost:8080/engine/push}"
export POLL_SECONDS="${POLL_SECONDS:-1.0}"

mkdir -p "$LOGDIR"

echo "[start_all] BASE: $BASE"
echo "[start_all] PY: $PY"
echo "[start_all] MODULE: $MODULE"
echo "[start_all] CDP_JSON: $CDP_JSON"
echo "[start_all] ENGINE_PUSH_URL: $ENGINE_PUSH_URL"
echo "[start_all] LOG: $CONSOLE_LOG"

# ====== Checks ======
if [ ! -x "$PY" ]; then
  echo "[ERROR] venv python not found: $PY"
  echo "Create venv:"
  echo "  cd $BASE"
  echo "  python3 -m venv .venv"
  echo "  source .venv/bin/activate"
  echo "  pip install -r requirements.txt"
  exit 1
fi

if [ ! -d "$BASE/app" ]; then
  echo "[ERROR] app directory not found: $BASE/app"
  exit 1
fi

# ====== Start CDP Chrome if needed ======
if lsof -nP -iTCP:"$CDP_PORT" -sTCP:LISTEN >/dev/null 2>&1; then
  echo "[start_all] CDP port $CDP_PORT already listening."
else
  echo "[start_all] Starting Chrome CDP on port $CDP_PORT ..."
  nohup "$CHROME_BIN" \
    --remote-debugging-port="$CDP_PORT" \
    --user-data-dir="$CHROME_PROFILE" \
    --no-first-run \
    --no-default-browser-check \
    --disable-popup-blocking \
    >/dev/null 2>&1 &

  echo "[start_all] Waiting CDP..."
  for i in {1..20}; do
    if curl -s "http://127.0.0.1:${CDP_PORT}/json" >/dev/null 2>&1; then
      echo "[start_all] CDP ready."
      break
    fi
    sleep 0.3
  done
fi

# ====== Start collector ======
echo "[start_all] Starting collector..."
echo "----------------------------------------" >> "$CONSOLE_LOG"
echo "[start_all] $(date '+%Y-%m-%d %H:%M:%S') starting" >> "$CONSOLE_LOG"

"$PY" -m "$MODULE" 2>&1 | tee -a "$CONSOLE_LOG"
