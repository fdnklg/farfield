#!/bin/zsh
set -euo pipefail

: "${FARFIELD_DIR:?FARFIELD_DIR is required}"
: "${FARFIELD_NODE_BIN:?FARFIELD_NODE_BIN is required}"

ENV_FILE="${FARFIELD_ENV_FILE:-$HOME/.config/farfield/farfield.env}"
if [[ -f "$ENV_FILE" ]]; then
  set -a
  source "$ENV_FILE"
  set +a
fi

if [[ -n "${FARFIELD_BUN_BIN:-}" ]]; then
  BUN_BIN="$FARFIELD_BUN_BIN"
elif [[ -x "${FARFIELD_NODE_BIN:h}/bun" ]]; then
  BUN_BIN="${FARFIELD_NODE_BIN:h}/bun"
elif [[ -x "/opt/homebrew/bin/bun" ]]; then
  BUN_BIN="/opt/homebrew/bin/bun"
elif [[ -x "/usr/local/bin/bun" ]]; then
  BUN_BIN="/usr/local/bin/bun"
else
  echo "FARFIELD_BUN_BIN is not set and bun was not found in common locations." >&2
  echo "Set FARFIELD_BUN_BIN (for example: /opt/homebrew/bin/bun)." >&2
  exit 1
fi

if [[ ! -x "$BUN_BIN" ]]; then
  echo "Configured FARFIELD_BUN_BIN is not executable: $BUN_BIN" >&2
  exit 1
fi

export PATH="${BUN_BIN:h}:${FARFIELD_NODE_BIN:h}:/usr/bin:/bin:/usr/sbin:/sbin"
cd "$FARFIELD_DIR"

cleanup_stale_farfield_processes() {
  local -a patterns=(
    "$FARFIELD_DIR/scripts/dev.mjs --remote"
    "$FARFIELD_DIR/node_modules/.bin/tsx watch src/index.ts"
    "$FARFIELD_DIR/apps/web/node_modules/.bin/vite --host 0.0.0.0 --port 4312"
    "bun run --filter @farfield/server dev:remote"
    "bun run --filter @farfield/web dev:remote"
  )

  local -a pids=()
  local pattern
  local pid

  for pattern in "${patterns[@]}"; do
    while IFS= read -r pid; do
      [[ -z "$pid" ]] && continue
      [[ "$pid" == "$$" ]] && continue
      pids+=("$pid")
    done < <(pgrep -f -- "$pattern" || true)
  done

  if (( ${#pids[@]} == 0 )); then
    return
  fi

  pids=("${(@u)pids}")
  kill -TERM "${pids[@]}" 2>/dev/null || true
  sleep 1

  local -a remaining=()
  for pid in "${pids[@]}"; do
    if kill -0 "$pid" 2>/dev/null; then
      remaining+=("$pid")
    fi
  done

  if (( ${#remaining[@]} > 0 )); then
    kill -KILL "${remaining[@]}" 2>/dev/null || true
  fi
}

cleanup_stale_farfield_processes

exec "$FARFIELD_NODE_BIN" scripts/dev.mjs --remote
