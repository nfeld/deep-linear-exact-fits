# Provenance of the reference snapshot

The primary proof artifact of this public release is
[`ExactFitFull_2026_10_28_UTC.lean`](../../ExactFitFull_2026_10_28_UTC.lean).
The local audit recomputes the reference output from that file. No access to
the earlier multi-file source or its checking environment is needed for this
released-file check.

| Item | SHA-256 or version |
| --- | --- |
| Released Lean source | `b362a3ee35df68adad7aa24a1ddd288e63e4e59d074445aaafef4093e8462a2c` |
| `tools/Fingerprint.body.lean` | `c9ec8599321e4d48407bc0df7141e8bc6b167d93ac21f3767828c14fd8c85dba` |
| `fingerprint-multi.txt` | `34e2fa7f3635b4f82eb985509eb7abad5e820413bc0eb34cd06241be172169d6` |
| Lean | `4.34.0-rc2` |
| Mathlib commit | `664cbbe52927ce6acaa39ca35498336116e123b8` |

The snapshot was originally printed with `import O7.ExactFitStatement` by the
same fingerprint script in the multi-file development, and its output was
compared successfully with the single-file output. This file preserves the
snapshot's content hash; it does not assert that this public repository contains
that earlier source tree, its workflow, or its complete build environment.

It lists 79 project definitions, inductive types and constructors; 17 distinct
theorem statements occurring in them; and 263 external non-theorem constants.
The endpoint type is printed with notation and with `pp.all`, and its proof's
axioms are printed. The structural hashes are noncryptographic and use the
normalizations documented in `tools/Fingerprint.body.lean`.

If the script or released theorem changes, recompute and review the comparison
rather than silently replacing the snapshot. A successful comparison tests
consistency with the frozen statement; the mathematical interpretation is
reviewed in the preprint's Appendix A.
