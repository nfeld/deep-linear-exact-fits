# Deep linear networks are mildly singular at every exact fit

**Niels Feld.** The mathematical text and formal proofs were developed with AI
assistance; the [preprint](paper/README.md) contains the author's AI use disclosure.

This repository contains a Lean 4 / Mathlib proof of the exact-fit classification
for deep linear networks and a container harness for checking it locally. The
main declaration is `MAIS.ExactFitStatement.exact_fit_classification` in
[`ExactFitFull_2026_10_28_UTC.lean`](ExactFitFull_2026_10_28_UTC.lean). The preprint
has not been refereed.

The result concerns the pointwise question in the
[Math for AI Safety](https://github.com/Math-for-AI-Safety/MAIS) problems
MAIS-O70 and MAIS-O77(a), in arbitrary depth. Let $`P(A)=A_{D-1}\cdots A_0`$
be the product of a chain of real matrices of arbitrary sizes, set
$`\Phi=P(A)`$, and define

$$
L_\Phi(B)=\frac12\lVert P(B)-\Phi\rVert_F^2.
$$

The norm is the Frobenius norm. For every sufficiently small fixed Euclidean
ball in all matrix entries about
$`A`$, the volume of the part where $`L_\Phi(B)<\varepsilon`$ is bounded above
and below by positive constants times

$$
\varepsilon^\lambda\bigl(\log(1/\varepsilon)\bigr)^{m-1}
\qquad (\varepsilon\longrightarrow0^+),
$$

for a unique nonnegative real number $`\lambda`$ and positive integer $`m`$.

- **Theorem A:** $`\lambda`$ is half the local codimension of the fibre
  $`P^{-1}(\Phi)`$ at $`A`$. Here local codimension means the ambient real
  dimension minus the local Hausdorff dimension of the fibre. This proves the
  pointwise conjecture of [Pepin Lehalleur and Rimányi](https://arxiv.org/abs/2411.19920).
- **Theorem B:** a finite procedure computes $`(\lambda,m)`$ from the ranks of
  all partial products $`A_{j-1}\cdots A_i`$. The preprint defines the procedure
  and gives its mathematical justification.

For a nonzero analytic loss germ, $`\lambda`$ is called the local learning
coefficient (or real log canonical threshold) and $`m`$ its multiplicity. A locally
zero loss has volume order $`(0,1)`$ under the convention in the preprint. The formal endpoint
and the additional mathematical arguments used to obtain the preprint's
statements are distinguished below.

## What is here

| Path | Contents |
| --- | --- |
| [`ExactFitFull_2026_10_28_UTC.lean`](ExactFitFull_2026_10_28_UTC.lean) | All project proof declarations in one file, importing only Mathlib. The main theorem depends on `propext`, `Classical.choice`, and `Quot.sound`. |
| [`exact-fit-local/`](exact-fit-local/README.md) | Container harness: source scan, build, ordinary kernel replay, statement and fingerprint audit, and receipt. |
| [`paper/`](paper/README.md) | Preprint, TeX source, revision notes and red/blue comparisons. |
| [`verification/`](verification/2026-10-28-agent-check/README.md) | Separate agent-operated source compilation, ordinary kernel replay, fingerprint comparison and source scan. |
| [`certificates/`](certificates/README.md) | Instructions for publishing checking receipts and, optionally, signed attestations. |
| [`exact-fit-local/logs/`](exact-fit-local/logs/README.md) | Author-run evidence and its documented redaction/integrity limitation. |

## Checking the proof

On Linux with Bash, Python 3 and rootless Podman:

```bash
cd exact-fit-local
chmod +x exactfit.sh
./exactfit.sh preflight
./exactfit.sh build
./exactfit.sh setup
./exactfit.sh doctor
./exactfit.sh all ../ExactFitFull_2026_10_28_UTC.lean
```

`build` and `setup` need network access. The subsequent checks run offline.
The executable-bit command also covers a copy obtained through a browser upload
or download that did not preserve file modes. With Docker, prefix each command
with `EXACTFIT_ENGINE=docker`.

Lean `4.34.0-rc2` and Mathlib
`664cbbe52927ce6acaa39ca35498336116e123b8` are pinned. A fresh dependency volume
needs about 11 GB of disk, plus temporary download space. Allow memory headroom:
a standalone compilation has been observed to use about 7.6 GiB of RAM.
If you already checked [MAIS-O77](https://github.com/nfeld/mais-o77-lean), its
compatible dependency volume can be reused; see the
[harness instructions](exact-fit-local/README.md#reusing-the-o77-volume).

A successful run must report a successful build or up-to-date target, replay exit
status `0`, the expected axiom list, and `FINGERPRINT MATCH`. Keep the receipt
and the exact logs it names. [CERTIFICATE.md](exact-fit-local/CERTIFICATE.md)
explains the trust assumptions and the limits of these checks.

## What the formal statement covers

The selected formal theorem states the singleton output of the finite program,
its identification with local Hausdorff codimension, and the local measured
power/log order as an if-and-only-if statement. Appendix A of the preprint quotes
and translates its controlling definitions.

The passage from this formal endpoint to the preprint's Theorems A and B uses
mathematical arguments specified in Section 11 and Appendix A. In particular,
the selected endpoint does not itself include the last sentence of Theorem B,
and norm independence is obtained by the comparison argument in the text.
A successful Lean run does not replace checking this translation.

## Source and checking reference

The released proof is the single file linked above. Its SHA-256 is

```text
b362a3ee35df68adad7aa24a1ddd288e63e4e59d074445aaafef4093e8462a2c
```

Its header records the source-module hashes used when it was assembled. The
[`reference/`](exact-fit-local/reference/README.md) folder contains the imported
fingerprint of the main statement and its definitions, together with the
fingerprint script's version. The local audit recomputes this fingerprint from
the released file and compares it with that snapshot. The fingerprint is a
noncryptographic consistency check; the proof is checked by Lean's kernel.

## AI use and human review

OpenAI GPT agents working through Codex wrote the formal development under
Niels Feld's direction. Claude (Anthropic) wrote the combined statement,
extraction, checking harness, and the first natural-language preprint from the
formal development. Claude and OpenAI agents subsequently reviewed and revised
the text under the author's direction. The author reports reading the preprint
and checking the Lean file locally. The preprint's disclosure describes the
scope of that review and the distinction between statement review, kernel
checking, and understanding the formal proof.

## Credits

The problems come from Lionel Levine's Math for AI Safety programme. Rob
Sneiderman posted a depth-two candidate solution in
[MAIS issue 3](https://github.com/Math-for-AI-Safety/MAIS/issues/3), and
Svyatoslav Novikov with OpenAI Codex posted one in
[issue 12](https://github.com/Math-for-AI-Safety/MAIS/issues/12). The depth-two
case is formalized in [nfeld/mais-o77-lean](https://github.com/nfeld/mais-o77-lean);
its proof is included here. Pepin Lehalleur and Rimányi established the global
half-codimension equality and posed the pointwise conjecture. Aoyagi and Watanabe computed the global depth-two coefficients, and Aoyagi
computed those of arbitrary-depth deep linear networks. The preprint discusses
these antecedents and other related work, including prior statements and
methods not used by this proof. The formalization depends on
[Mathlib](https://github.com/leanprover-community/mathlib4) and Lean.

## License

Code: Apache License 2.0, see [LICENSE](LICENSE). Documentation, logs, and the
preprint: CC BY 4.0, see [LICENSE-DOCS](LICENSE-DOCS). Third-party material retains
its own license; see [LICENSING.md](LICENSING.md).
