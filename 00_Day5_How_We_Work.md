# How we work on Day 5 (Module 05 — Logstash)

Same logins as Day 1 (`u01` … `u06`). Course folder is at `~/adx-aws-training` on **lab VS Code** — do **not** `git clone` again.

Today you use **two** machines:

| Where | Used for |
|-------|----------|
| **Lab VS Code** (card: `54.174.192.103`, port `8081`–`8086`) | `git pull`, KQL files, ADX Step 1, `aws ssm` for the Entra secret |
| **Shared Linux lab VM** (SSM or SSH command on your card) | Logstash, `/var/log/secure`, pipeline config, Steps 2–4 |

Logstash is **not** installed on the VS Code host. If `which logstash` returns nothing, you are still on VS Code — open the Linux lab VM shell first.

## Start here (VS Code terminal)

```bash
cd ~/adx-aws-training
git pull origin main
ls Module_05_Logstash assets/module_05
aws sts get-caller-identity
```

ARN must end with `user/u01` (or **your** login).

## Linux lab VM — quick check

Open a **second** terminal using the command on your access card. Then:

```bash
which logstash || ls /usr/share/logstash/bin/logstash
sudo tail -n 5 /var/log/secure 2>/dev/null || sudo tail -n 5 /var/log/auth.log
```

If Logstash is missing, the lab **Step 2** block installs it (Elastic yum repo). First student on a fresh VM runs that; others skip if the binary is already there.

Courseware on the lab VM is usually at `/opt/adx-aws-training/`. If that path is missing, ask the trainer.

## Names for Module 05 (example `u01`)

| What | Value |
|------|--------|
| ADX database | `ADXTrainingDB_u01` |
| ADX table | `LogstashHostLogs` |
| JSON mapping | `LogstashHostLogsMapping` |
| Entra app | `logstash-adx-ingestor` |
| App ID | `afed2047-fb94-41bd-bee5-e8c5b84fa1b8` |
| Tenant ID | `05f46730-30d9-47bc-b103-d316ee58a3f5` |
| Ingest URL | `https://ingest-adxtrainaug26.centralindia.kusto.windows.net` |
| Auth log | `/var/log/secure` (Amazon Linux) |
| Entra secret | SSM `/adx/lab/entra-secret` — never commit, never chat |

Use the **ingest** URL above, not the query URL (`https://adxtrainaug26…` without `ingest-`).

## Entra secret (runtime only)

```bash
aws ssm get-parameter --name /adx/lab/entra-secret --with-decryption \
  --query Parameter.Value --output text
```

Paste the value into `app_key` in `/tmp/logstash-lab/adx-pipeline.conf` on the **Linux lab VM** only.

## Turn-taking

The Linux lab VM is **shared**. One Logstash at a time.

1. Ask: "Is anyone running Logstash?"
2. Use your own `--path.data`, e.g. `/tmp/logstash-lab/data-u01`.
3. When you finish: `Ctrl+C`, then the next student starts.

## Module order

`05_Logstash_Primer.md` → Concepts → Lab → Exercises

## Day 5 traps

1. **Wrong host** — pipeline commands on VS Code will fail; use the Linux lab VM for Logstash.
2. **Fresh VM** — Logstash may not be installed yet; run lab Step 2A once per VM.
3. **Wrong URL** — query URL in the config → empty table with no obvious error.
4. **Wrong database** — `database =>` in the conf must match **your** `ADXTrainingDB_<login>`.
5. **Wait 2–5 minutes** after sudo/SSH activity before `LogstashHostLogs | count` looks wrong.
6. **Real auth log** — tail `/var/log/secure`; do not point the lab pipeline at a fake `/tmp` file.
7. **Do not commit** the client secret or paste it in chat.
8. **Sudo denied** — use Linux password at prompt; if not in sudoers, trainer runs `grant_sudo_lab_users.sh`.

## ADX

Portal → cluster **adxtrainaug26** → database **`ADXTrainingDB_<your-login>`**.

```kusto
print Database = current_database()
```

Must show your database before `create_tables.kql`.
