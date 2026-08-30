# Module 03 — Exercises

After the core lab. KQL: `assets/module_03/explore.kql`. Prefer data from **`app_traffic_simulator.sh`** (or console JSON events), not only the three-line probe script.

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

### E4 — Parse app fields (real-shaped logs)

```kusto
CloudWatchLogs
| where messageType == "DATA_MESSAGE"
| mv-expand e = logEvents
| extend parsed = parse_json(tostring(e.message))
| where isnotempty(parsed)
| project Event = tostring(parsed.event), Level = tostring(parsed.level), Service = tostring(parsed.service), Message = e.message
| summarize n = count() by Event, Level
| order by n desc
```

You should see events such as `order.created`, `auth.login.failed`, `http.request` if you used the app simulator.

## Stretch — generate more like production

### E5 — Second wave of app traffic

Re-run:

```bash
export MSYS_NO_PATHCONV=1
bash assets/module_03/app_traffic_simulator.sh us-east-1 <your-login> 3
```

Wait 60–90s, ingest a new S3 object, re-run E4. Counts should grow.

### E6 — Insights vs ADX

In CloudWatch Logs Insights on your log group:

```sql
fields @timestamp, @message
| filter @message like /ERROR|order\.created/
| sort @timestamp desc
| limit 20
```

Same filter idea in ADX (E4). Compare delay (Firehose buffer) and envelope vs inner JSON.

### E7 — Manual “incident” line (no script)

Console → your stream → **Create log event** with:

```json
{"level":"ERROR","service":"checkout-api","event":"payment.declined","orderId":"ord-incident-1","reason":"card_declined"}
```

Wait for S3, ingest, find `payment.declined` with E4. This is how on-call sometimes injects a marker line during an incident.

### E8 — Filter pattern (trainer demo)

Subscription filter for `ERROR` only — discuss what reaches S3 after mixed INFO/WARN/ERROR traffic.
