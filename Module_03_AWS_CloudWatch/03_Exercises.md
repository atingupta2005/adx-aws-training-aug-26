# Module 03 — Exercises

After the core lab. KQL: `assets/module_03/explore.kql`.

Use data from **Path A (curl the checkout API)** or **Path B (Lambda Test invokes)** — not only a smoke script.

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

### E4 — Parse app fields

```kusto
CloudWatchLogs
| where messageType == "DATA_MESSAGE"
| mv-expand e = logEvents
| extend parsed = parse_json(tostring(e.message))
| where isnotempty(parsed)
| project Event = tostring(parsed.event), Level = tostring(parsed.level), Service = tostring(parsed.service)
| summarize n = count() by Event, Level
| order by n desc
```

Expect events such as `order.created`, `auth.login.failed`, `http.request` after using the API or Lambda.

## Stretch — more real traffic

### E5 — Drive the API again

With `server.py` still running, send more `curl` orders/logins. Wait 60–90s, ingest a new S3 object, re-run E4.

### E6 — Insights vs ADX

CloudWatch Logs Insights on your log group:

```sql
fields @timestamp, @message
| filter @message like /ERROR|order\.created/
| sort @timestamp desc
| limit 20
```

Compare delay (Firehose) and envelope vs inner JSON in ADX.

### E7 — Incident marker (console)

Stream → **Create log event** with a single `payment.declined` JSON line. Find it after ingest.

### E8 — Filter pattern (trainer demo)

Subscription filter matching `ERROR` only — discuss what reaches S3 after mixed traffic.
