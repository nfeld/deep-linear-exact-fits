#!/usr/bin/env bash
# Elaborate the copied source once, without producing a compiled module.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
[ "$#" -le 1 ] || fail 'Pass exactly one source file.'
prepare_check "${1:-/input/ExactFitTarget.lean}"
echo '==> lake env lean -DmaxErrors=0 ExactFitTarget.lean'
if time lake env lean -DmaxErrors=0 ExactFitTarget.lean; then
  echo 'ELABORATION PASSED (exit 0). Read the log for any warning.'
  echo 'The #guard_msgs check of the axioms at the end of the file was part of this run.'
else
  status=$?
  echo "Elaboration failed (exit $status)."
  exit "$status"
fi
