# Selected live-candidate intake: SIM2XR shared-prefix

**Candidate ID:** `SIM2XR_SPEEDUP_V1_SHARED_PREFIX`  
**Historical run:** `sim2xr_speedup_v1_20260908T201616Z`  
**Recorded target:** Termux on Android 15, AArch64  
**Admission state:** `CANDIDATE — FRESH END-TO-END RECEIPT REQUIRED`

## Why this candidate was selected

The local historical report records seven paired runs with observed speedups:

`16.506075x, 17.569849x, 17.617531x, 17.469194x, 17.577857x, 17.509339x, 17.546782x`

It reports a median of `17.54427741717751x`, all seven output/hash comparisons matching, and a workload boundary limited to the declared shared-prefix case. The record is useful historical evidence, not a universal speedup claim.

## Current proof-carrying status

The local evidence tree also contains a separate SIM2XR invariant-sector certificate whose `lean` gate is explicitly false. That certificate reports a different experiment (maximum `168.1415x` across five witnesses) and must not be mixed with the shared-prefix result.

This repository's PCSS intake requires the fresh claim receipt to bind all of the following to the same immutable revision/build:
- raw baseline and optimized end-to-end timing samples;
- raw-result and telemetry SHA-256 digests;
- exact benchmark source and execution environment manifest;
- seven-repeat semantic/hash comparison, rerun from the canonical source;
- quotient-forward, reverse reconstruction, and invariant evidence;
- Lean theorem manifest and kernel replay;
- a real configured independent-checker execution receipt;
- measured ratio recomputed from raw timings.

The historical report contains per-repeat speedup ratios and matching-output flags, but the canonical executable source and raw paired timing samples were not found in the repository examined for this PR. Therefore, do not synthesize absolute timings from ratios or copy historical booleans into a fresh receipt.

## Promotion rule

Until the canonical runner is recovered or restored, a fresh target-device run emits immutable raw timings, and every formal/semantic/telemetry gate is bound to that run, the candidate remains **BLOCKED from promotion**. The historical `17.544277x` value remains a bounded, workload-specific historical measurement only.
