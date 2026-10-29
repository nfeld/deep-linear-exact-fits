#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
enter_project
check_environment
print_environment
echo 'Resolved Lean toolchain pin and Mathlib commit match the required values.'
