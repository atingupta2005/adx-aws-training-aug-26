# Module 05 — Logstash to ADX: Concepts

> **Reading order:** `05_Logstash_Primer.md` → Concepts (this file) → Lab → Exercises.

## What this module is trying to solve

Modules 01–03 used **batch pull from S3**: a file already exists in a bucket, you run `.ingest`, and ADX downloads it. That works perfectly for CloudTrail and CloudWatch Firehose files.

Host logs are fundamentally different. `/var/log/secure` on the lab VM **grows continuously** as users SSH in, run sudo, trigger failed logins. There is no S3 hop. You need:

1. A process that **tails** the file as it grows.
2. A **parser** that splits the raw syslog text into named fields.
3. A way to **authenticate to ADX and write** those parsed events without copying to S3 first.

**Logstash** covers all three. This module wires Logstash directly from the cloud isolated lab VM into your personal ADX database.

---

## The lab VM in context

The lab VM is a cloud isolated Amazon Linux EC2 instance. It represents the **host tier** of the pipeline:

```
Modules 01–03   S3 bucket  ─────────────────────────────▶ ADX  (batch)
Modules 05–07   Lab VM  ──► Logstash / Beats ───────────▶ ADX  (streaming)
```

The VM is cloud-hosted, not physically on-premises. From a pipeline architecture standpoint it behaves exactly like a production server: it writes to `/var/log/secure`, `/var/log/nginx/access.log`, and similar files in real time. The pipeline you build here is the same pattern you would deploy on real on-premises or edge infrastructure.

---

## Plain-English pipeline: input → filter → output

Every Logstash pipeline has three stages:

| Stage | Plain meaning | In this lab |
|-------|---------------|-------------|
| **Input** | Where lines come from | Live auth log: `/var/log/secure` (Amazon Linux lab VM) |
| **Filter** | How to split one line into named fields | `grok` extracts `Hostname`, `Process`, `Pid`, `Message`; `date` sets `LogTime` |
| **Output** | Where parsed events go | `logstash-output-kusto` uses the Entra app to queued-ingest into `LogstashHostLogs` |

**Example line in `/var/log/secure`:**

```
Aug 31 09:14:23 ip-10-0-1-42 sudo: student : TTY=pts/0 ; PWD=/home/student ; USER=root ; COMMAND=/usr/bin/ls /root
```

After `grok` + `date`:

| Field | Value |
|-------|-------|
| `LogTime` | `2026-08-31T09:14:23.000Z` |
| `Hostname` | `ip-10-0-1-42` |
| `Process` | `sudo` |
| `Pid` | `0` (no pid bracket in this line — see below) |
| `Message` | `student : TTY=pts/0 ; PWD=/home/student ; USER=root ; COMMAND=/usr/bin/ls /root` |

These five fields land as one row in `LogstashHostLogs`.

---

## Auth and URLs — two endpoints that look alike

ADX has **two** hostnames for the same cluster. Using the wrong one causes silent failures:

| Endpoint | Format | Used for |
|----------|--------|----------|
| **Query** | `https://adxtrainaug26.centralindia.kusto.windows.net` | ADX Web UI, KQL queries |
| **Ingest** | `https://ingest-adxtrainaug26.centralindia.kusto.windows.net` | Logstash kusto plugin, data management |

The kusto plugin needs the **ingest** URL. If you put the query URL, the plugin authenticates successfully but every ingest call is rejected — and the table stays empty with no obvious error. This is the single most common mistake in this module.

### Entra app credentials (non-secret identifiers)

The Entra app `logstash-adx-ingestor` has two public identifiers that go in the pipeline config:

| Field | Value |
|-------|-------|
| `app_id` | `afed2047-fb94-41bd-bee5-e8c5b84fa1b8` |
| `app_tenant` | `05f46730-30d9-47bc-b103-d316ee58a3f5` |

The `app_key` (client secret) is sensitive and is provided by the instructor at lab time. Do not commit it to a file in the repo.

The Entra app must be granted **Database Ingestor** on **your** `ADXTrainingDB_<login>`. A cluster-level grant is not sufficient — it must be at the database level so each student's data lands only in their own database.

---

## Logstash 8 traps that look like "ADX is empty"

These three issues each produce a healthy-looking Logstash process with an empty ADX table:

### Trap 1: ECS compatibility not disabled

Logstash 8 enables Elastic Common Schema (ECS) v8 by default. ECS renames fields produced by grok patterns:

- Your grok pattern says `Hostname` → ECS renames it to `[host][name]`
- Your grok pattern says `message` → ECS restructures it

Your ADX JSON mapping expects `$.Hostname` at the event root. With ECS on, that key does not exist in the JSON. ADX mapping fails silently for those columns; rows arrive with nulls or are dropped entirely.

**Fix:** Add `ecs_compatibility => disabled` inside every `grok { }` block in your pipeline config.

### Trap 2: `@timestamp` removed from the event

The kusto plugin v2.x generates the staging file path from `@timestamp`:

```
path => "/tmp/kusto/%{+YYYY-MM-dd-HH-mm}.txt"
```

If you include `@timestamp` in a `mutate { remove_field => [...] }`, the path token resolves to a literal `%{+YYYY-MM-dd-HH-mm}` string. The plugin cannot write the staging file, so nothing reaches ADX.

**Fix:** Never include `@timestamp` in `remove_field`. The column is not written to `LogstashHostLogs` anyway (the JSON mapping does not map it to a table column).

### Trap 3: Checking ADX before ingest completes

Queued ingest is **not real-time**. ADX receives the uploaded staging file, queues it for internal processing, and makes it queryable typically within **2–5 minutes**. During that window `LogstashHostLogs | count` returns 0 even though data is on its way.

**Fix:** Generate activity, wait at least 3 minutes, then query.

---

## Turn-taking and sincedb

`sincedb` is Logstash's file-position tracker. It records how far into a file Logstash has read. If two students share the same `--path.data` directory:

1. Student A runs Logstash, reads to line 500. Sincedb records position 500.
2. Student A stops. Student B starts Logstash with the same `--path.data`.
3. Logstash resumes at line 500, skipping all of Student B's auth events that appeared before line 500.

**Fix:** Each student uses a unique `--path.data`, for example `/tmp/logstash-lab/data-u01` for login `u01`.

The lab pipeline config sets `sincedb_path => "/dev/null"` to disable persistence for the classroom session. This means Logstash re-reads from the beginning of the file on every restart. That is intentional for the lab — it may replay older events, but it guarantees your new events are always captured.

---

## Why the Pid column is sometimes 0

Not every syslog line includes a `[pid]` in brackets. The grok pattern captures it optionally:

```
%{DATA:Process}(?:\[%{POSINT:Pid}\])?:
```

If no pid bracket is present, Logstash sets `Pid = "0"` via a mutate default and converts to integer. You will see `sudo` lines often carry a pid, while some `su` or login lines do not. A Pid of 0 in ADX is expected — it is not a pipeline error.

---

## How this connects back to Module 04

Module 04 built `UnifiedHybridLogs` with an `On-Premises` environment value. The rows you are producing now in `LogstashHostLogs` (from the lab VM's `/var/log/secure`) represent the kind of real host data that Module 04 was anticipating. After Module 05, you could project `LogstashHostLogs` rows through the same normalize function pattern to feed real host events into the hybrid unified table.

Module 05 teaches the **collection path** (Logstash → ADX). Module 04 taught the **unification shape** (raw tables + update policy). Together they form the full picture.
