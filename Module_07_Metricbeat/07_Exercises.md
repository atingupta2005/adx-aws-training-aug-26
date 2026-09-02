# Module 07 — Exercises

After the core lab. KQL: `assets/module_07/explore.kql`.

## Practice

### E1 — Metricsets present

```kusto
SystemMetrics
| summarize Rows = count() by Metricset
| order by Rows desc
```

### E2 — Average CPU

```kusto
SystemMetrics
| where isnotnull(CPU_User_Pct)
| extend UserPct = CPU_User_Pct * 100
| summarize AvgUser = avg(UserPct), MaxUser = max(UserPct) by Hostname
```

### E3 — Memory

```kusto
SystemMetrics
| where isnotnull(Mem_Used_Pct)
| extend UsedPct = Mem_Used_Pct * 100
| summarize AvgUsed = avg(UsedPct) by Hostname
```

### E4 — CPU timechart

```kusto
SystemMetrics
| where isnotnull(CPU_User_Pct)
| extend UserPct = CPU_User_Pct * 100
| summarize AvgUser = avg(UserPct) by bin(LogTime, 1m)
| render timechart
```

## Stretch

### E5 — Disk usage

Query filesystem columns; find mounts above 80% used.

### E6 — CPU load test

Brief CPU load on VM (trainer OK); watch chart after lag.

### E7 — vs CloudWatch Metrics

Which AWS metrics mirror this host data?
