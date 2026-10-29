# Preprint

**Niels Feld.** The title-page footnote links to the disclosure of substantial AI assistance in Section 12. This version has not been refereed.

Current version: 29 October 2026, 14:29:39, Europe/Paris (UTC+01:00).

- [Preprint PDF](deep-linear-exact-fits-2026-10-29_14-29-39_Paris.pdf)
- [Self-contained TeX source](deep-linear-exact-fits-2026-10-29_14-29-39_Paris.tex)
- [Revision notes](REVISION-NOTES.md)

Changes for review, as red struck-through deletions and blue additions:

- [Credit correction since 13:33:54](deep-linear-exact-fits-2026-10-29_14-29-39_Paris-diff-vs-13-33-54.pdf) ([TeX](deep-linear-exact-fits-2026-10-29_14-29-39_Paris-diff-vs-13-33-54.tex)).
- [Changes since the version of 00:19:56](deep-linear-exact-fits-2026-10-29_13-33-54_Paris-diff-vs-00-19-56.pdf) ([TeX](deep-linear-exact-fits-2026-10-29_13-33-54_Paris-diff-vs-00-19-56.tex)): the corrections listed in the revision notes.
- [The version of 00:19:56 against the 28 October draft](deep-linear-exact-fits-2026-10-29_00-19-56_Paris-diff.pdf) ([TeX](deep-linear-exact-fits-2026-10-29_00-19-56_Paris-diff.tex)). Identifying provenance was removed from the comparison baseline; its mathematical text was unchanged before comparison.

The version of 13:33:54 ([PDF](deep-linear-exact-fits-2026-10-29_13-33-54_Paris.pdf), [TeX](deep-linear-exact-fits-2026-10-29_13-33-54_Paris.tex)) is retained as the baseline for the credit correction.

The version of 00:19:56 ([PDF](deep-linear-exact-fits-2026-10-29_00-19-56_Paris.pdf), [TeX](deep-linear-exact-fits-2026-10-29_00-19-56_Paris.tex)) is kept because both comparisons refer to it. The two main theorem statements, the mathematical notation, the Lean quotations and the Lean proof are the unchanged across these versions.

## Building

Use XeLaTeX with `fontspec`, `amsmath`, `amssymb`, `amsthm`, `mathtools`, `fvextra`, TikZ, `hyperref`, and `xurl`; the fonts are Latin Modern Roman, DejaVu Sans Mono and DejaVu Math TeX Gyre. A standard TeX Live installation supplies the packages. No external illustration files are needed.

```bash
cd paper
xelatex -interaction=nonstopmode -halt-on-error deep-linear-exact-fits-2026-10-29_14-29-39_Paris.tex
xelatex -interaction=nonstopmode -halt-on-error deep-linear-exact-fits-2026-10-29_14-29-39_Paris.tex
xelatex -interaction=nonstopmode -halt-on-error deep-linear-exact-fits-2026-10-29_14-29-39_Paris.tex
```

The page count can differ by one between TeX Live releases. The comparison files are compiled in the same way; they use `ulem`, either the copy supplied here, whose original license and attribution remain in that file, or a compatible installed one. The preprint itself does not depend on `ulem`.

## Checking the quotations

From the repository root:

```bash
python3 paper/tools/verify_quotations.py paper/deep-linear-exact-fits-2026-10-29_14-29-39_Paris.tex /path/to/pinned/mathlib
```

The optional Mathlib checkout must be at `664cbbe52927ce6acaa39ca35498336116e123b8`. Without that argument, the checker verifies all quotation fragments against the manifest and all 14 project fragments against the released Lean file; it explicitly leaves the six Mathlib source comparisons unchecked. These checks compare literal text, not mathematical meaning or proof validity.

## Scope of the revisions

The revision of 00:19:56 expanded explicit estimates and selected linear-algebra arguments, handled zero-dimensional norm and zero-loss conventions, made the formal certification scope precise, expanded scholarly credits, and removed unsupported references to companion computations. The version of 13:33:54 revised citation and terminology; the current version corrects its mistaken description of the Furman–Lau record. The Lean proof has not changed. The author should review the comparisons before circulating this version; earlier human readings do not certify later edits.
