# Module 03 — CloudWatch to ADX

> **Reading order:** `03_CloudWatch_Primer.md` → Concepts (this file) → Lab → Exercises.

CloudWatch **Logs** reach ADX through subscription filter → Firehose → S3 → `.ingest`. ADX never calls the CloudWatch API.

**Rule:** In real projects, CloudWatch fills because **applications and AWS services run**. Lab Step 3 uses a **checkout API you call with curl** or a **Lambda you invoke** — not a batch script whose only purpose is to invent log lines.

## How data moves

```mermaid
%%{init: {"theme":"base","flowchart":{"htmlLabels":true,"padding":12}}}%%
flowchart TB
  subgraph awsBox [AWS]
    SRC["Checkout API / Lambda<br/>real requests"]
    LG["Log group"]
    FH["Firehose"]
    S3[("S3")]
  end
  subgraph azureBox [Azure]
    CW[("CloudWatchLogs")]
  end
  SRC --> LG
  LG --> FH
  FH --> S3
  S3 -->|".ingest"| CW
  style awsBox fill:#FFF4E5,stroke:#FF9900,color:#232F3E
  style azureBox fill:#E6F2FB,stroke:#0078D4,color:#003A5D
  style SRC fill:#3B48CC,stroke:#1B2266,color:#fff
  style LG fill:#EC7211,stroke:#232F3E,color:#fff
  style FH fill:#3B48CC,stroke:#1B2266,color:#fff
  style S3 fill:#232F3E,stroke:#FF9900,color:#fff
  style CW fill:#0078D4,stroke:#005A9E,color:#fff
```

Build order: **`03_CloudWatch_Primer.md`**. Produce data: **Lab Step 3 Path A or B**.

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
  end
  LE --> event
  MSG -.->|"parse in KQL"| INNER["inner JSON<br/>level / event / orderId"]
  style s3file fill:#FFF4E5,stroke:#FF9900,color:#232F3E
  style event fill:#E6F2FB,stroke:#0078D4,color:#003A5D
  style MT fill:#FF9900,stroke:#232F3E,color:#fff
  style INNER fill:#107C10,stroke:#0B5A0B,color:#fff
```

- Filter to `messageType == "DATA_MESSAGE"`
- Parse `message` in KQL for app fields
- Leave `CloudWatchLogs` for Module 04

## In class

- Database `ADXTrainingDB_<your-login>`; reader on **your** Firehose bucket
- Git Bash: `export MSYS_NO_PATHCONV=1` before `aws logs`
- After Step 1: **start API + curl** or **invoke Lambda**, confirm CloudWatch, wait for Firehose, ingest
