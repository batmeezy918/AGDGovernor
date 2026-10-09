# AGD/MUNI Edge Governor Bridge

This directory contains the prototype telemetry/pacing agent, edge-policy tests, runbook, and proposed Datadog dashboard/query contract.

The agent reports only readings it can observe. Thermal sentinels and absent sensors are handled explicitly. When evidence integrity fails it quarantines execution; when thermal telemetry is missing it refuses unattended stress; when CPU/SoC temperature crosses its conservative configured guard or rises quickly it enters cooldown. It never writes CPU governor, frequency, scheduler, or thermal-limit knobs.

See `DEVICE_EDGE_RUNBOOK.md` for requirements, on-device findings, acceptance criteria, and production gaps. `datadog_dashboard_proposal.json` and `DEVICE_TELEMETRY_DASHBOARD_QUERIES.md` are proposals only: the current connected Datadog writer is not enabled and the account has not shown fresh samples for its pre-existing device metrics.

## Local run

```sh
python3 -m unittest discover -s muni/edge -p 'test_device_governor.py' -v
python3 muni/edge/device_governor.py --once --observe-only --out /tmp/agd-edge.jsonl
```

A benchmark run is intentionally withheld under the latest observed high CPU/SoC temperatures. Do not interpret a missing speedup sample as zero or a passing mathematical proof as a sustained silicon-performance result.