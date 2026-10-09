# AGD/MUNI Device Edge Runbook

## Contract

The edge bridge samples available sensor/cpufreq values and optionally invokes the proof-gated MUNI API. It is not a kernel governor: it never writes CPU governor, frequency, scheduler, battery, or thermal-limit knobs. Android/kernel thermal protection remains authoritative.

## Verified findings (2026-10-09)

- Existing MUNI API `/health` returned HTTP 200 / `integrity: PASS`.
- Supported formal scope remains `U = Ubar ⊗ I_m` on block-constant states only.
- Existing synthetic benchmark receipts: ARM64 Debian PRoot `d=4096,m=64,steps=64`, 64.113911×; Termux/Bionic on same physical device `d=512,m=16,steps=32`, 20.050822×. These are local workload witnesses, not arbitrary-transformer results or independent hardware.
- Live sysfs sampling read CPU frequency and thermal zones. CPU/SoC sensors were mid-to-high 50s °C, and `socd` reported 68–69 °C in observed samples. Sentinel zones (0, -40, -273 °C) were excluded by the refined parser. The policy selected `COOLDOWN`; no benchmark ran.
- `termux-battery-status` timed out; `termux-thermal-status` was not found in the remote execution context; `adb devices` was empty. Datadog had only sparse historic `sim2xr.device.*` series, no recent 6-hour samples and no tag values.
- Disk has approximately 2.1 GB free on a 222 GB volume; defer long soak runs until storage has headroom.

## Run

```sh
python3 -m unittest discover -s muni/edge -p 'test_device_governor.py' -v
python3 muni/edge/device_governor.py --once --observe-only --out /tmp/agd-edge.jsonl
python3 muni/edge/device_governor.py --iterations 20 --interval 10 --d 512 --m 16 --steps 16 --trials 3 --out /tmp/agd-edge.jsonl
```

A benchmark loop runs only when evidence integrity passes and usable CPU/SoC thermal samples are under the configured guard (default 42 °C), with no rapid rise. Missing/stale sensors cause `OBSERVE_ONLY`; a failed evidence/correctness/path gate causes `QUARANTINE`; a hot/rapidly rising sensor causes `COOLDOWN`. The configured threshold is a conservative app policy, not a claimed device manufacturer limit.

## Requirements for direct Termux integration

1. Run from the actual Termux app process, not only a Debian PRoot shell.
2. Install the matching Termux:API companion app and Termux package; confirm `termux-battery-status` yields valid JSON, and check what thermal commands are provided by that installed version.
3. Probe readable `/sys/class/thermal/thermal_zone*/{type,temp}` and `/sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq`. Treat blocked/absent values as unavailable, not zero.
4. Do not write cpufreq/thermal knobs; require a separately audited, rooted/kernel-specific design if hardware control is ever proposed.
5. Telemetry should write local append-only JSONL first; upload only under an approved Datadog configuration and out-of-band secret provisioning. Use low-cardinality tags (`device_id`, `build`, `runtime`, `algorithm`, `source`), never account/email identifiers.

## Datadog integration requirements

Datadog metric names `sim2xr.device.*` exist, but initial checks found no data in the last 6 hours and no indexed tag values. Proposed metric contract and query payload are documented separately. The connected Datadog dashboard writer is disabled for this organization; no dashboard or metric submission was performed.

Recommended metrics: `agd.muni.thermal.cpu_soc_max_c`, `agd.muni.thermal.battery_c`, `agd.muni.cpu.frequency_mhz`, `agd.muni.cpu.utilization_pct`, `agd.muni.benchmark.baseline_ms`, `agd.muni.benchmark.optimized_ms`, `agd.muni.benchmark.speedup`, `agd.muni.benchmark.max_abs_error`, `agd.muni.evidence_integrity`, `agd.muni.telemetry.valid_sensor_count`, plus a governor mode tag.

## Sustained-performance acceptance

Before any sustained claim: at least 30 paired baseline/optimized blocks in randomized or ABBA order; warm-up separated; identical inputs, compiler/build and thread/runtime conditions; at least 20 minutes or a pre-registered target workload; report median/p95/p99 latency, throughput, memory and per-sample thermal/frequency; exact correctness gate per pair; retain all exclusions and all raw receipts. Test absent/stale sensors, API failure, hash mismatch, invalid shapes, non-admissibility/fallback, malformed requests, NaN/Inf, memory/disk pressure, timeouts, cancellation, and thermal throttling. Report dispersion; do not select only the maximum multiplier.

## Public production gaps

Authentication/authorization, quotas and concurrency controls, process isolation, caller-data schema/hash binding, API version migration, audit-log rotation, HTTPS for any non-loopback deployment, dependencies/SBOM and licenses, signed release artifacts, reproducible clean-machine builds, Android permission UX, multi-device soak tests, privacy/retention controls, threat model, and independent security review remain open. This is not yet a production-ready public service.
