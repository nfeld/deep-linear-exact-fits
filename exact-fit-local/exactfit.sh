#!/usr/bin/env bash
# Local container workflow for checking the single-file extraction of the
# exact-fit classification, MAIS.ExactFitStatement.exact_fit_classification.
# Adapted from the O77 harness (github.com/nfeld/mais-o77-lean, folder o77-local).
set -euo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ENGINE=${EXACTFIT_ENGINE:-podman}
IMAGE=${EXACTFIT_IMAGE:-exactfit-lean:latest}
VOLUME=${EXACTFIT_VOLUME:-exactfit-lean}
LOG_DIR=${EXACTFIT_LOG_DIR:-$HERE/logs}
REFERENCE=${EXACTFIT_REFERENCE:-$HERE/reference/fingerprint-multi.txt}

die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
info() { printf '==> %s\n' "$*"; }
no_args() { [ "$#" -eq 0 ] || die 'Unexpected extra arguments.'; }

case "$ENGINE" in
  podman) RO=${EXACTFIT_MOUNT_RO:-ro,Z} ;;
  docker) RO=${EXACTFIT_MOUNT_RO:-ro} ;;
  *) die 'EXACTFIT_ENGINE must be podman or docker.' ;;
esac
need_engine() { command -v "$ENGINE" >/dev/null || die "Install $ENGINE first (see README.md)."; }

usage() {
  cat <<'HELP'
Usage: ./exactfit.sh COMMAND [arguments]
  preflight          show local prerequisites and available resources
  build              build the container image (network required)
  setup              fetch the pinned Lean toolchain, Mathlib and its cache (network required)
  doctor             check the resolved environment, offline
  scan FILE.lean     list risky Lean constructs in FILE (host side, Python 3; no container)
  verify FILE.lean   elaborate FILE once, offline
  recheck FILE.lean  build FILE as a module, then replay it with leanchecker, offline
  audit FILE.lean    print the statement, its axioms and the fingerprint of its
                     definitional closure, and compare with reference/fingerprint-multi.txt
  all FILE.lean      scan, recheck and audit, then write a receipt (logs/receipt-*.txt)
  manifest           print the resolved Lake manifest
  shell              open an offline shell in the dependency volume
  clean              remove this workflow's image and dependency volume
  help               show this message
Environment:
  EXACTFIT_ENGINE    podman (default) or docker
  FRESH=1            recheck also replays Mathlib and Lean core (leanchecker --fresh; slow)
  EXACTFIT_IMAGE     container image name (default: exactfit-lean:latest)
  EXACTFIT_VOLUME    dependency volume (default: exactfit-lean)
  EXACTFIT_SEED      setup only: a Lake project in the same volume whose compiled Mathlib
                     (same pinned commit) is reused through hard links instead of being
                     downloaded again, e.g. /work/o77check in the O77 volume o77-lean
  EXACTFIT_LOG_DIR   directory for new logs (default: ./logs)
  EXACTFIT_MOUNT_RO  options of read-only bind mounts (default: ro,Z for podman, ro for docker)
HELP
}

cmd_preflight() {
  no_args "$@"
  command -v "$ENGINE" >/dev/null && "$ENGINE" --version || echo "$ENGINE: not installed"
  command -v python3 >/dev/null && python3 --version || echo 'Python 3: missing (needed for scan)'
  if [ -r /proc/meminfo ]; then
    awk '/MemTotal/ {printf "RAM: %.1f GiB\n", $2/1048576}' /proc/meminfo
  fi
  df -h "$HERE"
  echo 'RAM: about 8 GB. Disk for a fresh dependency volume: about 11 GB (measured: Lean'
  echo 'toolchain 2.9 GB, Mathlib and its dependencies 7.9 GB, build of the file 0.13 GB),'
  echo 'plus the image and temporary space while setup downloads: keep about 15 GB free.'
  echo 'If the O77 volume o77-lean exists (same Lean and Mathlib pins), reuse it instead'
  echo '(no download, about 0.15 GB more):'
  echo '  export EXACTFIT_VOLUME=o77-lean; EXACTFIT_SEED=/work/o77check ./exactfit.sh setup'
}

cmd_build() {
  no_args "$@"; need_engine
  "$ENGINE" build -t "$IMAGE" -f "$HERE/Containerfile" "$HERE"
}

cmd_setup() {
  no_args "$@"; need_engine
  if ! "$ENGINE" volume inspect "$VOLUME" >/dev/null 2>&1; then
    "$ENGINE" volume create "$VOLUME" >/dev/null
  fi
  "$ENGINE" run --rm --security-opt=no-new-privileges \
    -v "$VOLUME":/work \
    -v "$HERE/project:/opt/project:$RO" \
    -v "$HERE/scripts:/opt/scripts:$RO" \
    -e EXACTFIT_SEED="${EXACTFIT_SEED:-}" \
    "$IMAGE" bash /opt/scripts/in-container-setup.sh
}

