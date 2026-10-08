# MUNI — Proof-Carrying Optimization Engine

MUNI is a gated optimization platform:

**inventory → baseline → profile → formal gap → certificate → transformation → semantic validation → adversarial validation → native measurement → claim**

## Broad applicability

The elevation engine currently recognizes:

- Python
- Node / TypeScript
- Rust
- Go
- C / C++
- Java
- Lean
- Julia

It scans nested source trees while excluding generated/build/vendor directories. Polyglot repositories expose all detected adapters; one adapter is selected as the primary baseline according to the declared policy.

## CLI

`muni inspect ./repository` — inventory without executing code.

`muni elevate ./repository` — create a machine-readable elevation receipt.

`muni elevate ./repository --execute` — run the detected baseline adapter and record its exact exit status, output, timing, and failure reason.

`muni self-test` — validate the bundled native witness.

## Product contract

A baseline passing is **not** an optimization proof. MUNI refuses to elevate a transformation unless the formal gap and certificate gates are satisfied. Failed or unsupported work is retained as CANDIDATE or QUARANTINED evidence.

The current native witness is the AGD invariant-sector quotient runtime. Semantic correctness is separated from performance claims: a measured multiplier is local evidence unless a formal cost-model proof establishes a bound.

## Evidence

Every elevation can produce:

- `AGD_ELEVATION_RECEIPT.json`
- artifact hashes
- formal certificate references
- baseline execution evidence
- semantic/adversarial gate results
- silicon measurements
- claim level

The system never converts a benchmark multiplier into a universal theorem automatically.

## Native product witness

The bundled AArch64 runtime has a verified local semantic witness with zero maximum reconstruction error. The strongest clean local amortized benchmark currently recorded is 100.753526× under its declared workload/configuration.

That number is **MEASURED_LOCAL_NATIVE**, not a universal speedup guarantee.
