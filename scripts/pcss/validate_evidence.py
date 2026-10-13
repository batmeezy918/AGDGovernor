#!/usr/bin/env python3
"""PCSS evidence schema validator and fail-closed promotion evaluator."""
import argparse
import hashlib
import json
import pathlib
import re
import sys

from jsonschema import Draft202012Validator, ValidationError


def promotion_decision(d):
    reasons = []
    formal = d.get("formal", {})
    source = d.get("source", {})
    impl = d.get("implementation", {})
    execution = d.get("execution", {})
    bench = d.get("benchmark", {})
    promotion = d.get("promotion", {})

    required = [
        ("clean source tree", source.get("dirty_tree") is False),
        ("formal build", formal.get("build_status") == "PASS"),
        ("sorry scan", formal.get("sorry_scan") == "PASS"),
        ("kernel replay", formal.get("kernel_replay_status") == "PASS"),
        ("independent checker", formal.get("independent_checker_status") == "PASS"),
        ("implementation equivalence", impl.get("equivalence_status") == "PASS"),
        ("live runtime", execution.get("runtime_status") == "PASS"),
        ("telemetry digest", bool(re.fullmatch(r"[0-9a-f]{64}", str(execution.get("telemetry_sha256", ""))))),
        ("environment manifest digest", bool(re.fullmatch(r"[0-9a-f]{64}", str(execution.get("environment_manifest_sha256", ""))))),
        ("implementation mapping digest", bool(re.fullmatch(r"[0-9a-f]{64}", str(impl.get("mapping_manifest_sha256", ""))))),
        ("raw benchmark digest", bool(re.fullmatch(r"[0-9a-f]{64}", str(bench.get("raw_results_sha256", ""))))),
        ("complete end-to-end accounting", bench.get("accounting_complete") is True),
        ("measured ratio consistency", False),
    ]

    b = bench.get("baseline_e2e_ns")
    o = bench.get("optimized_e2e_ns")
    s = bench.get("speedup_measured")
    if (isinstance(b, (int, float)) and not isinstance(b, bool) and
            isinstance(o, (int, float)) and not isinstance(o, bool) and
            isinstance(s, (int, float)) and not isinstance(s, bool) and
            b > 0 and o > 0 and s > 0):
        ratio = b / o
        required[-1] = (
            "measured speedup agrees with raw E2E timings",
            abs(ratio - s) <= max(1e-9, abs(ratio) * 1e-6),
        )

    for label, ok in required:
        if not ok:
            reasons.append(label + " not proven/passed")

    claim = promotion.get("claim_strength", "HYPOTHESIS")
    evidence = promotion.get("evidence_strength", "NONE")
    rank = {"HYPOTHESIS": 0, "STRUCTURAL": 1, "MEASURED": 2, "VERIFIED": 3, "CUMULATIVE_VERIFIED": 4}
    erank = {"NONE": 0, "STRUCTURAL": 1, "MEASURED": 2, "FORMAL": 2, "INDEPENDENTLY_CHECKED": 3, "END_TO_END_VERIFIED": 4}
    if rank.get(claim, 99) > erank.get(evidence, -1):
        reasons.append("ClaimStrength exceeds EvidenceStrength")

    return {"status": "PROMOTED" if not reasons else "BLOCKED", "block_reasons": reasons}


def self_test():
    base = {
        "source": {"dirty_tree": False},
        "formal": {"build_status": "PASS", "sorry_scan": "PASS", "kernel_replay_status": "PASS", "independent_checker_status": "PASS"},
        "implementation": {"equivalence_status": "PASS", "mapping_manifest_sha256": "b" * 64},
        "execution": {"runtime_status": "PASS", "telemetry_sha256": "a" * 64, "environment_manifest_sha256": "c" * 64},
        "benchmark": {"baseline_e2e_ns": 1000, "optimized_e2e_ns": 500, "speedup_measured": 2.0, "accounting_complete": True, "raw_results_sha256": "d" * 64},
        "promotion": {"claim_strength": "VERIFIED", "evidence_strength": "END_TO_END_VERIFIED"},
    }
    good = promotion_decision(base)
    bad = promotion_decision({**base, "formal": {**base["formal"], "independent_checker_status": "NOT_CONFIGURED"}})
    bad2 = promotion_decision({**base, "benchmark": {**base["benchmark"], "speedup_measured": 999}})
    bad3 = promotion_decision({**base, "source": {"dirty_tree": True}})
    assert good["status"] == "PROMOTED", good
    assert bad["status"] == "BLOCKED", bad
    assert bad2["status"] == "BLOCKED", bad2
    assert bad3["status"] == "BLOCKED", bad3

    out = pathlib.Path("artifacts/pcss-schema")
    out.mkdir(parents=True, exist_ok=True)
    receipt = {
        "self_test": "PASS",
        "positive_case": "PASS",
        "missing_checker_case": "BLOCKED",
        "ratio_mismatch_case": "BLOCKED",
        "dirty_source_case": "BLOCKED",
        "hash_shape_checks": "ENFORCED_BY_JSON_SCHEMA",
    }
    receipt["sha256"] = hashlib.sha256(json.dumps(receipt, sort_keys=True, separators=(",", ":")).encode()).hexdigest()
    (out / "schema-self-test.json").write_text(json.dumps(receipt, indent=2) + "\n")
    print(json.dumps(receipt, indent=2))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--schema", required=True)
    ap.add_argument("--self-test", action="store_true")
    ap.add_argument("--evidence")
    args = ap.parse_args()

    schema = json.loads(pathlib.Path(args.schema).read_text(encoding="utf-8"))
    Draft202012Validator.check_schema(schema)

    if args.self_test:
        self_test()

    if args.evidence:
        evidence_path = pathlib.Path(args.evidence)
        d = json.loads(evidence_path.read_text(encoding="utf-8"))
        try:
            Draft202012Validator(schema).validate(d)
        except ValidationError as exc:
            print(json.dumps({
                "status": "BLOCKED",
                "stage": "JSON_SCHEMA",
                "path": list(exc.absolute_path),
                "reason": exc.message,
            }, indent=2))
            sys.exit(2)

        result = promotion_decision(d)
        print(json.dumps(result, indent=2))
        sys.exit(0 if result["status"] == "PROMOTED" else 1)


if __name__ == "__main__":
    main()
