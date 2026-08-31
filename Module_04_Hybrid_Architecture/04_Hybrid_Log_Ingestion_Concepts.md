# Module 04 — Hybrid logs

> **Reading order:** `04_Hybrid_Primer.md` → Concepts (this file) → Lab → Exercises.

Keep **raw** tables per source shape. Project five shared columns into **`UnifiedHybridLogs`** via ADX **update policies**.

| Column | Purpose |
|--------|---------|
| `LogTime` | Event timestamp |
| `Environment` | `AWS` or `On-Premises` |
| `SourceService` | e.g. `eventSource`, log group, `firewall` |
| `LogLevel` | e.g. `ERROR`, `INFO` |
| `Message` | Human-readable summary |

**Policy before load** — attach update policy before `.set-or-append` to raw tables, or unified stays empty for that batch. Details: **`04_Hybrid_Primer.md`**.

## Data flow

```mermaid
%%{init: {"theme":"base","flowchart":{"htmlLabels":true,"padding":12}}}%%
flowchart TB
  CT[("CloudTrailEvents")]
  CW[("CloudWatchLogs")]
  RAW_AWS[("RawAWSLogs")]
  DT["datatable on-prem"]
  RAW_OP[("RawOnPremLogs")]
  UNI[("UnifiedHybridLogs")]
  CT --> RAW_AWS
  CW -.-> RAW_AWS
  DT --> RAW_OP
  RAW_AWS -->|"update policy"| UNI
  RAW_OP -->|"update policy"| UNI
  style CT fill:#EC7211,stroke:#232F3E,color:#fff
  style CW fill:#3B48CC,stroke:#1B2266,color:#fff
  style RAW_AWS fill:#0078D4,stroke:#005A9E,color:#fff
  style RAW_OP fill:#5C2D91,stroke:#3A1D5C,color:#fff
  style UNI fill:#107C10,stroke:#0B5A0B,color:#fff
```

Prerequisite: rows in `CloudTrailEvents` or `CloudWatchLogs` from Module 02 or 03.
