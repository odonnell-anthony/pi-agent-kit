#!/usr/bin/env bash
# Smoke test: validate the kit, create a sandbox, check Pi, run a prompt, tear down.
# Requires credential bindings (see README Prerequisites).
set -euo pipefail

KIT="${KIT:-./pi-agent}"
NAME="${NAME:-pi-smoke}"
WORKSPACE="${WORKSPACE:-$(mktemp -d)}"
PROMPT="${PROMPT:-Reply with exactly: OK}"
EXPECT="${EXPECT:-OK}"
BUILDX_BUILDER="${BUILDX_BUILDER:-sbx-kit}"

cleanup() {
  sbx rm "$NAME" --force >/dev/null 2>&1 || true
}
trap cleanup EXIT

echo "== validate =="
BUILDX_BUILDER="$BUILDX_BUILDER" sbx kit validate "$KIT"

echo "== create =="
sbx rm "$NAME" --force >/dev/null 2>&1 || true
sbx run --name "$NAME" -d "$KIT" "$WORKSPACE"

echo "== pi version =="
sbx exec "$NAME" -- bash -lc 'pi --version' | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$'

echo "== prompt =="
out="$(sbx exec "$NAME" -- bash -lc "pi-headless -p \"$PROMPT\"")"
printf '%s\n' "$out"
printf '%s' "$out" | grep -q "$EXPECT"

echo "== smoke test passed =="
