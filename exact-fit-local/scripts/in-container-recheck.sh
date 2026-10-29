#!/usr/bin/env bash
# Build the copied source as a module, then replay its declarations in the kernel.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
[ "$#" -le 1 ] || fail 'Pass exactly one source file.'
FRESH=${FRESH:-0}
[[ "$FRESH" = 0 || "$FRESH" = 1 ]] || fail 'FRESH must be 0 or 1.'
prepare_check "${1:-/input/ExactFitTarget.lean}"
build_target
checker=(lake env leanchecker)
if [ "$FRESH" = 1 ]; then
  checker+=(--fresh)
  echo '==> Kernel replay of every declaration of ExactFitTarget AND of everything it imports (Mathlib, core).'
else
  echo '==> Kernel replay of every declaration of ExactFitTarget, starting from its imports (Mathlib, core).'
fi
checker+=(ExactFitTarget)
if time "${checker[@]}"; then
  echo 'Kernel replay exit status: 0'
else
  status=$?
  echo "Kernel replay failed (exit $status). Keep the complete log."
  exit "$status"
fi
cat <<'MSG'
KERNEL RE-CHECK PASSED.
- The build elaborated the whole file, including its final #guard_msgs check that
  the theorem depends exactly on the axioms [propext, Classical.choice, Quot.sound].
- leanchecker then replayed, with Lean's kernel, every declaration of the file.
  Since the file contains the whole project part of the proof, this covers all of it;
  Mathlib and Lean core are replayed only with FRESH=1.
- leanchecker reuses Lean's own kernel: it is a second run, not an independent checker.
- Nothing here says that the statement means what the preprint says it means.
  That is the translation of Appendix A, which is checked by reading.
MSG
