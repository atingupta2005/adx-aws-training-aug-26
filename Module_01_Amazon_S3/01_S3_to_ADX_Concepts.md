# Module 01 — S3 to ADX

> **Reading order:** `01_S3_Primer.md` → Concepts (this file) → Lab → Exercises.

ADX runs KQL. S3 holds files. ADX pulls objects over HTTPS with IAM keys on the **ingest URI** — same pattern as later modules (CloudTrail, CloudWatch via Firehose, GuardDuty).

Wrong mapping? Fix it and re-ingest the **same** S3 key.

**Module 01 capture uses live AWS API responses** — see `assets/REAL_VS_LAB_DATA.md`.

S3 basics and console tour: **`01_S3_Primer.md`**.

## Two key pairs

```mermaid
%%{init: {"theme":"base","flowchart":{"htmlLabels":true,"padding":12}}}%%
flowchart TB
  CARD["Card keys u01<br/>console + aws configure"]
  READ["Reader keys<br/>.ingest URI only"]
  BUCKET[("adx-log-ingestion-u01")]
  CARD -->|"creates + upload"| BUCKET
  READ -->|"ADX GET"| BUCKET
  style CARD fill:#FF9900,stroke:#232F3E,color:#fff
  style READ fill:#0078D4,stroke:#005A9E,color:#fff
  style BUCKET fill:#232F3E,stroke:#FF9900,color:#fff
```

## How data moves

```mermaid
%%{init: {"theme":"base","flowchart":{"htmlLabels":true,"padding":12}}}%%
flowchart TB
  CLI["AWS CLI"] --> S3[("S3")]
  S3 -->|".ingest"| T[("AppLogs_JSON + AppLogs_CSV")]
  T --> KQL["KQL"]
  style CLI fill:#FF9900,stroke:#232F3E,color:#fff
  style S3 fill:#232F3E,stroke:#FF9900,color:#fff
  style T fill:#0078D4,stroke:#005A9E,color:#fff
  style KQL fill:#107C10,stroke:#0B5A0B,color:#fff
```

Create tables and mappings **before** `.ingest`. Reader policy needs `GetBucketLocation` (see `assets/iam/s3-reader-policy.json`).

## JSON and CSV mappings

| File | Format | ADX binding |
|------|--------|-------------|
| `aws_api_logs.ndjson` | one JSON object per line | JSONPath, e.g. `$.timestamp` |
| `aws_regions.csv` | no header row | column index 0, 1, … |

```text
https://<bucket>.s3.<region>.amazonaws.com/<key>;AwsCredentials=<access_key_id>,<secret>
```

Use `AwsCredentials=` with a **comma** between id and secret.
