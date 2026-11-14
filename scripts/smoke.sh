#!/usr/bin/env bash
# Smoke test: validate the kit, create a sandbox, check Pi, run a prompt, tear down.
# Requires credential bindings (see README Prerequisites).
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
KIT="${KIT:-$repo_root}"
NAME="${NAME:-pi-smoke}"
WORKSPACE="${WORKSPACE:-$(mktemp -d)}"
PROMPT="${PROMPT:-Reply with exactly: OK}"
EXPECT="${EXPECT:-OK}"
BUILDX_BUILDER="${BUILDX_BUILDER:-sbx-kit}"
export BUILDX_BUILDER

cleanup() {
  sbx rm "$NAME" --force >/dev/null 2>&1 || true
}
trap cleanup EXIT

run() { sbx exec "$NAME" -- bash -lc "$1"; }

echo "== validate =="
sbx kit validate "$KIT"

echo "== create =="
sbx rm "$NAME" --force >/dev/null 2>&1 || true
sbx run --name "$NAME" -d "$KIT" "$WORKSPACE"

echo "== tools =="
run 'pi --version' | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$'
run 'fd --version'
run 'jq --version'
run 'git config --get credential.https://github.com.helper'

echo "== settings =="
run 'jq -e "has(\"defaultProvider\") and has(\"defaultModel\") and has(\"defaultThinkingLevel\")" \
  /home/agent/.pi/agent/settings.json' >/dev/null

echo "== mcp =="
run 'test -s /home/agent/.pi/agent/mcp.json'
run 'grep -q mcp-gateway.docker.internal /home/agent/.pi/agent/mcp.json'
mcp="$(run 'timeout 60 pi mcp list')"
printf '%s\n' "$mcp"
printf '%s' "$mcp" | grep -q "connected"

echo "== prompt =="
out="$(run "pi-headless -p \"$PROMPT\"")"
printf '%s\n' "$out"
printf '%s' "$out" | grep -q "$EXPECT"

echo "== smoke test passed =="
