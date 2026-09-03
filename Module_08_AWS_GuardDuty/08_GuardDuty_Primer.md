# Module 08 — GuardDuty primer

Read this **before** `08_GuardDuty_to_ADX_Concepts.md`.

## What GuardDuty is

**Amazon GuardDuty** watches AWS activity and creates **findings** — JSON security alerts with a type, severity (0–10), and description.

| | CloudTrail (M02) | GuardDuty (M08) |
|---|---|---|
| Shape | One API call | One detected pattern |
| Severity | None | 0–10 |
| Purpose | Audit | Security alert |

---

## EventBridge (why S3 looks “wrapped”)

Findings go: **GuardDuty → EventBridge → Firehose → S3**.

EventBridge adds an **envelope**. The real finding is under `detail`, so ADX uses `$.detail.type` (not `$.type`).

```text
GuardDuty → EventBridge → Firehose → s3://adx-classroom-guardduty-export/guardduty/ → ADX
```

After **Generate sample findings**, wait **60–90 seconds** before checking S3.

---

## Before the lab

1. AWS console (`us-east-1`) → **GuardDuty** → **Findings** and **Settings**.  
2. S3 → bucket **`adx-classroom-guardduty-export`** → folder **`guardduty/`**.

**Checkpoint:** You know GuardDuty ≠ CloudTrail, and why mappings use `$.detail.*`.
