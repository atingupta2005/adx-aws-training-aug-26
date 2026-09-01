# Module 05 — Exercises

After the core lab. KQL: `assets/module_05/explore.kql`.

## Practice

### E1 — Row count

```kusto
LogstashHostLogs | count
```

### E2 — Top processes

```kusto
LogstashHostLogs
| summarize Events = count() by Process
| order by Events desc
```

### E3 — Recent messages

```kusto
LogstashHostLogs
| order by LogTime desc
| take 20
| project LogTime, Hostname, Process, Pid, Message
```

### E4 — SSH failures

```kusto
LogstashHostLogs
| where Message contains "Failed" or Message contains "failure"
| take 20
```

## Stretch

### E5 — New auth lines

Generate activity on the VM (trainer OK). Confirm rows after ingest lag.

### E6 — Pipeline walkthrough

Identify input, grok, and kusto blocks in `/tmp/logstash-lab/adx-pipeline.conf`.

### E7 — S3 vs Logstash

List three differences from Module 01 batch ingest.
