#!/usr/bin/env python3
"""AGD/MUNI edge telemetry + conservative pacing governor.

Read-only with respect to CPU governor/sysfs: never writes thermal or cpufreq knobs.
Records what is available, emits null for unavailable sensors, and optionally
runs bounded MUNI benchmark calls. Standard library only.
"""
from __future__ import annotations
import argparse, hashlib, json, math, os, platform, statistics, subprocess, time, urllib.error, urllib.request
from pathlib import Path

DEFAULT_API = "http://127.0.0.1:8765"
THERMAL_ROOT = Path("/sys/class/thermal")
FREQ_ROOT = Path("/sys/devices/system/cpu")


def read_text(path: Path):
    try: return path.read_text().strip()
    except (OSError, PermissionError): return None


def termux_json(command: str, timeout=2):
    try:
        p = subprocess.run([command], capture_output=True, text=True, timeout=timeout, check=False)
        if p.returncode != 0: return {"available": False, "reason": "command_failed", "exit_code": p.returncode}
        try: return {"available": True, "data": json.loads(p.stdout)}
        except json.JSONDecodeError: return {"available": True, "data_text": p.stdout[:2000]}
    except FileNotFoundError: return {"available": False, "reason": "command_not_found"}
    except subprocess.TimeoutExpired: return {"available": False, "reason": "timeout"}


def snapshot():
    thermal = []
    if THERMAL_ROOT.exists():
        for zone in sorted(THERMAL_ROOT.glob("thermal_zone*")):
            typ = read_text(zone / "type")
            raw = read_text(zone / "temp")
            val = None
            if raw is not None:
                try:
                    n = float(raw)
                    # Android sysfs is inconsistent; ignore known sentinel values.
                    val = n / 1000.0 if abs(n) > 1000 else n
                    if not (-20.0 <= val <= 150.0) or val in (-40.0, -273.0, 0.0): val = None
                except ValueError: pass
            thermal.append({"zone": zone.name, "type": typ, "raw": raw, "celsius": val, "valid": val is not None})
    freqs = []
    if FREQ_ROOT.exists():
        for node in sorted(FREQ_ROOT.glob("cpu*/cpufreq/scaling_cur_freq")):
            raw = read_text(node)
            try: mhz = float(raw) / 1000 if raw is not None else None
            except ValueError: mhz = None
            freqs.append({"cpu": node.parts[-3], "mhz": mhz})
    battery = termux_json("termux-battery-status")
    thermal_api = termux_json("termux-thermal-status")
    return {
        "schema": "agd.device.telemetry.v1", "timestamp_unix": time.time(),
        "device": {"hostname": platform.node(), "machine": platform.machine(), "system": platform.system(), "release": platform.release()},
        "thermal_sysfs": {"available": any(z["valid"] for z in thermal), "zones": thermal,
          "valid_sensor_count": sum(1 for z in thermal if z["valid"]),
          "cpu_soc_max_c": max((z["celsius"] for z in thermal if z["celsius"] is not None and any(k in (z["type"] or "").lower() for k in ("cpu", "cpuss", "socd"))), default=None),
          "battery_c": next((z["celsius"] for z in thermal if z["celsius"] is not None and (z["type"] or "").lower() == "battery"), None),
          "max_c": max((z["celsius"] for z in thermal if z["celsius"] is not None), default=None)},
        "frequency_sysfs": {"available": bool(freqs), "cpus": freqs,
          "avg_mhz": statistics.mean([c["mhz"] for c in freqs if c["mhz"] is not None]) if any(c["mhz"] is not None for c in freqs) else None},
        "termux_battery": battery, "termux_thermal": thermal_api,
        "linux": {"uptime": read_text(Path("/proc/uptime")), "loadavg": read_text(Path("/proc/loadavg"))},
        "control_policy": "OBSERVE_AND_PACE_ONLY; no sysfs writes; Android thermal protections remain authoritative"
    }


def api_get(base, path, timeout=4):
    with urllib.request.urlopen(base.rstrip("/") + path, timeout=timeout) as r: return json.loads(r.read())


def api_post(base, path, obj, timeout=65):
    req = urllib.request.Request(base.rstrip("/") + path, data=json.dumps(obj, separators=(",", ":")).encode(), headers={"Content-Type":"application/json"}, method="POST")
    with urllib.request.urlopen(req, timeout=timeout) as r: return json.loads(r.read())


