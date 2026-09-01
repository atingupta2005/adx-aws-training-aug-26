# How we work on Day 5 (Module 05 — Logstash)

Same logins as Day 1 (`u01` … `u06`). Same **lab VS Code** host as Days 1–4 — port `8081`–`8086` on `54.174.192.103`. Course folder: `~/adx-aws-training`.

Module 05 runs **on this host** (Logstash is already installed under `/usr/share/logstash`). You do **not** open a second VM for Logstash unless the trainer says otherwise.

## Start here

```bash
cd ~/adx-aws-training
git pull origin main
ls Module_05_Logstash assets/module_05
aws sts get-caller-identity
```

ARN must end with `user/u01` (or **your** login).

## Before Logstash — quick checks

```bash
# Logstash binary (use full path if which fails)
ls /usr/share/logstash/bin/logstash

# Auth log — Amazon Linux uses /var/log/secure
ls -l /var/log/secure
sudo tail -n 5 /var/log/secure
```

If `/var/log/secure` is **missing**, tell the trainer — they run `prepare_logstash_vscode_host.sh` once to enable `rsyslog`. Do not continue Step 2 until the file exists.

When `sudo` prompts, use your **Linux / IDE password** from the access card.

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
| Auth log | `/var/log/secure` |
| Entra secret | SSM `/adx/lab/entra-secret` — never commit, never chat |

Use the **ingest** URL, not the query URL (`https://adxtrainaug26…` without `ingest-`).

## Entra secret

```bash
aws ssm get-parameter --name /adx/lab/entra-secret --with-decryption \
  --query Parameter.Value --output text
```

Paste into `app_key` in `/tmp/logstash-lab/adx-pipeline.conf` only.

## Turn-taking

The VS Code host is **shared**. One Logstash at a time.

1. Ask: "Is anyone running Logstash?"
2. Use your own `--path.data`, e.g. `/tmp/logstash-lab/data-u01`.
3. When you finish: `Ctrl+C`, then the next student starts.

## Module order

`05_Logstash_Primer.md` → Concepts → Lab → Exercises

## Day 5 traps

1. **`/var/log/secure` missing** — trainer must enable rsyslog before class; you cannot fix this yourself.
2. **Wrong URL** — query URL in the config → empty table with no obvious error.
3. **Wrong database** — `database =>` must match **your** `ADXTrainingDB_<login>`.
4. **Wait 2–5 minutes** after sudo/SSH activity before `LogstashHostLogs | count` looks wrong.
5. **Real auth log** — tail `/var/log/secure`; do not use a fake `/tmp` file.
6. **Do not commit** the client secret or paste it in chat.
7. **Sudo denied** — Linux password at prompt; if not in sudoers, trainer runs `grant_sudo_lab_users.sh`.

## ADX

Portal → cluster **adxtrainaug26** → database **`ADXTrainingDB_<your-login>`**.

```kusto
print Database = current_database()
```

Must show your database before `create_tables.kql`.