cmd_scan() {
  [ "$#" -eq 1 ] || die 'Usage: ./exactfit.sh scan FILE.lean'
  [ -f "$1" ] || die "No such source file: $1"
  python3 "$HERE/tools/scan_lean_source.py" "$1"
}

# Run one offline check in the container; the log name is printed on stdout's last line.
run_check() {
  local action=$1 src=$2 abs log
  [ -f "$src" ] || die "No such source file: $src"
  need_engine
  abs=$(readlink -f -- "$src")
  # A colon is the -v delimiter; refuse ambiguous bind-mount paths.
  [[ "$abs" != *:* && "$HERE" != *:* ]] || die 'Bind-mount paths must not contain a colon.'
  [[ "${FRESH:-0}" = 0 || "${FRESH:-0}" = 1 ]] || die 'FRESH must be 0 or 1.'
  mkdir -p "$LOG_DIR"
  log=$(mktemp "$LOG_DIR/${action}-$(date -u +%Y%m%dT%H%M%SZ)-XXXXXX.log")
  {
    printf 'UTC: '; date -u +%Y-%m-%dT%H:%M:%SZ
    printf 'Action: %s\nInput basename: %s\n' "$action" "$(basename "$abs")"
    printf 'Host source SHA-256: '; sha256sum "$abs" | cut -d' ' -f1
    printf 'FRESH: %s\n' "${FRESH:-0}"
    "$ENGINE" --version
    printf 'Container image ID: '; "$ENGINE" image inspect --format '{{.Id}}' "$IMAGE"
    echo 'Harness scripts/configuration hashes:'
    (cd "$HERE" && sha256sum exactfit.sh Containerfile project/lakefile.toml project/lean-toolchain \
      scripts/*.sh tools/Fingerprint.body.lean tools/scan_lean_source.py)
  } > "$log"
  info "Checking $(basename "$abs") ($action); log: $log" >&2
  local -a statuses
  # Keep both exit statuses: tee must not hide a failed check.
  set +e
  "$ENGINE" run --rm --network=none --security-opt=no-new-privileges \
    -v "$VOLUME":/work \
    -v "$abs:/input/ExactFitTarget.lean:$RO" \
    -v "$HERE/scripts:/opt/scripts:$RO" \
    -v "$HERE/project:/opt/project:$RO" \
    -v "$HERE/tools:/opt/tools:$RO" \
    -e FRESH="${FRESH:-0}" \
    "$IMAGE" bash "/opt/scripts/in-container-${action}.sh" /input/ExactFitTarget.lean \
    2>&1 | tee -a "$log" >&2
  statuses=("${PIPESTATUS[@]}")
  set -e
  printf 'Container/check exit status: %s; log writer exit status: %s\n' \
    "${statuses[0]}" "${statuses[1]}" | tee -a "$log" >&2
  LAST_LOG=$log
  if [ "${statuses[0]}" -ne 0 ]; then return "${statuses[0]}"; fi
  return "${statuses[1]}"
}

# Extract the fingerprint printed by in-container-audit.sh, without Lean's
# message headers (which contain the file name), into $2.
extract_fingerprint() {
  sed -n '/^=== FINGERPRINT OUTPUT BEGIN ===$/,/^=== FINGERPRINT OUTPUT END ===$/p' "$1" \
    | sed '1d;$d' \
    | sed -E 's/^[^ :]*\.lean:[0-9]+:[0-9]+: (info|warning|error): //' > "$2"
}

compare_fingerprint() {
  local log=$1 out
  out="${log%.log}.fingerprint.txt"
  extract_fingerprint "$log" "$out"
  [ -s "$out" ] || { echo 'No fingerprint output found in the log.' | tee -a "$log" >&2; return 1; }
  if [ ! -s "$REFERENCE" ]; then
    echo "Fingerprint reference missing or empty: $REFERENCE; comparison failed." | tee -a "$log" >&2
    FINGERPRINT_RESULT='FAILED (missing or empty reference)'
    return 1
  fi
  if diff -u "$REFERENCE" "$out" > "${out%.txt}.diff"; then
    rm -f "${out%.txt}.diff"
    echo "FINGERPRINT MATCH: identical to $(basename "$REFERENCE") (SHA-256 $(sha256sum "$REFERENCE" | cut -d' ' -f1))." \
      | tee -a "$log" >&2
    FINGERPRINT_RESULT="match with reference $(sha256sum "$REFERENCE" | cut -d' ' -f1)"
    return 0
  fi
  echo "FINGERPRINT MISMATCH: see ${out%.txt}.diff" | tee -a "$log" >&2
  FINGERPRINT_RESULT='MISMATCH'
  return 1
}

cmd_check() {
  local action=$1; shift
  [ "$#" -eq 1 ] || die "Usage: ./exactfit.sh $action FILE.lean (exactly one file)"
  run_check "$action" "$1"
  if [ "$action" = audit ]; then compare_fingerprint "$LAST_LOG"; fi
  info "Full log: $LAST_LOG"
}

cmd_all() {
  [ "$#" -eq 1 ] || die 'Usage: ./exactfit.sh all FILE.lean (exactly one file)'
  local src=$1 abs scanlog receipt
  abs=$(readlink -f -- "$src")
  mkdir -p "$LOG_DIR"
  scanlog=$(mktemp "$LOG_DIR/scan-$(date -u +%Y%m%dT%H%M%SZ)-XXXXXX.log")
  info "Scanning $(basename "$abs"); log: $scanlog"
  cmd_scan "$abs" | tee "$scanlog"
  run_check recheck "$abs"; local recheck_log=$LAST_LOG
  run_check audit "$abs"; local audit_log=$LAST_LOG
  FINGERPRINT_RESULT='not run'
  local fp_status=0
  compare_fingerprint "$audit_log" || fp_status=$?
  receipt="$LOG_DIR/receipt-$(date -u +%Y%m%dT%H%M%SZ).txt"
  {
    echo 'Receipt of a local check of the exact-fit classification (single-file extraction)'
    printf 'UTC: '; date -u +%Y-%m-%dT%H:%M:%SZ
    printf 'Input file: %s\n' "$(basename "$abs")"
    printf 'Input SHA-256: %s\n' "$(sha256sum "$abs" | cut -d' ' -f1)"
    printf 'Theorem: MAIS.ExactFitStatement.exact_fit_classification\n'
    printf 'Container engine: %s\n' "$("$ENGINE" --version)"
    printf 'Container image ID: %s\n' "$("$ENGINE" image inspect --format '{{.Id}}' "$IMAGE")"
    grep -m1 '^Lean (version' "$recheck_log" || echo 'Lean version: not found in log'
    grep -m1 '^Mathlib HEAD:' "$recheck_log" || echo 'Mathlib HEAD: not found in log'
    printf 'Scan: %s\n' "$(tail -n 1 "$scanlog")"
    printf 'Build of the module (includes the #guard_msgs axiom check): %s\n' \
      "$(grep -m1 '^Build exit status' "$recheck_log" || echo 'not found')"
    printf 'Kernel replay, leanchecker%s: %s\n' "$([ "${FRESH:-0}" = 1 ] && echo ' --fresh' || true)" \
      "$(grep -m1 '^Kernel replay exit status' "$recheck_log" || echo 'not found')"
    printf 'Axioms printed by the audit: %s\n' \
      "$(grep -m1 "exact_fit_classification' depends on axioms" "$audit_log" | sed -E 's/^.*(.MAIS\.ExactFitStatement)/\1/' || echo 'not found')"
    printf 'Fingerprint of the definitional closure: %s\n' "$FINGERPRINT_RESULT"
    echo 'SHA-256 of the logs:'
    (cd "$LOG_DIR" && sha256sum "$(basename "$scanlog")" "$(basename "$recheck_log")" \
      "$(basename "$audit_log")" "$(basename "${audit_log%.log}.fingerprint.txt")")
    echo 'This receipt records what was run and what it printed. It does not certify that'
    echo 'the statement expresses the intended mathematics; see CERTIFICATE.md.'
  } > "$receipt"
  info "Receipt: $receipt"
  cat "$receipt"
  return "$fp_status"
}

cmd_doctor() {
  no_args "$@"; need_engine
  "$ENGINE" run --rm --network=none --security-opt=no-new-privileges \
    -v "$VOLUME":/work -v "$HERE/scripts:/opt/scripts:$RO" \
    "$IMAGE" bash /opt/scripts/in-container-doctor.sh
}

cmd_manifest() {
  no_args "$@"; need_engine
  "$ENGINE" run --rm --network=none --security-opt=no-new-privileges \
    -v "$VOLUME":/work:ro "$IMAGE" cat /work/exactfitcheck/lake-manifest.json
}

cmd_shell() {
  no_args "$@"; need_engine
  "$ENGINE" run --rm -it --network=none --security-opt=no-new-privileges \
    -v "$VOLUME":/work -w /work/exactfitcheck "$IMAGE" bash
}

cmd_clean() {
  no_args "$@"; need_engine
  info "Removing only image $IMAGE and volume $VOLUME. Sources and logs are kept."
  "$ENGINE" rmi "$IMAGE"
  "$ENGINE" volume rm "$VOLUME"
}

case "${1:-help}" in
  help|--help|-h) usage ;;
  preflight) shift; cmd_preflight "$@" ;;
  build) shift; cmd_build "$@" ;;
  setup) shift; cmd_setup "$@" ;;
  doctor) shift; cmd_doctor "$@" ;;
  scan) shift; cmd_scan "$@" ;;
  verify|recheck|audit) action=$1; shift; cmd_check "$action" "$@" ;;
  all) shift; cmd_all "$@" ;;
  manifest) shift; cmd_manifest "$@" ;;
  shell) shift; cmd_shell "$@" ;;
  clean) shift; cmd_clean "$@" ;;
  *) die "Unknown command: $1 (use ./exactfit.sh help)" ;;
esac
