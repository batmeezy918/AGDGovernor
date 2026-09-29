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
| CMI-001 | `QX_CMI_001` | read X as the first reduced-response operator output | treat X as a partial trace on B(H) |
| CMI-002 | `QX_CMI_002` | read Y as the second reduced-response operator output | treat Y as ad_H^2 on a density operator |
| CMI-003 | `QX_CMI_003_*` | use S'' = A - Gamma on Int observables | quote a von Neumann Hessian |
| CMI-004 | `LocalUnitaryCMIReduction` | discharge I'' = S'' on this algebra | claim the Hilbert-space CMI reduction |
| CMI-005 | `QX_CMI_005_nonneg` | treat discrete Gamma = |X|^2 as nonnegative | claim BKM positivity of Dlog |
| CMI-006 | `QX_CMI_006_master_bridge` | decompose I'' as A - Gamma | revive I'' = Gamma_ABC - Gamma_AB |
| CMI-007 | `QX_CMI_007_zero_residual` | treat residual Omega as identically 0 | skip the definition of I'' |
| CMI-008 | `QX_CMI_008_sign` | when Y = 0, conclude I'' = -Gamma <= 0 | claim I'' is always nonpositive |
| CMI-009 | `QX_CMI_009_zero_tangent` | when X = 0, conclude I'' = A | claim X = 0 implies Y = 0 |
| CMI-010 | `QX_CMI_010_flat` | when X = Y = 0, conclude I'' = 0 | call a flat orbit a verified optimizer |
| SPEC-S | `S_involutive` | invert a tagged generator twice and recover it | insert S into the CMI derivation |
| SPEC-F | `Ft_odd` | treat F as odd under S | treat numerical oddness as a CMI proof |
| SPEC-D | `Dt_even` | treat D as even under S | treat numerical evenness as a CMI proof |
