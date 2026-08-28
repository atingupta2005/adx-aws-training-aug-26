# Module 03 — CloudWatch to ADX

> **Reading order:** `03_CloudWatch_Primer.md` → Concepts (this file) → Lab → Exercises.

CloudWatch **Logs** reach ADX through subscription filter → Firehose → S3 → `.ingest`. ADX never calls the CloudWatch API.

You build one log group, one Firehose stream, and one bucket per student. Firehose writes an **envelope** object — ingest that envelope, not only the inner `message` string.

## How data moves

```mermaid
%%{init: {"theme":"base","flowchart":{"htmlLabels":true,"padding":12}}}%%
flowchart TB
  subgraph awsBox [AWS]
    PUT["put-log-events"]
    LG["Log group"]
    FH["Firehose"]
    S3[("S3")]
  end
  subgraph azureBox [Azure]
    CW[("CloudWatchLogs")]
  end
  PUT --> LG
  LG --> FH
  FH --> S3
  S3 -->|".ingest"| CW
  style awsBox fill:#FFF4E5,stroke:#FF9900,color:#232F3E
  style azureBox fill:#E6F2FB,stroke:#0078D4,color:#003A5D
  style PUT fill:#FF9900,stroke:#232F3E,color:#fff
  style LG fill:#EC7211,stroke:#232F3E,color:#fff
  style FH fill:#3B48CC,stroke:#1B2266,color:#fff
  style S3 fill:#232F3E,stroke:#FF9900,color:#fff
  style CW fill:#0078D4,stroke:#005A9E,color:#fff
```

Build order and Firehose toggles: **`03_CloudWatch_Primer.md`**.

**Real vs scripted log lines:** **`assets/REAL_VS_LAB_DATA.md`** (production apps vs `put_log_events.sh`).

## Envelope shape (mapping target)

```mermaid
%%{init: {"theme":"base","flowchart":{"htmlLabels":true,"padding":12}}}%%
flowchart TB
  subgraph s3file [S3 object]
    MT["messageType"]
    LG["logGroup"]
    LE["logEvents array"]
  end
  subgraph event [Each logEvents element]
    TS["timestamp"]
    MSG["message"]
    ID["id"]
  end
  LE --> event
  MSG -.->|"parse in KQL"| INNER["inner JSON text"]
  style s3file fill:#FFF4E5,stroke:#FF9900,color:#232F3E
  style event fill:#E6F2FB,stroke:#0078D4,color:#003A5D
  style MT fill:#FF9900,stroke:#232F3E,color:#fff
  style INNER fill:#E8E8E8,stroke:#666,color:#333
```

- Filter ingest/query to `messageType == "DATA_MESSAGE"`
- Mapping binds envelope fields; parse `message` in KQL if needed
- Leave table `CloudWatchLogs` for Module 04

## In class

- Database `ADXTrainingDB_<your-login>`; reader IAM on **your** Firehose bucket
- Git Bash: `export MSYS_NO_PATHCONV=1` before `aws logs`
