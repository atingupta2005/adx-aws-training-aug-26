# Module 04 — Exercises

After the core lab. KQL: `assets/module_04/explore.kql`.

## Practice

### E1 — Count by environment

```kusto
UnifiedHybridLogs
| summarize Events = count() by Environment
```

### E2 — Unified timeline

```kusto
UnifiedHybridLogs
| order by LogTime desc
| take 30
| project LogTime, Environment, SourceService, LogLevel, Message
```

### E3 — Errors only

```kusto
UnifiedHybridLogs
| where LogLevel == "ERROR"
| summarize Events = count() by Environment, SourceService
```

### E4 — Raw vs unified counts

```kusto
RawAWSLogs | count
RawOnPremLogs | count
UnifiedHybridLogs | count
```

## Stretch

### E5 — Extra on-prem row

Append one simulated firewall line (trainer pattern). Confirm unified updates.

### E6 — CloudWatch load path

Try `load_from_cloudwatch.kql` if you used CloudTrail in the lab.

### E7 — Design sketch

Where would VPN fit if on-prem were real?