def governor_decision(samples, temp_limit_c=42.0):
    temps=[]
    for s in samples:
        t=s.get("thermal_sysfs", {})
        for x in (t.get("cpu_soc_max_c", t.get("max_c")), t.get("battery_c")):
            if isinstance(x,(int,float)) and math.isfinite(x): temps.append(x)
    if not temps: return {"mode":"OBSERVE_ONLY","reason":"thermal_sensor_unavailable","allowed_action":"NO_AUTONOMOUS_STRESS; collect telemetry only"}
    if max(temps) >= temp_limit_c: return {"mode":"COOLDOWN","reason":"thermal_limit_reached","allowed_action":"STOP_WORKLOAD_AND_COOLDOWN"}
    if len(temps)>=2 and temps[-1]-temps[0]>=3.0: return {"mode":"COOLDOWN","reason":"rapid_temperature_rise","allowed_action":"STOP_WORKLOAD_AND_COOLDOWN"}
    return {"mode":"PACE","reason":"thermal_samples_within_configured_guard","allowed_action":"bounded_workload_with_pause_between_iterations"}


def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--api",default=DEFAULT_API); ap.add_argument("--out",default="device_governor_run.jsonl")
    ap.add_argument("--iterations",type=int,default=20); ap.add_argument("--interval",type=float,default=5.0)
    ap.add_argument("--d",type=int,default=512); ap.add_argument("--m",type=int,default=16); ap.add_argument("--steps",type=int,default=16); ap.add_argument("--trials",type=int,default=3)
    ap.add_argument("--temp-limit-c",type=float,default=42.0); ap.add_argument("--observe-only",action="store_true"); ap.add_argument("--once",action="store_true")
    a=ap.parse_args()
    if not 1<=a.iterations<=1000 or not 0.5<=a.interval<=300: ap.error("iterations 1..1000 and interval 0.5..300 required")
    if not (1<=a.d<=16384 and 1<=a.m<=a.d and a.d%a.m==0 and 0<=a.steps<=10000 and 3<=a.trials<=31): ap.error("invalid bounded benchmark parameters")
    output=Path(a.out).expanduser().resolve(); output.parent.mkdir(parents=True,exist_ok=True)
    rows=[]; count=1 if a.once else a.iterations
    for i in range(count):
        started=time.monotonic(); row={"iteration":i,"telemetry":snapshot()}
        try:
            h=api_get(a.api,"/health"); row["api_health"]={"integrity":h.get("integrity"),"checks":h.get("checks")}
            if h.get("integrity")!="PASS": row["decision"]={"mode":"QUARANTINE","reason":"evidence_integrity_failed","allowed_action":"NO_BENCHMARK"}
            else:
                d=governor_decision([x["telemetry"] for x in rows[-2:]]+[row["telemetry"]],a.temp_limit_c)
                if a.observe_only or d["mode"]!="PACE": row["decision"]={**d,"allowed_action":"OBSERVE_ONLY" if a.observe_only else d["allowed_action"]}
                else:
                    row["decision"]=d; res=api_post(a.api,"/v1/benchmark",{"d":a.d,"m":a.m,"steps":a.steps,"trials":a.trials}).get("result",{})
                    row["benchmark"]={k:res.get(k) for k in ("baseline_ms","optimised_ms","speedup","max_abs_error","in_fallback","request_id","claim_class")}
                    if res.get("max_abs_error")!=0 or res.get("in_fallback"): row["decision"]={"mode":"QUARANTINE","reason":"correctness_or_path_gate_failed","allowed_action":"STOP_AND_REPORT"}
        except (OSError,urllib.error.URLError,TimeoutError,ValueError) as e: row["api_error"]=repr(e); row["decision"]={"mode":"OBSERVE_ONLY","reason":"api_unavailable","allowed_action":"NO_BENCHMARK"}
        row["sample_elapsed_s"]=time.monotonic()-started; canon=json.dumps(row,sort_keys=True,separators=(",",":")); row["record_sha256"]=hashlib.sha256(canon.encode()).hexdigest()
        with output.open("a",encoding="utf-8") as f: f.write(json.dumps(row,sort_keys=True)+"\n")
        rows.append(row); print(json.dumps({"iteration":i,"mode":row["decision"]["mode"],"reason":row["decision"]["reason"],"cpu_soc_c":row["telemetry"]["thermal_sysfs"]["cpu_soc_max_c"],"benchmark":row.get("benchmark")},sort_keys=True),flush=True)
        if i+1<count: time.sleep(max(0.0,a.interval-(time.monotonic()-started)))
    valid=[r["benchmark"]["speedup"] for r in rows if isinstance(r.get("benchmark",{}).get("speedup"),(int,float)) and r["benchmark"].get("max_abs_error")==0]
    print(json.dumps({"schema":"agd.device.governor.summary.v1","iterations":len(rows),"valid_benchmarks":len(valid),"speedup_median":statistics.median(valid) if valid else None,"speedup_min":min(valid) if valid else None,"speedup_max":max(valid) if valid else None,"record_file":str(output),"sustained_speedup_claim":"NOT_ESTABLISHED_BY_SHORT_RUN"},indent=2))

if __name__=="__main__": main()
