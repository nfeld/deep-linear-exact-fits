#!/usr/bin/env bash
# Shared container-side functions. Callers use set -euo pipefail.
EXACTFIT_PROJECT=${EXACTFIT_PROJECT:-/work/exactfitcheck}
EXACTFIT_CONFIG_DIR=${EXACTFIT_CONFIG_DIR:-/opt/project}
EXACTFIT_PIN=664cbbe52927ce6acaa39ca35498336116e123b8
EXACTFIT_TOOLCHAIN=leanprover/lean4:v4.34.0-rc2

fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

enter_project() {
  [ -d "$EXACTFIT_PROJECT" ] || fail 'Project missing; run ./exactfit.sh setup first.'
  cd "$EXACTFIT_PROJECT" || exit 1
  # Serialize access to the common build directory, including source replacement.
  exec 9> .exactfit-run.lock
  flock -n 9 || fail 'Another setup/check/editor operation holds the project lock.'
}

refresh_config() {
  [ -f "$EXACTFIT_CONFIG_DIR/lakefile.toml" ] || fail 'Mounted Lake configuration missing.'
  cp -- "$EXACTFIT_CONFIG_DIR/lakefile.toml" "$EXACTFIT_CONFIG_DIR/lean-toolchain" "$EXACTFIT_PROJECT/"
}

check_environment() {
  [ "$(cat lean-toolchain)" = "$EXACTFIT_TOOLCHAIN" ] || fail 'Unexpected Lean toolchain pin.'
  [ -f lake-manifest.json ] || fail 'Dependency manifest missing; run ./exactfit.sh setup.'
  local resolved
  resolved=$(git -C .lake/packages/mathlib rev-parse HEAD)
  [ "$resolved" = "$EXACTFIT_PIN" ] || fail "Mathlib is $resolved, expected $EXACTFIT_PIN. Run setup."
  git -C .lake/packages/mathlib diff --quiet HEAD -- || fail 'Mathlib has tracked modifications.'
}

# Reuse the dependencies of another Lake project in the same volume (for instance
# the O77 harness's /work/o77check), with hard links: nothing is downloaded or
# copied. Only a Mathlib checkout at the pinned commit, unmodified and compiled,
# is accepted.
seed_packages() {
  local seed=$1 pkgs rev
  pkgs="$seed/.lake/packages"
  [ -d "$pkgs/mathlib" ] || fail "EXACTFIT_SEED=$seed: no Mathlib checkout in $pkgs."
  rev=$(git -C "$pkgs/mathlib" rev-parse HEAD) || fail "EXACTFIT_SEED: cannot read the Mathlib revision in $pkgs."
  [ "$rev" = "$EXACTFIT_PIN" ] || fail "EXACTFIT_SEED: Mathlib in $pkgs is $rev, expected $EXACTFIT_PIN."
  git -C "$pkgs/mathlib" diff --quiet HEAD -- || fail "EXACTFIT_SEED: Mathlib in $pkgs has tracked modifications."
  [ -f "$pkgs/mathlib/.lake/build/lib/lean/Mathlib.olean" ] \
    || fail "EXACTFIT_SEED: Mathlib in $pkgs is not compiled; run that project's setup first."
  mkdir -p .lake
  cp -al -- "$pkgs" .lake/packages \
    || fail 'Hard-linking the seed packages failed (both projects must be in the same volume).'
  echo "Seeded .lake/packages from $pkgs with hard links (nothing downloaded or copied)."
}

# Say whether Mathlib's compiled files are shared, through hard links, with another
# project of the volume (after setup with EXACTFIT_SEED).
report_sharing() {
  local f=.lake/packages/mathlib/.lake/build/lib/lean/Mathlib.olean links
  if [ -f "$f" ]; then
    links=$(stat -c %h "$f")
    if [ "$links" -gt 1 ]; then
      echo "Mathlib's compiled files are shared with another project of this volume (hard links: $links)."
    else
      echo "Mathlib's compiled files belong to this project only."
    fi
  fi
}

print_environment() {
  printf 'UTC: '; date -u +%Y-%m-%dT%H:%M:%SZ
  printf 'Toolchain pin: '; cat lean-toolchain
  lean --version
  lake --version
  printf 'Mathlib HEAD: '; git -C .lake/packages/mathlib rev-parse HEAD
  report_sharing
  echo 'Configuration / resolved manifest hashes:'
  sha256sum lean-toolchain lakefile.toml lake-manifest.json
  echo 'Resolved dependency manifest (JSON):'
  cat lake-manifest.json
  printf '\n'
}

copy_source() {
  local src=$1 tmp
  [ -f "$src" ] || fail "Source missing: $src"
  tmp=$(mktemp "$EXACTFIT_PROJECT/.ExactFitTarget.XXXXXX")
  # Do not continue with an old ExactFitTarget if a read/copy fails.
  if ! cp -- "$src" "$tmp"; then
    rm -f -- "$tmp"
    fail 'Source copy failed; no build was attempted.'
  fi
  if ! cmp -s -- "$src" "$tmp"; then
    rm -f -- "$tmp"
    fail 'Copied source differs from input; no build was attempted.'
  fi
  # Keep the old file (and hence Lake's up-to-date check) if the content is unchanged.
  if [ -f "$EXACTFIT_PROJECT/ExactFitTarget.lean" ] && cmp -s -- "$tmp" "$EXACTFIT_PROJECT/ExactFitTarget.lean"; then
    rm -f -- "$tmp"
  else
    mv -f -- "$tmp" "$EXACTFIT_PROJECT/ExactFitTarget.lean"
  fi
  echo 'SHA-256 of the exact copied source:'
  sha256sum ExactFitTarget.lean
}

prepare_check() {
  enter_project
  refresh_config
  check_environment
  print_environment
  copy_source "$1"
}

build_target() {
  echo '==> lake build ExactFitTarget'
  if time lake build ExactFitTarget; then
    echo 'Build exit status: 0'
  else
    local status=$?
    echo "Build failed (exit $status)."
    exit "$status"
  fi
}
