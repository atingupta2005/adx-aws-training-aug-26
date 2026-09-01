# Module 05 — Lab (Logstash → ADX from the cloud lab VM)

**Reading order:** `05_Logstash_Primer.md` → `05_Logstash_ADX_Integration_Concepts.md` → **this Lab** → `05_Exercises.md`.

**Database:** `ADXTrainingDB_<your-login>` (example: `ADXTrainingDB_u01`).

**KQL files:** `assets/module_05/`.

**VM:** Shared cloud isolated lab VM — coordinate turn-taking with the group before starting Logstash.

---

## 1. What this lab is about (plain English)

In Modules 01–04 you ingested AWS logs (batch, S3-based) and built a hybrid ADX table. Those methods work great when a file already exists in a bucket.

The host on which you work here is a **cloud isolated lab VM** — an Amazon Linux EC2 instance running in the same AWS environment as the rest of this training. It is not physically on-premises, but for this exercise it represents the host tier: an infrastructure component that writes to files like `/var/log/secure` in real time, exactly as a production server would.

**Module 05 connects that VM's live auth log directly into ADX:**

> `/var/log/secure` on the lab VM → Logstash → ADX table `LogstashHostLogs`

You do **not** batch-copy files to S3 first. Logstash tails the file continuously. You produce log lines by doing real OS activity (SSH, sudo, failed login). Those lines appear in `/var/log/secure` → Logstash parses them → events arrive in ADX within 2–5 minutes.

---

## 2. How data travels (source → destination)

```mermaid
%%{init: {"theme":"base","flowchart":{"htmlLabels":true,"padding":12}}}%%
flowchart TB
  subgraph vm [Cloud Isolated Lab VM — Amazon Linux]
    direction TB
    A1["Real OS activity<br/>SSH · sudo · failed login"]
    A2["/var/log/secure<br/>growing auth log file"]
    A1 -->|"writes lines"| A2
  end
  subgraph ls [Logstash on the same VM]
    direction TB
    B1["input { file }<br/>tail /var/log/secure"]
    B2["filter { grok · date }<br/>parse into fields"]
    B3["output { kusto }<br/>batch + queued ingest"]
    B1 --> B2 --> B3
  end
  subgraph adx [Azure Data Explorer]
    C1[("LogstashHostLogs<br/>LogTime · Hostname · Process · Pid · Message")]
  end
  A2 -->|"new lines"| B1
  B3 -->|"Entra app auth<br/>ingest-adxtrainaug26<br/>queued ingest 2–5 min"| C1
  style vm fill:#FFF4E5,stroke:#FF9900,color:#232F3E
  style ls fill:#E8F4FC,stroke:#07C,color:#003A5D
  style adx fill:#E6F2FB,stroke:#0078D4,color:#003A5D
  style A2 fill:#E95420,stroke:#772953,color:#fff
  style C1 fill:#107C10,stroke:#0B5A0B,color:#fff
```

**Key facts about this path:**

| Piece | Detail |
|-------|--------|
| Auth log | `/var/log/secure` (Amazon Linux) or `/var/log/auth.log` (Debian/Ubuntu) |
| Logstash binary | `/usr/share/logstash/bin/logstash` |
| Kusto plugin | `logstash-output-kusto` (install via plugin manager) |
| Entra app | `logstash-adx-ingestor` (App ID `afed2047-fb94-41bd-bee5-e8c5b84fa1b8`, Tenant `05f46730-30d9-47bc-b103-d316ee58a3f5`) |
| Ingest endpoint | `https://ingest-adxtrainaug26.centralindia.kusto.windows.net` |
| ADX table | `LogstashHostLogs` in `ADXTrainingDB_<your-login>` |
| Delay | Queued ingest: **2–5 minutes** after a line is written |

---

## 3. Turn-taking on the shared VM

The lab VM is **shared**. Before you start Logstash:

1. Ask the group: "Is anyone running Logstash right now?"
2. If yes, wait or coordinate so two instances do not use the same `--path.data` directory.
3. If the previous student left Logstash running: `sudo pkill -f logstash` (confirm with the instructor first).
4. Use a **unique** `--path.data` for your run, for example `/tmp/logstash-lab/data-u01` for login `u01`.

This prevents sincedb conflicts and ensures each student's Logstash reads from its own file-position state.

---

## 4. How to generate auth log data (do NOT invent a fake file)

Logstash tails `/var/log/secure`. That file fills when **real OS actions** happen:

| Action to take | What appears in `/var/log/secure` |
|----------------|-----------------------------------|
| `sudo true` or `sudo ls /root` | `sudo: <user> : TTY=pts/0 …` |
| `ssh baduser@127.0.0.1` (expect fail) | `Invalid user baduser` / `Connection closed` |
| Open a second SSH session to the VM | `Accepted publickey for <user>` |
| `su - otheruser` then exit | `su: …` authentication lines |
| `sudo -l` (list sudo perms) | `sudo: list` lines |

