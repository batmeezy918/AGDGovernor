# Datadog dashboard query plan — AGD/MUNI edge

**Status:** Proposal only. The connected Datadog integration reports that dashboard write tools are not enabled for this organization. No dashboard was created.

## Current sensor state

The existing `sim2xr.device.*` metrics have a small number of historical points, but queries over the last 6 hours return no data and metric tag discovery returns no values. Thus we cannot reliably scope historical points to this exact phone. Do not use these unscoped historical points as proof of a current phone state.

## Required agent metric contract

Emit one sample per completed iteration, with tags `device_id:<stable-local-random-id>`, `runtime:termux|proot`, `algorithm:muni`, `build:<short-build-id>`, `source:agd-edge-agent`; never emit email/account identifiers. Proposed metrics:

- `agd.muni.thermal.cpu_soc_max_c` gauge °C
- `agd.muni.thermal.battery_c` gauge °C
- `agd.muni.cpu.frequency_mhz` gauge MHz
- `agd.muni.cpu.utilization_pct` gauge %
- `agd.muni.benchmark.baseline_ms` gauge ms
- `agd.muni.benchmark.optimized_ms` gauge ms
- `agd.muni.benchmark.speedup` gauge x
- `agd.muni.benchmark.max_abs_error` gauge, exact gate must remain 0
- `agd.muni.evidence_integrity` gauge 1 pass / 0 fail
- `agd.muni.telemetry.valid_sensor_count` gauge count

Use an approved Datadog Agent or Metrics API integration; provision secrets out of band and never commit API keys. Add retry/backoff, bounded local queue, and privacy/retention controls.

## Queries after authorized ingestion begins

```text
max:agd.muni.thermal.cpu_soc_max_c{*} by {device_id}
avg:agd.muni.cpu.frequency_mhz{*} by {device_id}
avg:agd.muni.cpu.utilization_pct{*} by {device_id}
p95:agd.muni.benchmark.optimized_ms{*} by {device_id}
p50:agd.muni.benchmark.speedup{*} by {device_id}
max:agd.muni.benchmark.max_abs_error{*} by {device_id}
min:agd.muni.evidence_integrity{*} by {device_id}
```

Proposed query names are not active until an approved exporter sends samples and Datadog accepts them.

## Alert policy

- Correctness error != 0 or evidence integrity == 0: critical, quarantine optimized path and preserve receipt.
- Thermal threshold exceedance or rapid rise: stop workload and cool down; do not manipulate OS thermal policy.
- No samples for 5 minutes: `TELEMETRY_STALE`, not zero; disable unattended benchmark scheduling.
- No thermal samples: `OBSERVE_ONLY`; no unattended stress.
- Paired speedup < 1: report regression; do not automatically escalate intensity.
