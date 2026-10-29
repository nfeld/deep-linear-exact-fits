/-!
# Fingerprint of `MAIS.ExactFitStatement.exact_fit_classification`

This file has no `import` line.  The harness prepends `import ExactFitTarget`
(the single-file extraction); the CI workflow also runs it in the repository
with `import O7.ExactFitStatement` (the original multi-file development).  The
two runs must print the same text.  This is how the extraction is checked to
state the same theorem, over the same definitions, as the repository.

It prints:

1. the statement, with notation, then with `pp.all` (every implicit argument,
   instance and universe level shown);
2. the axioms on which the proof depends;
3. the *definitional closure* of the statement: the constants reachable from the
   statement's type by following types, bodies of definitions, constructors of
   inductive types and the inductive type of each constructor.  Proofs of
   theorems are never followed: they do not change the meaning of a statement.
   For each definition, inductive type and constructor of the project, one line
   gives its name, its kind, its universe parameters, and a 128-bit fingerprint
   of its type and (for a definition) of its body.  The theorems that occur
   (of the project or external) are listed by the fingerprints of their
   statements only.  The other external constants (Lean core, Mathlib and its
   dependencies) are listed by name only, since both runs use the same pinned
   Mathlib.

The fingerprint of a term is a structural hash computed after three
normalizations, which do not change the meaning of a statement:
* names of private declarations lose their module part
  (`_private.M.0.x` becomes `x`), since the module differs between the builds;
* a theorem used inside a term is identified by the fingerprint of its
  statement, not by its name.  By proof irrelevance, a definition does not
  depend on which proof of a proposition it contains, and the elaborator
  shares identical auxiliary lemmas (`_proof_n`) between declarations of one
  module, so the names of these lemmas differ between the two builds;
* binder names and metadata annotations are ignored.
Nothing in this file proves anything.
-/

open Lean Elab Command

namespace ExactFitFingerprint

/-- First components of the module names of Lean core, Mathlib and its dependencies. -/
def externalRoots : List String :=
  ["Init", "Std", "Lean", "Lake", "Mathlib", "Batteries", "Aesop", "Qq",
    "ProofWidgets", "Plausible", "LeanSearchClient", "ImportGraph", "Cli"]

/-- The module in which an imported constant was declared. -/
def declModule? (env : Environment) (c : Name) : Option Name := do
  let idx ← env.getModuleIdxFor? c
  env.header.moduleNames[idx.toNat]?

/-- External constants come from Lean core, Mathlib or a dependency of Mathlib. -/
def isExternal (env : Environment) (c : Name) : Bool :=
  match declModule? env c with
  | some m => externalRoots.contains m.getRoot.toString
  | none => false

/-- Remove the module part of a private name: `_private.M₁.….Mₖ.0.x ↦ x`. -/
def normName (n : Name) : Name :=
  match n.components with
  | first :: rest =>
    if first == Name.mkSimple "_private" then
      let afterModule := (rest.dropWhile fun c => match c with
        | .num .. => false
        | _ => true).drop 1
      afterModule.foldl (fun acc c => acc ++ c) Name.anonymous
    else n
  | [] => n

/-- A 128-bit fingerprint, as two 64-bit words mixed differently. -/
abbrev Fp := UInt64 × UInt64

def mixFp (a b : Fp) : Fp :=
  (mixHash a.1 b.1, mixHash (b.2 ^^^ 0x9E3779B97F4A7C15) (a.2 * 0xC2B2AE3D27D4EB4F + 1))

def leaf (tag x : UInt64) : Fp :=
  (mixHash (tag * 0x100000001B3) x, mixHash (x ^^^ 0x632BE59BD9B4E019) (tag + 0x27D4EB2F165667C5))

def binderCode : BinderInfo → UInt64
  | .default => 0
  | .implicit => 1
  | .strictImplicit => 2
  | .instImplicit => 3

def fpToString (f : Fp) : String := s!"{f.1}-{f.2}"

/-- Memo table: the fingerprint of each constant reference seen so far. -/
abbrev FpM := StateM (Std.HashMap Name Fp)

mutual
  /-- Structural fingerprint of an expression, after the normalizations above. -/
  partial def fp (env : Environment) (e : Expr) : FpM Fp := do
    match e with
    | .bvar i => return leaf 1 i.toUInt64
    | .fvar id => return leaf 2 (hash id.name)
    | .mvar id => return leaf 3 (hash id.name)
    | .sort u => return leaf 4 (hash u)
    | .const n us => return mixFp (← constFp env n) (leaf 5 (hash us))
    | .app f a => return mixFp (leaf 6 0) (mixFp (← fp env f) (← fp env a))
    | .lam _ t b bi => return mixFp (leaf 7 (binderCode bi)) (mixFp (← fp env t) (← fp env b))
    | .forallE _ t b bi => return mixFp (leaf 8 (binderCode bi)) (mixFp (← fp env t) (← fp env b))
    | .letE _ t v b nd =>
      return mixFp (leaf 9 (if nd then 1 else 0)) (mixFp (← fp env t) (mixFp (← fp env v) (← fp env b)))
    | .lit (.natVal k) => return leaf 10 (hash k)
    | .lit (.strVal s) => return leaf 11 (hash s)
    | .mdata _ b => fp env b
    | .proj s i b => return mixFp (leaf 12 (mixHash (hash (normName s)) i.toUInt64)) (← fp env b)

  /-- A theorem is identified by the fingerprint of its statement; every other
  constant by its (normalized) name. -/
  partial def constFp (env : Environment) (n : Name) : FpM Fp := do
    if let some v := (← get)[n]? then return v
    let v ← match env.find? n with
      | some (.thmInfo t) => do
        let ty ← fp env t.type
        pure (mixFp (leaf 20 (hash t.levelParams.length)) ty)
      | _ => pure (leaf 21 (hash (normName n)))
    modify (·.insert n v)
    return v
