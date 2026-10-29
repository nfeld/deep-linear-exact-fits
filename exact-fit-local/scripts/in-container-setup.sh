#!/usr/bin/env bash
# Network-enabled setup; ordinary checking runs use network=none.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
mkdir -p "$EXACTFIT_PROJECT"
enter_project
refresh_config
lake --version
# Optional: reuse the compiled Mathlib of another Lake project in this volume.
if [ -n "${EXACTFIT_SEED:-}" ]; then
  if [ -e .lake/packages ]; then
    echo "EXACTFIT_SEED ignored: $EXACTFIT_PROJECT/.lake/packages already exists."
  else
    seed_packages "$EXACTFIT_SEED"
    # The pinned manifest (the one `lake update` produces for this project) makes
    # `lake update`, and hence Mathlib's post-update hook `cache get`, unnecessary.
    [ -f lake-manifest.json ] || cp -- "$EXACTFIT_CONFIG_DIR/lake-manifest.json" lake-manifest.json
    echo "$EXACTFIT_SEED" > .lake/exactfit-seeded-from
  fi
fi
# Reuse an existing manifest only if Mathlib already has the required revision.
resolved=$(git -C .lake/packages/mathlib rev-parse HEAD 2>/dev/null || true)
if [ ! -f lake-manifest.json ] || [ "$resolved" != "$EXACTFIT_PIN" ]; then
  lake update mathlib
fi
check_environment
print_environment
if [ -f .lake/exactfit-seeded-from ]; then
  # The compiled files come from the seed project, whose own setup fetched them;
  # `cache get` here would only download the archives again.
  echo "Mathlib cache not fetched: the compiled files come from $(cat .lake/exactfit-seeded-from)."
else
  lake exe cache get
fi
warm=$(mktemp "$EXACTFIT_PROJECT/ExactFitWarmXXXXXX.lean")
trap 'rm -f -- "$warm"' EXIT
printf 'import Mathlib\n' > "$warm"
lake env lean "$warm"
echo 'Setup completed. The dependency volume is ready for offline checking.'
