# Checking the exact-fit classification locally

This harness checks the released Lean file
[`ExactFitFull_2026_10_28_UTC.lean`](../ExactFitFull_2026_10_28_UTC.lean), whose
main theorem is `MAIS.ExactFitStatement.exact_fit_classification`. It is adapted
from the `o77-local/` harness of
[nfeld/mais-o77-lean](https://github.com/nfeld/mais-o77-lean).

The single file contains all project proof declarations and imports only
Mathlib. Its header lists the hashes of the source modules from which it was
assembled. Checking this release requires this file and the pinned dependencies;
it does not require access to any other project repository.

## Quick start

On Linux with Bash, Python 3 and rootless Podman:

```bash
cd exact-fit-local
chmod +x exactfit.sh
./exactfit.sh preflight
./exactfit.sh build          # network: Ubuntu tools and elan
./exactfit.sh setup          # network: pinned Lean, Mathlib and its cache
./exactfit.sh doctor         # offline
./exactfit.sh all ../ExactFitFull_2026_10_28_UTC.lean
```

With Docker, prefix each command with `EXACTFIT_ENGINE=docker`.

A fresh dependency volume occupies about 11 GB, plus the image and temporary
download space; allow about 15 GB free. A standalone compilation has used about
7.6 GiB of RAM, so leave memory headroom. Build time depends on the machine;
recorded builds took roughly 12–17 minutes, followed by one to two minutes of
ordinary kernel replay.

`all` scans the source, builds the target, replays its declarations, audits the
statement, compares its fingerprint, and writes `logs/receipt-<UTC>.txt`.
Require an explicit `FINGERPRINT MATCH`: a receipt alone is not evidence that
all intended checks passed. The current driver can report “not compared” when
the reference is missing; this release includes the required reference. Check
it before running:

```bash
test -s reference/fingerprint-multi.txt
```

Keep the complete logs named by the receipt. A repeated build may reuse an
unchanged target; the replay and fingerprint audit still run.

## Reusing the O77 volume

If the O77 harness already installed the same Lean and Mathlib versions into
its rootless-Podman volume `o77-lean`, reuse those dependencies as follows:

```bash
cd exact-fit-local
chmod +x exactfit.sh
export EXACTFIT_VOLUME=o77-lean
./exactfit.sh build
EXACTFIT_SEED=/work/o77check ./exactfit.sh setup
./exactfit.sh doctor
./exactfit.sh all ../ExactFitFull_2026_10_28_UTC.lean
```

The seed check requires the pinned, tracked-clean Mathlib checkout and its
compiled `Mathlib.olean`. It hard-links the seed's dependency packages into the
new project and uses the supplied manifest, avoiding the cache download. The
extra build occupies approximately 0.13 GB.

Both harnesses then have write access to the same volume and share dependency
files. Do not run them concurrently. **Never run `clean` while selecting
`o77-lean`: it removes the entire selected volume, including O77.** For separate
storage, use the default volume and omit `EXACTFIT_SEED`.

## Commands

| Command | Meaning |
| --- | --- |
| `preflight` | Prints prerequisites and estimated resources. |
| `build` | Builds the tool image; needs network access. |
| `setup` | Installs or reuses pinned dependencies; needs network access. |
| `doctor` | Checks the toolchain pin, Mathlib revision and tracked source cleanliness; prints versions and manifest. It does not verify every compiled cache file. |
| `scan FILE` | Host-side Python scan for proof escapes, metaprogramming, options, imports and unusual Unicode. A lexical scan is a reading aid, not a proof that arbitrary code is inert. |
| `verify FILE` | Elaborates the source once. |
| `recheck FILE` | Builds the target if necessary, then replays all declarations of its module with `leanchecker`. `FRESH=1` also replays imported dependencies. |
| `audit FILE` | Prints the main statement, its axioms and the fingerprint of its definitions; compares the result with the reference snapshot. |
| `all FILE` | Runs scan, recheck and audit, and writes the receipt and logs. |

The final source guard requires the axiom list
`[propext, Classical.choice, Quot.sound]`. An axiom-list match does not establish
that the statement expresses the intended mathematics; read Appendix A of the
[preprint](../paper/README.md).

## Pins

| Component | Pin |
| --- | --- |
| Lean | `leanprover/lean4:v4.34.0-rc2` |
| Mathlib | `664cbbe52927ce6acaa39ca35498336116e123b8` |
| Lean source SHA-256 | `b362a3ee35df68adad7aa24a1ddd288e63e4e59d074445aaafef4093e8462a2c` |
| Reference fingerprint SHA-256 | `34e2fa7f3635b4f82eb985509eb7abad5e820413bc0eb34cd06241be172169d6` |

The Ubuntu image and elan installer are not pinned by digest. Lean and Mathlib
are pinned; the operating-system image is not byte-identical across builds.

## Isolation and trust

Checking containers use an unprivileged user, `--network=none`, and
`--security-opt=no-new-privileges`. Source, scripts, tools and configuration are
mounted read-only. The dependency volume is writable. The host home directory
and container-engine socket are not mounted. The context ignore files restrict
the image build context to `Containerfile`.

Lean elaboration can execute metaprograms. For unrelated files, use a separate
volume and review the source; the absence of scanner findings is not a general
security guarantee. Kernel replay uses the same Lean kernel as compilation.
The ordinary replay trusts imported Mathlib/core declarations; `FRESH=1` replays
those too. Neither is an independently implemented checker.

The fingerprint script prints the statement, axioms, and structural hashes of
its controlling definitions. The bundled snapshot was imported from the earlier
multi-file check; the local run independently reproduces it from this release.
The hash is not cryptographic and does not replace a mathematical specification
review. [Reference details](reference/PROVENANCE.md) and
[CERTIFICATE.md](CERTIFICATE.md) explain this distinction.

## Files and attribution

- `exactfit.sh`: host launcher; `scripts/`: container-side checks.
- `project/`: pinned Lake configuration and resolved dependency manifest.
- `tools/`: scanner and fingerprint script.
- `reference/`: imported fingerprint snapshot and its provenance.
- `logs/`: generated local logs. Inspect them before deliberately publishing a
  selected run; new logs are ignored by Git by default.

Claude (Anthropic) wrote this harness under Niels Feld's direction, adapting the
O77 harness. The preprint's AI use disclosure records the wider contributions.
