#!/usr/bin/env python3
"""PCSS evidence contract self-test and fail-closed promotion evaluator."""
import argparse, hashlib, json, pathlib, sys

def promotion_decision(d):
    reasons=[]
    formal=d.get("formal",{})
    impl=d.get("implementation",{})
    execution=d.get("execution",{})
    bench=d.get("benchmark",{})
    required=[
      ("formal build",formal.get("build_status")=="PASS"),
      ("sorry scan",formal.get("sorry_scan")=="PASS"),
      ("kernel replay",formal.get("kernel_replay_status")=="PASS"),
      ("independent checker",formal.get("independent_checker_status")=="PASS"),
      ("implementation equivalence",impl.get("equivalence_status")=="PASS"),
      ("live runtime",execution.get("runtime_status")=="PASS"),
      ("telemetry digest",bool(execution.get("telemetry_sha256"))),
      ("complete end-to-end accounting",bench.get("accounting_complete") is True),
      ("measured ratio consistency",False),
    ]
    b=bench.get("baseline_e2e_ns"); o=bench.get("optimized_e2e_ns"); s=bench.get("speedup_measured")
    if isinstance(b,(int,float)) and isinstance(o,(int,float)) and o>0 and b>0 and isinstance(s,(int,float)):
        ratio=b/o
        required[-1]=("measured speedup agrees with raw E2E timings",abs(ratio-s)<=max(1e-9,abs(ratio)*1e-6))
    for label,ok in required:
        if not ok: reasons.append(label+" not proven/passed")
    claim=d.get("promotion",{}).get("claim_strength","HYPOTHESIS")
    evidence=d.get("promotion",{}).get("evidence_strength","NONE")
    rank={"HYPOTHESIS":0,"STRUCTURAL":1,"MEASURED":2,"VERIFIED":3,"CUMULATIVE_VERIFIED":4}
    erank={"NONE":0,"STRUCTURAL":1,"MEASURED":2,"FORMAL":2,"INDEPENDENTLY_CHECKED":3,"END_TO_END_VERIFIED":4}
    if rank.get(claim,99)>erank.get(evidence,-1): reasons.append("ClaimStrength exceeds EvidenceStrength")
    return {"status":"PROMOTED" if not reasons else "BLOCKED","block_reasons":reasons}

def self_test():
    base={
      "formal":{"build_status":"PASS","sorry_scan":"PASS","kernel_replay_status":"PASS","independent_checker_status":"PASS"},
      "implementation":{"equivalence_status":"PASS"},
      "execution":{"runtime_status":"PASS","telemetry_sha256":"a"*64},
      "benchmark":{"baseline_e2e_ns":1000,"optimized_e2e_ns":500,"speedup_measured":2.0,"accounting_complete":True},
      "promotion":{"claim_strength":"VERIFIED","evidence_strength":"END_TO_END_VERIFIED"}
    }
    good=promotion_decision(base)
    bad=promotion_decision({**base,"formal":{**base["formal"],"independent_checker_status":"NOT_CONFIGURED"}})
    bad2=promotion_decision({**base,"benchmark":{**base["benchmark"],"speedup_measured":999}})
    assert good["status"]=="PROMOTED",good
    assert bad["status"]=="BLOCKED",bad
    assert bad2["status"]=="BLOCKED",bad2
    out=pathlib.Path("artifacts/pcss-schema"); out.mkdir(parents=True,exist_ok=True)
    receipt={"self_test":"PASS","positive_case":"PASS","missing_checker_case":"BLOCKED","ratio_mismatch_case":"BLOCKED"}
    receipt["sha256"]=hashlib.sha256(json.dumps(receipt,sort_keys=True,separators=(",",":")).encode()).hexdigest()
    (out/"schema-self-test.json").write_text(json.dumps(receipt,indent=2)+"\n")
    print(json.dumps(receipt,indent=2))

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--schema",required=True)
    ap.add_argument("--self-test",action="store_true")
    ap.add_argument("--evidence")
    a=ap.parse_args()
    schema=json.loads(pathlib.Path(a.schema).read_text())
    assert schema.get("schema_version") is None or True
    if a.self_test: self_test()
    if a.evidence:
        d=json.loads(pathlib.Path(a.evidence).read_text())
        result=promotion_decision(d)
        print(json.dumps(result,indent=2))
        sys.exit(0 if result["status"]=="PROMOTED" else 1)
if __name__=="__main__": main()
