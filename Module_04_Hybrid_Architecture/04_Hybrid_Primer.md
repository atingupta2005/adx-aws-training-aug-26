# Module 04 — Hybrid analytics primer

Read this **before** `04_Hybrid_Log_Ingestion_Concepts.md`.

## The problem (plain English)

You already have AWS logs in ADX from earlier modules. Those logs do not all look alike:

- **CloudTrail** rows describe API calls (who called what, when).
- **CloudWatch** rows describe application / service log messages.

If your company also has **on-premises** systems, those logs look different again.

If you try to stuff every field from every source into **one wide table**, you get many empty columns and a schema that breaks whenever one source adds a field.

```mermaid
%%{init: {"theme":"base","flowchart":{"htmlLabels":true,"padding":12}}}%%
flowchart TB
  CT["CloudTrailEvents<br/>eventTime, eventName, userIdentity"]
  CW["CloudWatchLogs<br/>logEvents, messageType"]
  BAD["One wide table<br/>many null columns — hard to maintain"]
  CT --> BAD
  CW --> BAD
  style CT fill:#EC7211,stroke:#232F3E,color:#fff
  style CW fill:#3B48CC,stroke:#1B2266,color:#fff
  style BAD fill:#D13212,stroke:#8B1A00,color:#fff
```

---

## The pattern (keep raw + unify)

Think of two layers:

### Layer 1 — Raw tables (keep the original shape)

- `RawAWSLogs` stores AWS-side rows in an AWS-friendly shape.
- `RawOnPremLogs` stores on-prem-side rows in an on-prem-friendly shape.

You keep these so you can still investigate source-specific details later.

### Layer 2 — Unified table (shared analytics shape)

- `UnifiedHybridLogs` stores only a **small shared schema** (five columns) so one KQL query can compare AWS and on-prem on one timeline.

### The glue — update policies

An ADX **update policy** means:

> When a new row is inserted into a raw table, ADX automatically runs a normalize function and appends the simplified row into `UnifiedHybridLogs`.

You usually do **not** insert into `UnifiedHybridLogs` by hand for the main path.

```mermaid
%%{init: {"theme":"base","flowchart":{"htmlLabels":true,"padding":12}}}%%
flowchart LR
  RAW_A["RawAWSLogs<br/>keep AWS shape"]
  RAW_O["RawOnPremLogs<br/>keep on-prem shape"]
  UNI[("UnifiedHybridLogs<br/>five shared columns")]
  RAW_A -->|"update policy"| UNI
  RAW_O -->|"update policy"| UNI
  style RAW_A fill:#FF9900,stroke:#232F3E,color:#fff
  style RAW_O fill:#5C2D91,stroke:#3A1D5C,color:#fff
  style UNI fill:#0078D4,stroke:#005A9E,color:#fff
```

---

## The five shared columns

| Column | Question it answers | Example AWS | Example on-prem |
|--------|---------------------|-------------|-----------------|
| `LogTime` | When did it happen? | CloudTrail `EventTime` | Simulated syslog time |
| `Environment` | Which world? | `AWS` | `On-Premises` |
| `SourceService` | Which system? | `eventSource` / log group | `firewall` / `app-server` |
| `LogLevel` | How serious? | derived from errors / info | `ERROR` / `INFO` |
| `Message` | What happened, briefly? | event name + context | free text |

“**Project**” means: calculate or copy these five fields from the richer raw row.

---

## On-prem in this lab

There is **no VPN**, **no ExpressRoute**, and **no live syslog shipper** in the classroom for Module 04.

On-prem rows come from a small **`datatable`** insert (`load_onprem.kql`). That is only a stand-in so you can:

1. See a second `Environment` value (`On-Premises`).
2. Prove the normalize function + update policy work for more than one source.

In production, the same raw table might be fed by Logstash, Filebeat, Event Hub, or batch files (you build agent paths in Modules 05–06).

---

## Policy order (critical)

Update policies run on **new** inserts after the policy is attached. They do not magically rewrite history.

```mermaid
%%{init: {"theme":"base","flowchart":{"htmlLabels":true,"padding":12}}}%%
flowchart TD
  P["1. Create tables, functions, and update policy FIRST"]
  L["2. Load raw tables"]
  U["3. UnifiedHybridLogs fills automatically"]
  P --> L --> U
  style P fill:#D13212,stroke:#8B1A00,color:#fff
  style L fill:#FF9900,stroke:#232F3E,color:#fff
  style U fill:#107C10,stroke:#0B5A0B,color:#fff
```

If you load raw data **before** the policy exists, those rows never appear in unified until you load again **after** the policy is in place.

---

## Prerequisites

You need rows in **`CloudTrailEvents`** (Module 02) or **`CloudWatchLogs`** (Module 03) from real earlier activity. If both are empty, complete an earlier module first.
