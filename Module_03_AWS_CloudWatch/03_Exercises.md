# Module 03 — Exercises

After the core lab. KQL: `assets/module_03/explore.kql`.

## Practice

### E1 — DATA_MESSAGE only

```kusto
CloudWatchLogs
| where messageType == "DATA_MESSAGE"
| count
```

### E2 — By log stream

```kusto
CloudWatchLogs
| where messageType == "DATA_MESSAGE"
| summarize Events = count() by logStream
```

### E3 — Expand logEvents

```kusto
CloudWatchLogs
| where messageType == "DATA_MESSAGE"
| mv-expand e = logEvents
| project logGroup, logStream, EventTime = e.timestamp, Message = e.message
| take 20
```

### E4 — Parse inner JSON

```kusto
CloudWatchLogs
| where messageType == "DATA_MESSAGE"
| mv-expand e = logEvents
| extend parsed = parse_json(tostring(e.message))
| where isnotempty(parsed)
| take 10
```

## Stretch

### E5 — Second put

Re-run `put_log_events.sh`, wait, ingest a new S3 object.

### E6 — Insights vs ADX

Run "last 20 messages" in CloudWatch Logs Insights and in ADX. Compare delay and shape.

### E7 — Filter pattern (trainer demo)

Subscription filter for `ERROR` only — discuss what reaches S3.
