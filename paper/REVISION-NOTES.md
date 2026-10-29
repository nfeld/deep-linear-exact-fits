# Revision notes

## 29 October 2026, 13:33:54 (Paris)

Corrections made by Claude (Anthropic) after a review of the public repository. The mathematics, the two main theorem statements, the Lean quotations and the Lean proof are unchanged.

- Section 1.3 and the bibliography: the previous version said that Furman and Lau's preprint arXiv:2402.03698 had been withdrawn and merged into the local learning coefficient paper (arXiv:2308.12108). arXiv lists a single version of arXiv:2402.03698 and no withdrawal, so that statement was removed; the three papers on estimators are now cited together, without comment on their relation.
- Section 1.3: the sentence defining "mildly singular", the term used in the title, is restored. A zero of a sum of squares is called mildly singular when $\lambda=\tfrac12\operatorname{codim}$ there; by Theorem A, every exact fit is mildly singular.
- Section 1.3: the pointwise conjecture of Pepin Lehalleur and Rimányi is cited as Section 8 of their paper instead of Remark 8.7.
- Section 12: records these corrections and the two comparison files.
- Title page: date of this version.

The comparison with the version of 00:19:56 was generated with latexdiff 1.3.2 and compiled with XeLaTeX (TeX Live 2023); see `diff-vs-00-19-56-generation.json`. All 20 Lean quotations are unchanged and appear in the text of the new PDF.

## 29 October 2026, 00:19:56 (Paris)

- The author is Niels Feld, with a linked title-page footnote to the AI-use disclosure. That disclosure identifies research direction, AI-generated formal proofs, AI-generated exposition, subsequent reviews and revisions, the author's readings, and the limits of kernel checking separately.
- The two main theorem statements and the released Lean proof are unchanged. No mathematical notation or alias was added. One unused component-count abbreviation and references to unavailable companion computations were removed.
- The operator norm is defined on the closed unit ball, including the zero-dimensional case. Locally zero loss is separated from classical RLCT terminology. The lower-integral comparison witness is defined on the whole space.
- Selected surjectivity, angular domination and radial integral steps now have explicit constructions or inequalities. The covariance remark assumes positive depth.
- Prior work and related ideas receive more precise attribution. (This revision also described arXiv:2402.03698 as withdrawn; that was wrong and is corrected in the version of 13:33:54.) The selected Lean endpoint's precise scope is stated consistently.
- Appendix A quotes actual lines of the public single-file proof. All 20 quotations were checked against source and extracted PDF text. The manifest and checker are supplied.
- The visual comparison uses red struck-through deletions and blue additions. Identifying provenance was removed from its comparison baseline; the mathematical baseline was not changed.

The checking harness now rejects a missing or empty fingerprint reference, as well as a mismatching one. This change was checked separately with matching, mismatching, missing and empty reference fixtures. The historical checking receipts describe the scripts used at their recorded dates; no receipt or raw execution log was rewritten. The new files do not claim that the container was rebuilt during this editorial revision.