end

def kindAndBody (env : Environment) : ConstantInfo → FpM String
  | .defnInfo d => do return s!"def body={fpToString (← fp env d.value)}"
  | .thmInfo _ => return "theorem"
  | .opaqueInfo d => do return s!"OPAQUE body={fpToString (← fp env d.value)}"
  | .axiomInfo _ => return "AXIOM"
  | .quotInfo _ => return "quot"
  | .inductInfo i =>
    return s!"inductive params={i.numParams} indices={i.numIndices} rec={i.isRec} ctors={i.ctors.map normName}"
  | .ctorInfo c =>
    return s!"constructor of={normName c.induct} idx={c.cidx} params={c.numParams} fields={c.numFields}"
  | .recInfo _ => return "recursor"

/-- Constants to follow from a constant: those in its type, plus those in the body
of a definition, the constructors of an inductive type, and the inductive type of
a constructor. -/
def successors (info : ConstantInfo) : Array Name := Id.run do
  let mut out := info.type.getUsedConstants
  match info with
  | .defnInfo d => out := out ++ d.value.getUsedConstants
  | .opaqueInfo d => out := out ++ d.value.getUsedConstants
  | .inductInfo i => out := out ++ i.ctors.toArray
  | .ctorInfo c => out := out.push c.induct
  | _ => pure ()
  return out

/-- Breadth-first closure from the given roots.  Project constants other than
theorems are followed; theorems (of the project or external) are collected but
not followed beyond their statements; other external constants are collected
by name only. -/
def closure (env : Environment) (roots : Array Name) :
    Array Name × Array Name × Array Name := Id.run do
  let mut seen : NameSet := {}
  let mut project : Array Name := #[]
  let mut theorems : Array Name := #[]
  let mut external : Array Name := #[]
  let mut queue : Array Name := roots
  let mut i := 0
  while i < queue.size do
    let c := queue[i]!
    i := i + 1
    if seen.contains c then continue
    seen := seen.insert c
    let some info := env.find? c | continue
    match info with
    | .thmInfo t =>
      theorems := theorems.push c
      if !isExternal env c then
        queue := queue ++ t.type.getUsedConstants
    | _ =>
      if isExternal env c then
        external := external.push c
      else
        project := project.push c
        queue := queue ++ successors info
  return (project, theorems, external)

def sortStrings (xs : Array String) : Array String := xs.qsort (· < ·)

/-- Remove adjacent duplicates of a sorted array. -/
def dedupSorted (xs : Array String) : Array String := Id.run do
  let mut out : Array String := #[]
  for x in xs do
    if out.back? != some x then out := out.push x
  return out

elab "#exact_fit_fingerprint" : command => do
  let env ← getEnv
  let thm := `MAIS.ExactFitStatement.exact_fit_classification
  let some info := env.find? thm | throwError "theorem {thm} not found"
  let (project, theorems, external) := closure env info.type.getUsedConstants
  let act : FpM (Fp × Array String × Array String) := do
    let mainFp ← fp env info.type
    let mut lines : Array String := #[]
    for c in project do
      let some ci := env.find? c | continue
      lines := lines.push
        s!"{normName c} | {← kindAndBody env ci} | params={ci.levelParams} | type={fpToString (← fp env ci.type)}"
    let mut thmTypes : Array String := #[]
    for c in theorems do
      let some ci := env.find? c | continue
      thmTypes := thmTypes.push
        s!"theorem-statement params={ci.levelParams.length} type={fpToString (← fp env ci.type)}"
    return (mainFp, lines, thmTypes)
  let ((mainFp, lines, thmTypes), _) := act.run {}
  let lines := sortStrings lines
  let thmTypes := dedupSorted (sortStrings thmTypes)
  let body := #[s!"theorem {thm} params={info.levelParams} type={fpToString mainFp}"] ++ lines ++ thmTypes
  logInfo m!"\nFINGERPRINT-BEGIN ({lines.size} definitions, inductive types and constructors; {thmTypes.size} distinct theorem statements)\n{String.intercalate "\n" body.toList}\nFINGERPRINT-END"
  let ext := sortStrings (external.map fun c => (normName c).toString)
  logInfo m!"\nEXTERNAL-BEGIN ({ext.size} external constants other than theorems)\n{String.intercalate "\n" ext.toList}\nEXTERNAL-END"

end ExactFitFingerprint

-- 1. The statement, with notation.
#check @MAIS.ExactFitStatement.exact_fit_classification

-- 2. The statement with every implicit argument, instance and universe shown.
set_option pp.all true in
#check @MAIS.ExactFitStatement.exact_fit_classification

-- 3. Axioms.
#print axioms MAIS.ExactFitStatement.exact_fit_classification

-- 4. Fingerprint of the definitional closure.
#exact_fit_fingerprint
