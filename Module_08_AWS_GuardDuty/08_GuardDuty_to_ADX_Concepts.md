# Module 08 — GuardDuty to ADX

> **Reading order:** Primer → Concepts (this file) → Lab → Exercises.

## Goal

Load GuardDuty **findings** into ADX and query them by type and severity.

```text
GuardDuty → EventBridge → Firehose → S3 → .ingest → GuardDutyFindings
```

In class you work mainly in the **AWS console** and the **ADX query** page. Use your normal lab AWS login from the access card.

---

## EventBridge (short)

EventBridge routes “GuardDuty created a finding” to Firehose, which writes to S3. The S3 JSON is an **envelope**; the finding is under **`detail`**. Map `$.detail.id` and `$.detail.type` — not `$.id` / `$.type`.

---

## Mapping

| JSON path | Column |
|-----------|--------|
| `$.time` | `EventTime` |
| `$.account` | `AccountId` |
| `$.region` | `Region` |
| `$.detail.id` | `FindingId` |
| `$.detail.type` | `FindingType` |
| `$.detail.severity` | `Severity` |
| `$.detail.title` | `Title` |
| `$.detail.description` | `Description` |
| `$.detail.resource` | `ResourceData` |

---

## Lab flow

1. Console: **Generate sample findings** → wait 60–90 s.  
2. Console: open `adx-classroom-guardduty-export` / `guardduty/` and copy an object key.  
3. ADX: run `create_tables.kql`.  
4. ADX: `.ingest` that object with your lab access keys.  
5. Query `FindingType` / `Severity`.

---

## Link to earlier modules

| Module | Link |
|--------|------|
| M02 | GuardDuty reads CloudTrail |
| M03 | Same idea of Firehose buffering into S3 |
