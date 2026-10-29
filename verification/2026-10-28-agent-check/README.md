# Independent compilation, kernel replay and source scan

These records were produced by OpenAI Codex in an agent-operated environment, separately from the author's local run. They are not a human referee report or the output of a separately implemented proof checker. They concern the publicly released `ExactFitFull_2026_10_28_UTC.lean`, SHA-256 `b362a3ee35df68adad7aa24a1ddd288e63e4e59d074445aaafef4093e8462a2c`.

On 28 October 2026 UTC the exact source was copied, unchanged, to `ExactFitTarget.lean` in clean scratch storage. Lean `4.34.0-rc2` and the cached Mathlib at `664cbbe52927ce6acaa39ca35498336116e123b8` were used directly, without the Podman/Docker launcher.

- Full standalone compilation completed with exit 0 in 860.856 seconds. The complete log has one inherited tactic-style warning and no error. Maximum resident memory was 7,912,032 KiB.
- Ordinary `leanchecker -v ExactFitTarget` completed with exit 0 in 68.727 seconds. Its log explicitly records `replaying ExactFitTarget`.
- The fingerprint script imported the just-compiled module and completed with exit 0. Removing only Lean's source-message prefixes gives `fingerprint-normalized.txt`, byte-identical to the release's `exact-fit-local/reference/fingerprint-multi.txt`, SHA-256 `34e2fa7f3635b4f82eb985509eb7abad5e820413bc0eb34cd06241be172169d6`.
- A separate source scan on 28 October 2026 at 23:18 UTC (29 October in Paris) used the current public scanner, printed only the source basename and hash, and completed with exit 0. Its own result JSON identifies the scanner and source by SHA-256. This new scan does not repair or replace an earlier author's receipt.

The raw execution logs and result JSON files are copied unchanged. `SHA256SUMS` is a new inventory of the files in this evidence folder, not a digital signature or independent attestation.

Ordinary replay checks all project declarations because they are in one module; it trusts imported Mathlib and Lean-core declarations. No `FRESH=1` replay of the imports, container execution, or independently implemented kernel was performed in these records. Mathematical interpretation of the formal statement remains a reading task.
