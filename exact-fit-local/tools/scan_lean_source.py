#!/usr/bin/env python3
"""List the constructs of a Lean source file that deserve a reader's attention
before trusting a "the build passed" message.

Comments and string literals are blanked out first, so only code is scanned.
The scan is a reading aid: it cannot certify that arbitrary Lean code is inert
(see ../README.md).  Exit status: 0 if no forbidden construct is found, 1 otherwise.

Forbidden (the build would not mean "proved from the standard axioms"):
  sorry, admit, axiom declarations, native_decide / +native, implemented_by,
  extern, unsafe, debug.* options (e.g. debug.skipKernelTC), #exit.
Forbidden (metaprogramming that can change what the file means or does):
  macro, macro_rules, syntax, elab, elab_rules, run_cmd, run_tac, run_elab,
  run_meta, #eval, initialize, builtin_initialize, declare_syntax_cat,
  global notation / infix / prefix / postfix.
Reported (allowed, but listed): imports, opaque and partial declarations,
  local notations, set_option names with their counts, #guard_msgs blocks,
  global attribute commands, non-ASCII characters by Unicode block.
"""
import collections, hashlib, os, re, sys, unicodedata

def strip_comments_and_strings(text):
    out, i, n, depth = [], 0, len(text), 0
    while i < n:
        if depth:
            if text.startswith('/-', i):
                depth += 1; out.append('  '); i += 2; continue
            if text.startswith('-/', i):
                depth -= 1; out.append('  '); i += 2; continue
            out.append('\n' if text[i] == '\n' else ' '); i += 1; continue
        if text.startswith('/-', i):
            depth = 1; out.append('  '); i += 2; continue
        if text.startswith('--', i):
            j = text.find('\n', i)
            j = n if j < 0 else j
            out.append(' ' * (j - i)); i = j; continue
        if text[i] == '"' and not (i > 0 and text[i - 1] == "'" and text[i + 1:i + 2] == "'"):
            j = i + 1
            while j < n and text[j] != '"':
                j += 2 if text[j] == '\\' else 1
            out.append(''.join('\n' if c == '\n' else ' ' for c in text[i:j + 1])); i = j + 1; continue
        out.append(text[i]); i += 1
    return ''.join(out)

def word(w):
    return re.compile(r"(?<![\w.'!?])" + re.escape(w) + r"(?![\w'!?])")

FORBIDDEN = {
    'sorry': word('sorry'),
    'admit': word('admit'),
    'axiom declaration': re.compile(r'^\s*(?:@\[[^\]]*\]\s*)?(?:(?:private|protected|noncomputable)\s+)*axiom\b', re.M),
    'native_decide': word('native_decide'),
    '+native / Lean.ofReduceBool': re.compile(r'\+native\b|ofReduceBool|ofReduceNat'),
    'implemented_by': word('implemented_by'),
    'extern': re.compile(r'@\[\s*extern\b|\bextern\s+"'),
    'unsafe': word('unsafe'),
    'debug option': re.compile(r'\bset_option\s+debug\.'),
    '#exit': word('#exit'),
    'macro': re.compile(r'^\s*(?:@\[[^\]]*\]\s*)?(?:(?:local|scoped)\s+)?macro(?:_rules)?\b', re.M),
    'syntax': re.compile(r'^\s*(?:@\[[^\]]*\]\s*)?(?:(?:local|scoped)\s+)?(?:syntax|declare_syntax_cat)\b', re.M),
    'elab': re.compile(r'^\s*(?:@\[[^\]]*\]\s*)?(?:(?:local|scoped)\s+)?elab(?:_rules)?\b', re.M),
    'run_cmd / run_tac / run_elab / run_meta': re.compile(r'\brun_(?:cmd|tac|elab|meta)\b'),
    '#eval': word('#eval'),
    'initialize': re.compile(r'^\s*(?:builtin_)?initialize\b', re.M),
    'global notation': re.compile(r'^\s*(?:@\[[^\]]*\]\s*)?(?:notation|infixl?|infixr|prefix|postfix)\b', re.M),
}
REPORTED = {
    'import': re.compile(r'^\s*import\s+(\S+)', re.M),
    'opaque declaration': re.compile(r'^\s*(?:@\[[^\]]*\]\s*)?(?:(?:private|protected|noncomputable)\s+)*opaque\b', re.M),
    'partial declaration': re.compile(r'\bpartial\s+def\b'),
    'local/scoped notation': re.compile(r'^\s*(?:local|scoped)\s+(?:notation|infixl?|infixr|prefix|postfix)\b', re.M),
    '#guard_msgs': word('#guard_msgs'),
    'global attribute command': re.compile(r'^\s*attribute\s+\[(?!local\b|scoped\b)', re.M),
}
SUSPICIOUS_CHARS = {0x200B, 0x200C, 0x200D, 0x200E, 0x200F, 0x2060, 0xFEFF,
                    *range(0x202A, 0x202F), *range(0x2066, 0x206A)}

def line_of(text, pos):
    return text.count('\n', 0, pos) + 1

def main(path):
    data = open(path, 'rb').read()
    raw = data.decode('utf-8')
    code = strip_comments_and_strings(raw)
    bad = 0
    # Only the file name and its hash: the log must not reveal the directory
    # (and so the user name) of the machine that ran the scan, and it is then
    # byte-identical for anyone who scans the same file.
    print(f'Scan of {os.path.basename(path)} (SHA-256 {hashlib.sha256(data).hexdigest()}, '
          f'{raw.count(chr(10))} lines)')
    print('Forbidden constructs (outside comments and strings):')
    for name, pat in FORBIDDEN.items():
        hits = [line_of(code, m.start()) for m in pat.finditer(code)]
        if hits:
            bad += len(hits)
            print(f'  FOUND {name}: {len(hits)} at lines {hits[:10]}')
    if not bad:
        print('  none')
    print('Reported constructs:')
    for name, pat in REPORTED.items():
        ms = list(pat.finditer(code))
        if name == 'import':
            print(f'  imports: {sorted(set(m.group(1) for m in ms))}')
        else:
            print(f'  {name}: {len(ms)}' + (f' (first at line {line_of(code, ms[0].start())})' if ms else ''))
    opts = collections.Counter(m.group(1) for m in re.finditer(r'\bset_option\s+([\w.]+)', code))
    print('  set_option: ' + (', '.join(f'{k} x{v}' for k, v in sorted(opts.items())) or 'none'))
    blocks = collections.Counter()
    for ch in raw:
        if ord(ch) > 127:
            if ord(ch) in SUSPICIOUS_CHARS:
                bad += 1
                print(f'  FOUND invisible or bidirectional character U+{ord(ch):04X}')
            blocks[unicodedata.name(ch, '?').split(' ')[0]] += 1
    print('  non-ASCII characters by first word of their Unicode name: '
          + ', '.join(f'{k} x{v}' for k, v in blocks.most_common()))
    print(f'SCAN RESULT: {bad} forbidden construct(s) or character(s) found.')
    return 1 if bad else 0

if __name__ == '__main__':
    if len(sys.argv) != 2:
        print(__doc__); sys.exit(2)
    sys.exit(main(sys.argv[1]))
