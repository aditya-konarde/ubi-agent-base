#!/usr/bin/env bash
set -euo pipefail
herdr --version
python3.12 --version
uv --version
rg --version
sudo -n true
uv venv --python python3.12 /tmp/smoke-venv
/tmp/smoke-venv/bin/python -c 'import sys; assert sys.version_info[:2] == (3, 12)'
herdr server >/tmp/herdr-server.log 2>&1 &
server_pid=$!
trap 'kill "$server_pid" 2>/dev/null || true' EXIT
for attempt in {1..50}; do
  if workspace=$(herdr workspace create --cwd /home/exedev --label smoke --no-focus 2>/dev/null); then break; fi
  sleep 0.1
done
pane=$(printf '%s' "$workspace" | jq -er '.result.root_pane.pane_id')
herdr pane run "$pane" "python3.12 -c 'from pathlib import Path; Path(\"/tmp/herdr-smoke-result\").write_text(\"ok\")'"
for attempt in {1..50}; do
  if test -f /tmp/herdr-smoke-result; then break; fi
  sleep 0.1
done
test "$(cat /tmp/herdr-smoke-result)" = ok
herdr pane read "$pane"
echo 'Herdr shell execution and Python environment passed.'
