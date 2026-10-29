#!/usr/bin/env python3
"""Check the preprint's literal quotations; this is not a mathematical proof check.

Usage: python3 paper/tools/verify_quotations.py PAPER.tex [MATHLIB_ROOT]
Mathlib sources, when provided, must be the pinned checkout named in the manifest.
"""
import hashlib
import json
from pathlib import Path
import re
import sys


def sha(data):
    return hashlib.sha256(data).hexdigest()


def main():
    if len(sys.argv) not in (2, 3):
        raise SystemExit(__doc__)
    root = Path(__file__).resolve().parents[2]
    tex = Path(sys.argv[1])
    manifest = json.loads((root / 'paper/quotation-manifest-public.json').read_text())
    proof = root / manifest['proof_file']
    assert sha(proof.read_bytes()) == manifest['proof_sha256'], 'Proof file hash differs'
    blocks = re.findall(r'\\begin\{LeanCode\}\n(.*?)\n\\end\{LeanCode\}',
                        tex.read_text(), re.S)
    assert len(blocks) == len(manifest['blocks']), 'Quotation count differs'
    checked = 0
    for block, record in zip(blocks, manifest['blocks']):
        assert sha(block.encode()) == record['fragment_sha256'], record['block']
        if record['source_kind'] == 'project':
            path = root / record['source_path']
        elif len(sys.argv) == 3:
            path = Path(sys.argv[2]) / record['source_path']
        else:
            continue
        raw = path.read_bytes()
        assert sha(raw) == record['file_sha256'], record['source_path']
        lines = raw.decode().split('\n')
        fragment = '\n'.join(lines[record['line_start'] - 1:record['line_end']])
        assert fragment == block, record['block']
        checked += 1
    print(f'{len(blocks)} TeX quotations match the manifest; {checked} source fragments checked.')
    if len(sys.argv) == 2:
        print('The six Mathlib source fragments require the optional pinned checkout.')


if __name__ == '__main__':
    main()