**Do not** create a fake log file under `/tmp` and point Logstash at it as the main pipeline. The purpose of this lab is a live tail of a real auth log: the log file grows because real things happen on the system, and Logstash picks them up.

Check that lines exist **before** starting Logstash:

```bash
sudo tail -n 10 /var/log/secure 2>/dev/null || sudo tail -n 10 /var/log/auth.log
```

You must see recent syslog-formatted lines. If the file is completely empty, run `sudo true` a few times to seed it.

---

## 5. Lab steps overview

```mermaid
%%{init: {"theme":"base","flowchart":{"htmlLabels":true,"padding":12}}}%%
flowchart TB
  A["Step 1 — ADX: table + mapping + Entra grant"] --> B["Step 2 — VM: install kusto plugin + check log file"]
  B --> C["Step 3 — VM: configure + start Logstash pipeline"]
  C --> D["Step 4 — VM: generate real auth activity"]
  D --> E["Step 5 — ADX: query LogstashHostLogs"]
  style A fill:#0078D4,stroke:#005A9E,color:#fff
  style B fill:#00BFB3,stroke:#005571,color:#fff
  style C fill:#E95420,stroke:#772953,color:#fff
  style D fill:#FF9900,stroke:#232F3E,color:#fff
  style E fill:#107C10,stroke:#0B5A0B,color:#fff
```

---

## Step 1 — ADX setup: table, mapping, and Entra grant

### Goal

Create `LogstashHostLogs` and its JSON ingestion mapping in **your** ADX database, then grant the Entra app `logstash-adx-ingestor` the Ingestor role on that database.

### Why this step comes first

The Logstash kusto plugin sends JSON blobs to ADX. ADX needs three things in place before any data can land:

1. A **table** with named columns (`LogTime`, `Hostname`, `Process`, `Pid`, `Message`).
2. A **JSON mapping** that tells ADX which JSON key maps to which column (e.g. `$.LogTime` → `LogTime`).
3. The **Entra app** listed as a Database Ingestor — without this, the plugin authenticates successfully but all ingest calls are rejected silently.

### What `create_tables.kql` does

| Command | Purpose |
|---------|---------|
| `.create table LogstashHostLogs (...)` | Defines 5 typed columns |
| `.create table LogstashHostLogs ingestion json mapping 'LogstashHostLogsMapping' [...]` | Maps `$.LogTime` → `LogTime`, `$.Hostname` → `Hostname`, etc. |
| `.add database [...] ingestors (...)` | Grants `logstash-adx-ingestor` the Ingestor role on your database |
| `.show database [...] principals` | Confirms the grant took effect |

### Do this exactly

1. In Azure Data Explorer Web UI, select database `ADXTrainingDB_<your-login>` from the dropdown.
2. Confirm you are in the right database:

```kusto
print Database = current_database()
```

3. Open `assets/module_05/create_tables.kql`.
4. Replace the two placeholders in the `.add database` line:
   - `[CLIENT_ID]` → `afed2047-fb94-41bd-bee5-e8c5b84fa1b8`
   - `[TENANT_ID]` → `05f46730-30d9-47bc-b103-d316ee58a3f5`
   - Database name → `ADXTrainingDB_<your-login>` (both occurrences)
5. Run the entire file.

### Checkpoint

```kusto
.show tables
| where TableName == "LogstashHostLogs"
```

```kusto
.show database ['ADXTrainingDB_<your-login>'] principals
| where PrincipalType == "App" and Role == "Ingestor"
```

You must see:
- `LogstashHostLogs` in the table list.
- At least one row in principals showing the Entra app (App ID starting with `afed2047`) as Ingestor.

### If something is wrong

| Symptom | Fix |
|---------|-----|
| `.show tables` does not list `LogstashHostLogs` | Re-run `create_tables.kql` from the correct database |
| Principals output is empty / app not listed | Re-run the `.add database` line after fixing `[CLIENT_ID]` and `[TENANT_ID]` placeholders |
| "Access denied" when running KQL | You are in the wrong database — fix the dropdown and re-confirm with `print Database` |
| Table already exists from a previous attempt | Check the mapping also exists; if the structure matches, continue |

---

## Step 2 — Plugin install and log file check

### Goal

Verify Logstash is installed, install the `logstash-output-kusto` plugin, confirm `/var/log/secure` is readable, and create the staging directories the plugin needs.

### Why a staging directory?

