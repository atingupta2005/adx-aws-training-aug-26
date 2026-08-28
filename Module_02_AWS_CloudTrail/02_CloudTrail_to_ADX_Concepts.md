# Module 02 — CloudTrail to ADX

> **Reading order:** `02_CloudTrail_Primer.md` → Concepts (this file) → Lab → Exercises.

Module 01 used a file **you** uploaded. This module uses gzipped JSON **AWS** wrote — top-level `Records` array, delivery often **5–15 minutes**.

- Ingest format: **`multijson`** (pretty-printed file, not single-line `json`)
- **`CloudTrailRaw`**: one row per file → **`CloudTrailEvents`**: one row per API call after expand

AWS primer (what CloudTrail is, shared trail): **`02_CloudTrail_Primer.md`**.

## How data moves

```mermaid
%%{init: {"theme":"base","flowchart":{"htmlLabels":true,"padding":12}}}%%
flowchart TB
  subgraph awsBox [AWS]
    API["CLI calls"]
    CT["CloudTrail"]
    S3[("Trail bucket")]
  end
  subgraph azureBox [Azure]
    RAW[("CloudTrailRaw")]
    EVT[("CloudTrailEvents")]
    KQL["KQL"]
  end
  API --> CT
  CT -->|"json.gz later"| S3
  S3 -->|".ingest"| RAW
  RAW -->|"expand Records"| EVT
  EVT --> KQL
  style awsBox fill:#FFF4E5,stroke:#FF9900,color:#232F3E
  style azureBox fill:#E6F2FB,stroke:#0078D4,color:#003A5D
  style API fill:#FF9900,stroke:#232F3E,color:#fff
  style CT fill:#EC7211,stroke:#232F3E,color:#fff
  style S3 fill:#232F3E,stroke:#FF9900,color:#fff
  style RAW fill:#0078D4,stroke:#005A9E,color:#fff
  style EVT fill:#50E6FF,stroke:#0078D4,color:#003A5D
  style KQL fill:#107C10,stroke:#0B5A0B,color:#fff
```

Empty S3 after two minutes is normal — build tables and IAM while waiting.

## One file → many rows

```mermaid
%%{init: {"theme":"base","flowchart":{"htmlLabels":true,"padding":12}}}%%
flowchart LR
  GZ[".json.gz"]
  RAW[("CloudTrailRaw")]
  EVT[("CloudTrailEvents")]
  GZ -->|"multijson"| RAW
  RAW -->|"mv-expand Records"| EVT
  style GZ fill:#232F3E,stroke:#FF9900,color:#fff
  style RAW fill:#0078D4,stroke:#005A9E,color:#fff
  style EVT fill:#50E6FF,stroke:#0078D4,color:#003A5D
```

After expand, query: `eventTime`, `eventName`, `eventSource`, `awsRegion`, `userIdentity.arn`, `errorCode`. Leave `CloudTrailEvents` for Module 04.

## Real activity vs lab script

CloudTrail records **every** API call in your account continuously. Delivery to S3 is **not** instant (typically **5–15 minutes**). The lab script `generate_events.sh` only **schedules recognizable API calls** — it is not fake JSON. For console-only real activity and bulk ingest without manual keys, see **`assets/REAL_VS_LAB_DATA.md`** and Step 5 in the lab (`ingest_s3_prefix.sh`).

## In class

- Shared bucket **`adx-classroom-cloudtrail`** — reader policy on that bucket only
- Filter by your ARN in KQL (`UserArn contains "<login>"`)
