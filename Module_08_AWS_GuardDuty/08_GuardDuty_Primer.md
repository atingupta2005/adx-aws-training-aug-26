# Module 08 — GuardDuty primer

Read this **before** `08_GuardDuty_to_ADX_Concepts.md`.

## What GuardDuty is (plain English)

**Amazon GuardDuty** is a **threat detection** service. It continuously analyses your AWS environment’s data sources — CloudTrail, VPC Flow Logs, DNS logs — and produces **findings**: structured JSON documents that describe a detected security issue.

A GuardDuty finding is not a raw log line you tail. It is a rich JSON object with a type, severity score, affected resources, timestamps, and a description of why the activity looks suspicious.

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

You do not “turn on” CloudTrail just to get GuardDuty findings. GuardDuty reads CloudTrail (and other sources) internally. The finding that emerges is a **higher-level** object — not a copy of a single API call.

---

## What is Amazon EventBridge?

**EventBridge** is AWS’s **event bus / router**.

1. Services publish **events** onto a bus (here: the account’s default bus).  
2. You define a **rule** with an **event pattern** (filters).  
3. Matching events are delivered to one or more **targets** (Firehose, Lambda, SQS, …).

In this module:

| Piece | Role |
|-------|------|
| **Event** | A GuardDuty finding becomes an EventBridge event (`source = aws.guardduty`, `detail-type = GuardDuty Finding`) |
| **Rule** | Matches those events |
| **Target** | A **Kinesis Data Firehose** delivery stream |
| **Why EventBridge?** | GuardDuty does not write findings into your lab S3 bucket by itself. EventBridge connects “finding created” → “send a copy to Firehose” |

```mermaid
%%{init: {"theme":"base","flowchart":{"htmlLabels":true,"padding":12}}}%%
flowchart LR
  GD["GuardDuty\npublishes finding"]
  BUS["EventBridge\ndefault event bus"]
  RULE["Rule\nmatch source +\ndetail-type"]
  FH["Firehose\nbuffer + write"]
  S3[("S3 bucket")]
  GD --> BUS --> RULE --> FH --> S3
  style GD fill:#DD344C,stroke:#8B1E2D,color:#fff
  style BUS fill:#FF9900,stroke:#232F3E,color:#fff
  style RULE fill:#FFB900,stroke:#232F3E,color:#000
  style FH fill:#3B48CC,stroke:#1B2266,color:#fff
  style S3 fill:#232F3E,stroke:#FF9900,color:#fff
```

**Contrast with Module 03:** CloudWatch Logs used a **subscription filter** straight into Firehose. GuardDuty has no subscription filter — **EventBridge** is the equivalent “when this happens, send there” glue.

---

## The export path into ADX

```text
GuardDuty → EventBridge → Firehose → s3://adx-classroom-guardduty-export/guardduty/ → ADX .ingest → GuardDutyFindings
```

```mermaid
%%{init: {"theme":"base","flowchart":{"htmlLabels":true,"padding":12}}}%%
flowchart LR
  GD["GuardDuty"]
  EB["EventBridge"]
  FH["Firehose"]
  S3[("adx-classroom-\nguardduty-export")]
  ADX["GuardDutyFindings"]
  GD --> EB --> FH --> S3 -->|".ingest"| ADX
  style GD fill:#DD344C,stroke:#8B1E2D,color:#fff
  style EB fill:#FF9900,stroke:#232F3E,color:#fff
  style FH fill:#3B48CC,stroke:#1B2266,color:#fff
  style S3 fill:#232F3E,stroke:#FF9900,color:#fff
  style ADX fill:#0078D4,stroke:#005A9E,color:#fff
```

**Firehose buffering:** Firehose holds events until a size or time limit is reached, then writes an S3 object. In this class, plan on **60–90 seconds** after **Generate sample findings** before you expect a new object in S3. Same idea as Module 03.

---

## The EventBridge envelope

S3 objects are **not** bare GuardDuty finding JSON. They contain **EventBridge event envelopes**. Finding fields live one level deeper, inside **`detail`**.

```mermaid
%%{init: {"theme":"base","flowchart":{"htmlLabels":true,"padding":12}}}%%
flowchart TB
  ENV["S3 object\n{ version, id, source, time, account, region, detail }"]
  DET["detail object\n{ id, type, severity, title, description, resource }"]
  F["ADX columns\nFindingId, FindingType, Severity, …"]
  ENV --> DET --> F
  style ENV fill:#FFF4E5,stroke:#FF9900,color:#232F3E
  style DET fill:#DD344C,stroke:#8B1E2D,color:#fff
  style F fill:#107C10,stroke:#0B5A0B,color:#fff
```

| JSON path | ADX column | Common mistake |
|-----------|------------|----------------|
| `$.time` | `EventTime` | — |
| `$.account` | `AccountId` | — |
| `$.region` | `Region` | — |
| `$.detail.id` | `FindingId` | **Not** `$.id` (that is the envelope event ID) |
| `$.detail.type` | `FindingType` | — |
| `$.detail.severity` | `Severity` | — |
| `$.detail.title` | `Title` | — |
| `$.detail.description` | `Description` | — |
| `$.detail.resource` | `ResourceData` | — |

If you map `$.id` instead of `$.detail.id`, ingest can succeed but `FindingId` is empty for every row — a silent mistake.

See also: `assets/module_08/sample_eventbridge_envelope.json` (shape study).

---

## Generate sample findings

GuardDuty → **Settings** → **Generate sample findings** tells the service to emit one sample for many supported finding types. Samples travel the **same** EventBridge → Firehose → S3 path as live findings. Titles are often prefixed with `[SAMPLE]`.

This is an AWS product feature — not a custom script that writes fake JSON into S3.

---

## Hands-on orientation (console — before lab steps)

1. Open **GuardDuty** (`us-east-1`) → **Summary** / **Findings** — note Type, Severity, Resource.  
2. Open **Settings** — locate **Generate sample findings**.  
3. Open **S3** → `adx-classroom-guardduty-export` → browse `guardduty/`.

**Checkpoint:** You can explain the difference between a GuardDuty finding and a CloudTrail API event, and why ADX mappings use `$.detail.*`.

---

## Common mistakes

| Mistake | Result |
|---------|--------|
| Map `$.id` instead of `$.detail.id` | Ingest succeeds; `FindingId` empty |
| Query ADX immediately after Generate sample findings | Empty table — wait for Firehose (60–90 s) then ingest |
| Expect live threats in a short lab | Sample findings are the reliable classroom source |
| Confuse Module 01 / M03 buckets with this one | Wrong objects / Access Denied — use `adx-classroom-guardduty-export` |