The kusto plugin v2.x does not stream events directly to ADX. It buffers parsed events into local text files in a staging path (e.g. `/tmp/kusto/`), then uploads each staging file as a batch. The staging `path` must include a **time token** (`%{+YYYY-MM-dd-HH-mm}`) so the plugin rotates files by minute. If you remove `@timestamp` from the event, the path token resolves to a literal string and file rotation breaks silently — nothing reaches ADX.

### Do this exactly

```bash
# Confirm Logstash binary
which logstash 2>/dev/null || ls /usr/share/logstash/bin/logstash

# Check the auth log is readable
sudo tail -n 10 /var/log/secure 2>/dev/null || sudo tail -n 10 /var/log/auth.log

# Install the kusto output plugin
cd /usr/share/logstash
sudo bin/logstash-plugin install logstash-output-kusto

# Verify it installed
bin/logstash-plugin list --verbose | grep kusto

# Create staging directories
sudo mkdir -p /tmp/kusto
sudo chmod 777 /tmp/kusto
mkdir -p /tmp/logstash-lab
```

### Checkpoint

- `which logstash` or the manual path returns a path (no error).
- `logstash-plugin list | grep kusto` shows the plugin name and a version number.
- `sudo tail` returns syslog-formatted lines (timestamp + hostname + process + message).
- `/tmp/kusto` and `/tmp/logstash-lab` exist.

### If something is wrong

| Symptom | Fix |
|---------|-----|
| `logstash` not found | Check `/usr/share/logstash/` manually; ask the instructor — it is pre-installed on the lab VM |
| Plugin install fails (timeout) | Check outbound internet from the VM; retry once; ask instructor if it persists |
| `/var/log/secure` permission denied | Use `sudo tail …` not plain `tail` |
| Auth log is completely empty | Run `sudo true` several times to seed it, then re-check |
| Plugin already installed | That is fine — verify it with `list | grep kusto` and continue |

---

## Step 3 — Pipeline configuration and start

### Goal

Copy the example pipeline config, fill in the five connection values, and start Logstash tailing `/var/log/secure`.

### What the pipeline config contains

| Section | Key setting | Your value |
|---------|------------|------------|
| `input { file }` | `path` | `/var/log/secure` (or `/var/log/auth.log` on Debian/Ubuntu) |
| `filter { grok }` | `ecs_compatibility => disabled` | Required — without this, Logstash 8 renames fields and ADX mapping fails |
| `filter { date }` | `target => "LogTime"` | Writes the parsed timestamp into the `LogTime` column |
| `output { kusto }` | `ingest_url` | `https://ingest-adxtrainaug26.centralindia.kusto.windows.net` |
| `output { kusto }` | `app_id` | `afed2047-fb94-41bd-bee5-e8c5b84fa1b8` |
| `output { kusto }` | `app_tenant` | `05f46730-30d9-47bc-b103-d316ee58a3f5` |
| `output { kusto }` | `app_key` | *(instructor provides the client secret)* |
| `output { kusto }` | `database` | `ADXTrainingDB_<your-login>` |
| `output { kusto }` | `path` | `/tmp/kusto/%{+YYYY-MM-dd-HH-mm}.txt` |

### Do this exactly

1. Copy the example to your working directory:

```bash
cp assets/module_05/adx-pipeline.conf.example /tmp/logstash-lab/adx-pipeline.conf
```

2. Edit the config:

```bash
nano /tmp/logstash-lab/adx-pipeline.conf
```

Fill in these five values:

```text
ingest_url => "https://ingest-adxtrainaug26.centralindia.kusto.windows.net"
app_id     => "afed2047-fb94-41bd-bee5-e8c5b84fa1b8"
app_key    => "<client-secret-from-instructor>"
app_tenant => "05f46730-30d9-47bc-b103-d316ee58a3f5"
database   => "ADXTrainingDB_<your-login>"
```

3. Validate the config syntax before starting:

```bash
cd /usr/share/logstash
sudo bin/logstash \
  --path.settings /etc/logstash \
  -f /tmp/logstash-lab/adx-pipeline.conf \
  --config.test_and_exit
```

You should see `Configuration OK`.

4. Start Logstash using a **unique** `--path.data` for your login:

```bash
sudo bin/logstash \
  --path.settings /etc/logstash \
  --path.data /tmp/logstash-lab/data-<your-login> \
  -f /tmp/logstash-lab/adx-pipeline.conf
```

5. Watch the startup messages for 30–60 seconds. You should see lines like:

```
[INFO ][logstash.inputs.file] Registering file input ...
[INFO ][logstash.outputs.kusto] ...
```

Leave Logstash running in this terminal. Open a **second terminal** for Step 4.

### Checkpoint

- Config validation returns `Configuration OK`.
- Logstash startup log does **not** show `ERROR` or `FATAL` in the first 30 seconds.
- After 30–60 seconds you see Logstash processing events (lines mentioning `kusto` in the output).

