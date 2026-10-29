#!/usr/bin/env bash
# Print the statement, its axioms and the fingerprint of its definitional closure.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
[ "$#" -le 1 ] || fail 'Pass exactly one source file.'
prepare_check "${1:-/input/ExactFitTarget.lean}"
build_target
body=/opt/tools/Fingerprint.body.lean
[ -f "$body" ] || fail "Missing $body"
echo 'SHA-256 of the fingerprint script body:'
sha256sum "$body"
{ echo 'import ExactFitTarget'; cat -- "$body"; } > Fingerprint.lean
echo '=== FINGERPRINT OUTPUT BEGIN ==='
set +e
lake env lean Fingerprint.lean
status=$?
set -e
echo '=== FINGERPRINT OUTPUT END ==='
if [ "$status" -ne 0 ]; then
  echo "The fingerprint script failed (exit $status)."
  exit "$status"
fi
echo 'Fingerprint printed (exit 0). The host compares it with reference/fingerprint-multi.txt.'
