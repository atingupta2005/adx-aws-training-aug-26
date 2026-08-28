# Module 02 — Exercises

After the core lab. KQL: `assets/module_02/explore.kql`.

## Practice

### E1 — Find your activity

Replace `u01` with your login:

```kusto
CloudTrailEvents
| where UserArn contains "u01"
| summarize Events = count() by EventName
| order by Events desc
```

### E2 — Failed vs successful

```kusto
CloudTrailEvents
| summarize Events = count() by ErrorCode
| order by Events desc
```

### E3 — Timeline

```kusto
CloudTrailEvents
| where UserArn contains "u01"
| summarize Events = count() by bin(EventTime, 5m)
| render timechart
```

### E4 — Top services

```kusto
CloudTrailEvents
| summarize Events = count() by EventSource
| order by Events desc
| take 10
```

## Stretch

### E5 — Multi-file ingest

Ingest two `.json.gz` keys in one `.ingest` (lab Step 5). Compare raw vs events counts.

### E6 — Source IP query

From `explore.kql` section B: top source IPs for your user.

### E7 — Raw vs events

```kusto
CloudTrailRaw | take 1 | extend n = array_length(Records) | project n
CloudTrailEvents | count
```

Compare after a single-file ingest.