### If something is wrong

| Symptom | Fix |
|---------|-----|
| `Configuration OK` but Logstash exits immediately | Finished reading the file from `start_position => "beginning"` — set `sincedb_path => "/dev/null"` and restart, or generate new activity and it will tail again |
| `ERROR … field … not found` or fields showing as `%{fieldname}` | `ecs_compatibility` is not `disabled` — edit the conf and add it to the grok block |
| `ERROR … access denied` on `/tmp/kusto` | `sudo chmod 777 /tmp/kusto` then restart Logstash |
| `FATAL … address already in use` | Another Logstash is running — `sudo pkill -f logstash`, wait, retry |
| Logstash starts but ADX table stays empty after 5+ minutes | Check that ingest URL starts with `https://ingest-` not the query URL; also check Step 1 Entra grant |

---

## Step 4 — Generate real auth activity (while Logstash runs)

### Goal

Produce lines in `/var/log/secure` that Logstash will parse and send to ADX.

### Why real activity (not a fake file)

A fake `/tmp/fake.log` you edit by hand teaches nothing about production log collection. The whole point of this module is: **the log file grows because real things happen on the system**, and Logstash picks them up in real time. The actions below are exactly what you would take on a real production server to test your auth pipeline.

### Do this exactly

In a **second terminal** (Logstash running in the first):

```bash
# Seed a few sudo events
sudo true
sudo ls /root
sudo -l

# Trigger a failed SSH attempt (will fail — that is the point)
ssh baduser@127.0.0.1

# su attempt with wrong password
su - root
# enter a wrong password intentionally, then Ctrl+D to exit
```

Watch the auth log live in a third terminal or pane:

```bash
sudo tail -f /var/log/secure
```

You should see new timestamped lines appearing as you perform each action. Each line Logstash picks up will be visible in the Logstash terminal as an event being processed.

Leave Logstash running for **at least 2–3 minutes** after generating activity. Queued ingest has a latency of 2–5 minutes before events appear in ADX.

### Checkpoint

- `sudo tail -f /var/log/secure` shows new timestamped lines for your actions.
- Logstash terminal shows events being processed with no sustained errors.
- After 2–5 minutes, proceed to Step 5 to verify in ADX.

---

## Step 5 — Query `LogstashHostLogs`

### Goal

Confirm that events you caused on the VM now appear in your ADX table.

### Do this exactly

1. Run `assets/module_05/validate.kql` in `ADXTrainingDB_<your-login>`.
2. Run spot queries:

```kusto
LogstashHostLogs | count
```

```kusto
LogstashHostLogs
| order by LogTime desc
| take 20
```

```kusto
// Which processes logged events?
LogstashHostLogs
| summarize n = count() by Process
| order by n desc
```

```kusto
// Look for sudo and sshd specifically
LogstashHostLogs
| where Process in ("sudo", "sshd", "su")
| order by LogTime desc
| take 30
```

3. Then run `assets/module_05/explore.kql` and continue to `05_Exercises.md`.

### You are done when

- `LogstashHostLogs | count` is greater than 0.
- At least some rows have `Process` values matching things you actually did (e.g. `sudo`, `sshd`).
- You can explain the journey: OS action → `/var/log/secure` → Logstash grok/date → kusto plugin queued ingest → ADX.
- You understand the 2–5 minute queued ingest delay is normal, not a bug.

---

## Continue — in-depth Logstash sessions

After the core lab, work through **`Logstash_In_Depth/`** (five practical sessions: grok deep dive, stdout debugging, extra filters, web log shape, operations). Start at `Logstash_In_Depth/README.md`.

---

## Quick failure guide

| Problem | Likely cause | Fix |
|---------|--------------|-----|
| `LogstashHostLogs` does not exist | Step 1 not run | Run `create_tables.kql` in the correct database |
| Table exists but count stays 0 after 5+ min | Entra grant missing OR wrong ingest URL | Check principals; confirm URL starts with `https://ingest-` |
| Count stays 0 with correct URL + grant | ECS compatibility on → field names differ from mapping | Add `ecs_compatibility => disabled` inside the `grok { }` block |
| Count stays 0, everything else looks correct | `@timestamp` removed → staging path broken | Remove `@timestamp` from the `remove_field` list |
| Logstash exits immediately after start | sincedb reached end of file with no new lines | Generate auth activity, or set `sincedb_path => "/dev/null"` and restart |
| Two students' events mixing | Shared `--path.data` directory | Use unique path per login: `/tmp/logstash-lab/data-<your-login>` |
| ADX shows rows but `Pid` is always 0 | Process had no `[pid]` bracket — mutate default sets 0 | Expected behavior — not a bug |
| Wrong database in ADX | Dropdown not set correctly | `print Database = current_database()` and fix |
