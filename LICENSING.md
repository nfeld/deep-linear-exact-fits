# Licensing and attribution

Copyright 2026 Niels Feld and the respective contributors, to the extent that
copyright subsists in their contributions and they hold the relevant rights.

## Code: Apache License 2.0

The Lean source `ExactFitFull_2026_10_28_UTC.lean`, the shell and Python
scripts, the container and Lake configuration in `exact-fit-local/`, and other
software in this repository are licensed under the Apache License, Version 2.0
(SPDX: `Apache-2.0`). The full license is in [LICENSE](LICENSE).

The module `O77Full_2026_10_06_20_50_UTC` inside the single file is copied from
[nfeld/mais-o77-lean](https://github.com/nfeld/mais-o77-lean), under the same
license. The container harness is adapted from the `o77-local` harness of that
repository.

## Documentation, logs and the preprint: CC BY 4.0

The README files, `CERTIFICATE.md`, the receipts and logs, and the preprint are licensed under Creative Commons Attribution 4.0 International (SPDX:
`CC-BY-4.0`), except for code listings and third-party material. The full legal
text is in [LICENSE-DOCS](LICENSE-DOCS).

## Third-party software

The proof depends on, but does not contain, Lean 4 and Mathlib and their
dependencies (Batteries, Aesop, Qq, ProofWidgets, Plausible, ImportGraph,
LeanSearchClient, Cli), which are downloaded at their pinned versions by the
harness and remain under their own licenses (Apache 2.0).

The file `paper/ulem.sty`, by Donald Arseneau, is distributed under the
permissions in its original header, which are preserved. It is not relicensed
under the repository's Apache or Creative Commons license. The visual comparison
was generated using latexdiff by F. Tilmann and contributors; that program is
not bundled with this release.
