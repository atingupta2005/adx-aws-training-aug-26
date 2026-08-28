# Module 01 — Exercises

After the core lab. KQL: `assets/module_01/explore.kql`.

## Practice

### E1 — Inventory your bucket

```bash
aws s3 ls s3://adx-log-ingestion-<your-login>/ --human-readable
```

Compare object sizes to `AppLogs_JSON | count` and `AppLogs_CSV | count`.

### E2 — Service breakdown

```kusto
AppLogs_JSON
| summarize Events = count() by ServiceName
| order by Events desc
```

### E3 — HTTP status filter

```kusto
AppLogs_JSON
| where HttpStatus >= 400
| project LogTime, ServiceName, Message, HttpStatus
```

### E4 — CSV regions

```kusto
AppLogs_CSV
| summarize Regions = count() by RegionCode
| order by RegionCode asc
```

## Stretch

### E5 — Re-ingest the same key

Run one `.ingest` again without changes. Did row count double?

### E6 — Manual NDJSON line

Upload a one-line NDJSON you write. Discuss with trainer before dropping tables.

### E7 — Key pairs sketch

Draw card user vs reader vs ADX on paper.
