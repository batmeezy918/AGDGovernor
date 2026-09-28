# Operational permissions added by AGDGovernor

| Id | Lemma | A governor may | A governor may not |
|---|---|---|---|
| 101 | `jitter_close_reflexive` | treat a measurement as close to itself | invent a metric on silicon |
| 102 | `jitter_close_symmetric` | reverse a closeness witness | — |
| 103 | `jitter_close_triangle` | chain two ε-close steps into 2ε | treat 2ε as zero error |
| 104 | `operator_preserves_equivalence` | apply an observable-constant transform to a close pair | claim the transform is faster |
| 105 | `speedup_positive` | report Nat floor(baseline/candidate) > 0 on a valid cert | print that number as wall-clock |
| 106 | `benchmark_claim_valid` | drop the `max _ 1` guard after positivity | skip the validity hypotheses |
| 107 | `agd_transport_closure` | keep Omega after an admissible step | transport an unofficial coco score |
| 108 | `curvature_convergence` | iterate an admissible map | call iteration a curvature theorem on R |
| 109 | `agd_bisimulation` | treat two admissible maps as observably equal | treat them as the same runtime |
| 110 | `agd_flow_semigroup` | use a flow hypothesis as composition | derive a flow from nothing |
| 111 | `agd_master_dynamic_closure` | conjoin transport + descent hypotheses | treat the conjunction as new analysis |
| 112 | `agd_spectral_convergence` | iterate admissibility | quote a Real spectral-radius bound |
| 201 | `adaptive_operator_preservation` | pick a listed operator that keeps Omega and minimizes declared loss | claim the pick is globally optimal |
| 202 | `agd_failure_recovery` | roll back to the last stable state when Omega breaks | invent a new state |
| 203 | `learning_manifold_stability` | iterate inside an Omega region | claim learning happened |
| 204 | `memory_lineage_reconstruction` | unpack a lineage witness | reconstruct without the witness |
| 205 | `agd_autonomous_closure` | run one adaptive cycle and keep Omega | call the cycle a verified optimizer |
