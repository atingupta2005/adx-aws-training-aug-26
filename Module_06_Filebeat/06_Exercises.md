# Module 06 — Exercises

After the core lab. KQL: `assets/module_06/explore.kql`.

## Practice

### E1 — By ServerType

```kusto
WebServerLogs
| summarize Events = count() by ServerType
| order by Events desc
```

### E2 — Web hits only

```kusto
WebServerLogs
| where ServerType in ("Apache", "NGINX") and StatusCode > 0
| take 20
```

### E3 — Top client IPs

```kusto
WebServerLogs
| where StatusCode > 0
| summarize Hits = count() by ClientIP
| order by Hits desc
| take 10
```

### E4 — Linux syslog

```kusto
WebServerLogs
| where ServerType == "Linux"
| take 10
| project LogTime, Hostname, Message
```

## Stretch

### E5 — Status chart

```kusto
WebServerLogs
| where StatusCode > 0
| summarize Hits = count() by StatusCode
| render barchart
```

### E6 — Filebeat offsets

Discuss where Filebeat stores read offsets on the VM.

### E7 — Fourth input (trainer)

Add one Filebeat input with approval; confirm in ADX.
