# Module 08 — GuardDuty primer

Read this **before** `08_GuardDuty_to_ADX_Concepts.md`.

## What GuardDuty is (plain English)

**Amazon GuardDuty** is a **threat detection** service. It continuously analyses your AWS environment's data sources — CloudTrail, VPC Flow Logs, DNS logs — and produces **findings**: structured JSON documents that describe a detected security issue.

A GuardDuty finding is not a raw log line you tail. It is a rich JSON object with a type, severity score, affected resources, timestamps, and a description of why the activity is suspicious.

```mermaid
%%{init: {"theme":"base","flowchart":{"htmlLabels":true,"padding":12}}}%%
flowchart TB
  subgraph inputs [GuardDuty data sources]
    CT["CloudTrail\n(API calls)"]
    VPC["VPC Flow Logs\n(network traffic)"]
    DNS["DNS logs\n(query patterns)"]
  end
  GD["GuardDuty detector"]
  FIND["Finding\n{type, severity, resource, …}"]
  inputs --> GD
  GD --> FIND
  style inputs fill:#FFF4E5,stroke:#FF9900,color:#232F3E
  style GD fill:#DD344C,stroke:#8B1E2D,color:#fff
  style FIND fill:#F25022,stroke:#8B1A00,color:#fff
```

---

## Finding vs log line

| | CloudTrail event (M02) | GuardDuty finding (M08) |
|---|---|---|
| **Shape** | One API call | One detected security pattern |
| **Format** | JSON — one action | JSON — aggregated signals |
| **Severity** | Not scored | Numerical (0–10 scale) |
| **Volume** | One row per API call | One row per distinct threat type |
| **Purpose** | Audit trail | Security alert |

You do not "turn on" CloudTrail to get GuardDuty findings. GuardDuty reads CloudTrail internally. The finding that emerges is a higher-level object — not a raw log line.

---

## Classroom export path

You do **not** create or manage the GuardDuty detector, the EventBridge rule, the Firehose delivery stream, or the landing S3 bucket. The trainer has provisioned all of that. Your role is:

1. Trigger findings (using the AWS **Generate sample findings** button).
2. Wait for them to reach S3 via the already-running Firehose.
3. Create an IAM reader, create your ADX table, and ingest.

```mermaid
%%{init: {"theme":"base","flowchart":{"htmlLabels":true,"padding":12}}}%%
flowchart LR
  GD["GuardDuty\ndetector"]
  EB["EventBridge rule\n'GuardDuty Finding'"]
  FH["Kinesis Firehose\nguardduty-to-adx-stream"]
  S3[("s3://adx-classroom-\nguardduty-export")]
  ADX["GuardDutyFindings\nADX table"]
  GD --> EB --> FH --> S3 -->|".ingest"| ADX
  style GD fill:#DD344C,stroke:#8B1E2D,color:#fff
  style EB fill:#FF9900,stroke:#232F3E,color:#fff
  style FH fill:#3B48CC,stroke:#1B2266,color:#fff
  style S3 fill:#232F3E,stroke:#FF9900,color:#fff
  style ADX fill:#0078D4,stroke:#005A9E,color:#fff
```

Same buffering idea as Module 03 (CloudWatch Firehose): after you trigger findings, **wait 60–90 seconds** for Firehose to flush its buffer and write an S3 object.

---

## The EventBridge envelope

S3 objects do not contain the raw GuardDuty finding JSON directly. They contain **EventBridge event envelopes** — one JSON document per line (NDJSON / multijson). The finding fields live one level deeper, inside the `detail` key.

```mermaid
%%{init: {"theme":"base","flowchart":{"htmlLabels":true,"padding":12}}}%%
flowchart TB
  ENV["S3 object line\n{ version, id, source, time, account, region, detail }"]
  DET["detail object\n{ id, type, severity, title, description, resource }"]
  F["ADX columns:\nFindingId, FindingType, Severity, Title, Description, ResourceData"]
  ENV --> DET --> F
  style ENV fill:#FFF4E5,stroke:#FF9900,color:#232F3E
  style DET fill:#DD344C,stroke:#8B1E2D,color:#fff
  style F fill:#107C10,stroke:#0B5A0B,color:#fff
```

Critical mapping rules:

| JSON path in envelope | ADX column | Common mistake |
|---|---|---|
| `$.time` | `EventTime` | — |
| `$.account` | `AccountId` | — |
| `$.region` | `Region` | — |
| `$.detail.id` | `FindingId` | **Not** `$.id` (that is the envelope event ID, not the finding ID) |
| `$.detail.type` | `FindingType` | — |
| `$.detail.severity` | `Severity` | — |
| `$.detail.title` | `Title` | — |
| `$.detail.description` | `Description` | — |
| `$.detail.resource` | `ResourceData` | — |

If you map `$.id` instead of `$.detail.id`, ingest succeeds but `FindingId` is empty for every row.

---

## Generate sample findings — what this does

GuardDuty has a built-in **Generate sample findings** button (Settings → Generate sample findings in the console). This tells the GuardDuty service to emit one sample finding for every supported finding type. These are real GuardDuty objects — they flow through EventBridge, Firehose, and S3 exactly as production findings would. The only difference is they are labeled as `[SAMPLE]` in their titles.

This is an AWS product feature, not a custom shell script that writes fake JSON. Ingest scripts in this lab only **list the S3 bucket** and **load into ADX** — they do not write finding data.

---

## Hands-on orientation (console — before starting lab steps)

1. Open **GuardDuty** in the AWS console → **Summary** — confirm the detector is enabled.
2. Click **Findings** — note the `Type`, `Severity`, and `Resource` columns.
3. Click **Settings** — locate the **Generate sample findings** button (you will use it in Step 1).
4. Open **S3** → `adx-classroom-guardduty-export` → browse the `guardduty/` prefix.

**Checkpoint:** You can explain the difference between a GuardDuty finding and a raw CloudTrail API event.

---

## Common mistakes

| Mistake | Result |
|---------|--------|
| Map `$.id` instead of `$.detail.id` | Ingest succeeds; `FindingId` is empty for all rows |
| Create IAM reader on the Module 01 inventory bucket | Wrong permissions; ingest fails with Access Denied |
| Query ADX immediately after Generate sample findings | Empty table — Firehose needs 60–90 s to flush |
| Expect live threat findings in a short lab session | Sample findings are the reliable classroom source; live threats may or may not appear |
| Create or delete the GuardDuty detector | Do not — trainer owns it; toggling disrupts the whole class |
