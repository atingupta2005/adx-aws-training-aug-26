# Module 04 — Hybrid analytics primer

Read this **before** `04_Hybrid_Log_Ingestion_Concepts.md`.

## The problem

CloudTrail and CloudWatch store **different shapes**. A single flat ingest mapping cannot represent both without breaking when either source changes.

```mermaid
%%{init: {"theme":"base","flowchart":{"htmlLabels":true,"padding":12}}}%%
flowchart TB
  CT["CloudTrailEvents<br/>eventTime, eventName, userIdentity"]
  CW["CloudWatchLogs<br/>logEvents, messageType"]
  BAD["One wide table<br/>many null columns"]
  CT --> BAD
  CW --> BAD
  style CT fill:#EC7211,stroke:#232F3E,color:#fff
  style CW fill:#3B48CC,stroke:#1B2266,color:#fff
  style BAD fill:#D13212,stroke:#8B1A00,color:#fff
```

## The pattern (keep raw + unify)

1. Keep **source-shaped** raw tables (`RawAWSLogs`, `RawOnPremLogs`).
2. Project a **small shared schema** into `UnifiedHybridLogs`.
3. Use ADX **update policies** to append on each raw insert.

```mermaid
%%{init: {"theme":"base","flowchart":{"htmlLabels":true,"padding":12}}}%%
flowchart LR
  RAW_A["RawAWSLogs"]
  RAW_O["RawOnPremLogs"]
  UNI[("UnifiedHybridLogs")]
  RAW_A -->|"update policy"| UNI
  RAW_O -->|"update policy"| UNI
  style RAW_A fill:#FF9900,stroke:#232F3E,color:#fff
  style RAW_O fill:#5C2D91,stroke:#3A1D5C,color:#fff
  style UNI fill:#0078D4,stroke:#005A9E,color:#fff
```

## Unified columns

| Column | Example AWS | Example on-prem |
|--------|-------------|-----------------|
| `LogTime` | CloudTrail `EventTime` | Simulated syslog time |
| `Environment` | `AWS` | `On-Premises` |
| `SourceService` | `eventSource` | `firewall` / `app-server` |
| `LogLevel` | derived from `ErrorCode` | `ERROR` / `INFO` |
| `Message` | `EventName` + context | free text |

## On-prem in this lab

There is **no VPN or syslog shipper** in the classroom. On-prem rows come from a **`datatable`** — a stand-in so you can query one timeline. In production, the same raw table might be fed by Logstash, Event Hub, or batch files.

## Policy order (critical)

```mermaid
%%{init: {"theme":"base","flowchart":{"htmlLabels":true,"padding":12}}}%%
flowchart TD
  P["1 Create policy FIRST"]
  L["2 Load raw tables"]
  U["3 UnifiedHybridLogs fills automatically"]
  P --> L --> U
  style P fill:#D13212,stroke:#8B1A00,color:#fff
  style L fill:#FF9900,stroke:#232F3E,color:#fff
  style U fill:#107C10,stroke:#0B5A0B,color:#fff
```

If you load raw data **before** the policy exists, those rows never project to unified — load again after fixing.

## Prerequisites

You need rows in **`CloudTrailEvents`** (Module 02) or **`CloudWatchLogs`** (Module 03). If both are empty, complete an earlier module first.
