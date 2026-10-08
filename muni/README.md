# MUNI — Proof-Carrying Optimization Engine

MUNI is a product architecture for gated software optimization:

formal gap -> certificate -> semantics-preserving transformation -> native artifact -> adversarial validation -> silicon measurement -> claim.

## CLI

`muni self-test`
`muni receipt`
`muni elevate ./repository`

The current native witness is the AGD invariant-sector quotient runtime. Semantic correctness is separated from performance claims: a measured multiplier is local evidence unless a formal cost-model proof establishes a bound.

## Product components

- formal/: Lean proof contracts
- native/: quotient and persistent-runtime implementations
- receipts/: machine-readable evidence
- benchmarks/: reproducible silicon harnesses
- tests/: callable/native validation

Uncertified transformations must be refused or quarantined, never silently optimized.
