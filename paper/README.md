# Preprint and revision comparison

**Niels Feld.** The title-page footnote links to the disclosure of substantial AI assistance in Section 12. This version has not been refereed.

- [Preprint PDF](deep-linear-exact-fits-2026-10-29_00-19-56_Paris.pdf)
- [Self-contained TeX source](deep-linear-exact-fits-2026-10-29_00-19-56_Paris.tex)
- [Visual revision comparison](deep-linear-exact-fits-2026-10-29_00-19-56_Paris-diff.pdf): red struck-through deletions and blue additions against the 28 October draft. Identifying provenance was removed from the comparison baseline; its mathematical text was unchanged before comparison.
- [Comparison TeX](deep-linear-exact-fits-2026-10-29_00-19-56_Paris-diff.tex)
- [Quotation manifest](quotation-manifest-public.json)

The timestamp is 29 October 2026, 00:19:56, Europe/Paris (UTC+01:00). The mathematical notation and the two main theorem statements are preserved; one unused component-count abbreviation was removed.

## Building

Use XeLaTeX with `fontspec`, `amsmath`, `amssymb`, `amsthm`, `mathtools`, `fvextra`, TikZ, `hyperref`, and `xurl`; the fonts are Latin Modern Roman, DejaVu Sans Mono and DejaVu Math TeX Gyre. A standard TeX Live installation supplies the packages. The interval brackets use the existing font configuration; no external illustration files are needed.

```bash
cd paper
xelatex -interaction=nonstopmode -halt-on-error deep-linear-exact-fits-2026-10-29_00-19-56_Paris.tex
xelatex -interaction=nonstopmode -halt-on-error deep-linear-exact-fits-2026-10-29_00-19-56_Paris.tex
xelatex -interaction=nonstopmode -halt-on-error deep-linear-exact-fits-2026-10-29_00-19-56_Paris.tex
```

The comparison uses the supplied `ulem.sty`, whose original license and attribution remain in that file. Compile the `-diff.tex` file in the same way. A compatible modern installed `ulem` can also be used. The standalone clean TeX file does not depend on `ulem`.

## Checking the quotations

From the repository root:

```bash
python3 paper/tools/verify_quotations.py paper/deep-linear-exact-fits-2026-10-29_00-19-56_Paris.tex /path/to/pinned/mathlib
```

The optional Mathlib checkout must be at `664cbbe52927ce6acaa39ca35498336116e123b8`. Without that argument, the checker verifies all quotation fragments against the manifest and all 14 project fragments against the released Lean file; it explicitly leaves the six Mathlib source comparisons unchecked. These checks compare literal text, not mathematical meaning or proof validity. The proof file remains byte-identical to the source identified in the preprint.

## Revision scope

The revision expands explicit estimates and selected linear-algebra arguments, handles zero-dimensional norm and zero-loss conventions, makes the formal certification scope precise, expands scholarly credits, and removes unsupported references to companion computations. The Lean proof has not changed. The author should review the comparison before circulating this revision; earlier human readings do not certify later edits.
