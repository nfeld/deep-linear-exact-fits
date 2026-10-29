# What a successful run establishes

There are four separate questions.

1. **Does Lean accept the proof?** `verify` elaborates the whole file;
   `recheck` builds the target when necessary, or reuses an up-to-date build,
   and then replays it. The resulting declarations are checked by Lean's kernel.
   The final
   `#guard_msgs` block fails the build unless the theorem depends exactly on the
   axioms `[propext, Classical.choice, Quot.sound]`, the standard axioms of
   Mathlib. `scan` shows that the file contains no `sorry`, no `axiom`, no
   `native_decide`, no `implemented_by`/`extern`, no `unsafe` code and no
   metaprogramming command.
2. **Can the compiled declarations be replayed?** `leanchecker` replays every
   declaration of the module with Lean's kernel, in a new process. Because the
   whole project part of the proof is in this one module, the default replay
   covers all of it; `FRESH=1` also replays Mathlib and Lean core. This is a
   second run of the same kernel, not an independently implemented checker.
3. **Does it agree with the frozen reference statement?** The fingerprint file contains the
   statement printed in full (with notation, then with `pp.all`), its axioms, and
   a 128-bit structural hash of the type and body of every definition, inductive
   type and constructor on which the statement depends. The harness compares this
   file, as text, with the one printed in the original multi-file development
   (`reference/fingerprint-multi.txt`). A match is consistency evidence for the
   statement and definitions, up to the normalizations
   listed at the top of `tools/Fingerprint.body.lean` (module part of private
   names, names of bound variables, metadata, and auxiliary lemmas identified by
   their statements). The proofs of theorems are not compared, which does not
   matter for the meaning of the statement. The hash is not cryptographic: an
   accidental collision is negligible, but it is not designed to resist someone
   who crafts a colliding definition on purpose. The printed statement itself is
   compared character by character.
4. **Does the statement say what the preprint says?** No program answers this.
   The statement and the definitions it uses are quoted in Appendix A of the
   preprint, with a translation into mathematical language; the translation has
   to be checked by reading. The audit prints the full list of definitions to
   check (the definitional closure).

## The receipt, and how to sign it

`./exactfit.sh all FILE` writes `logs/receipt-<UTC>.txt`. It records the input's
SHA-256, the container image ID, the Lean and Mathlib versions, the result of each
step, the axioms, the fingerprint comparison, and the SHA-256 of the full logs.

A receipt is a record of what was run on which machine and what it printed. It
is only as trustworthy as the person who ran it. Signing is optional: a signature
identifies who attests to the receipt's bytes. For example, with an SSH key:

```bash
ssh-keygen -Y sign -f ~/.ssh/id_ed25519 -n file logs/receipt-<UTC>.txt
# creates logs/receipt-<UTC>.txt.sig; to verify:
ssh-keygen -Y verify -f allowed_signers -I <your identity> -n file \
  -s logs/receipt-<UTC>.txt.sig < logs/receipt-<UTC>.txt
```

Or commit the receipt and the logs it lists in a signed Git commit
(`git commit -S`), which GitHub displays as verified.

## What is trusted

- Lean's kernel (version `4.34.0-rc2`), which both the build and `leanchecker`
  use, and the logical soundness of Lean with the three axioms above.
- Mathlib's compiled files (`.olean`), which `setup` downloads from Mathlib's
  official cache for the pinned commit instead of compiling them. The default
  replay takes Mathlib's declarations as given; `FRESH=1` replays them with the
  kernel too. `leanchecker` assumes that the `.olean` files are well formed.
- The container runtime, for the isolation (not for the correctness of the
  check).

## Stronger checks, not done here

The Lean reference manual (section "Validating proofs", for instance
<https://lean-lang.org/doc/reference/4.35.0/ValidatingProofs/>) describes a
ladder of checks: kernel acceptance, `#print axioms`, a replay with
`lean4checker --fresh`, and, for high-risk settings, among which it names proofs
produced by unaligned AI, the tool `comparator` with external checkers. This
harness does the first three (the last one with `FRESH=1`). Not done here:

- `comparator` (<https://github.com/leanprover/comparator>): it builds the proof
  in a sandbox, exports the proof terms, checks them with the official kernel
  and with an independently implemented checker (`nanoda`), and checks that the
  theorem has exactly the statement of a trusted "challenge" file. Whether it
  supports Lean `4.34.0-rc2` has not been checked.
- The challenge file itself: a reference statement written by a reviewer from
  the mathematics. This would replace part of question 4 by a smaller reading
  task: the challenge file instead of the definitional closure.
