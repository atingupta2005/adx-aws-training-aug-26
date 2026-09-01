# Session 01 — Grok deep dive

**Goal:** Understand how Logstash turns one syslog line into named fields — and what happens when the pattern does not match.

**Prerequisite:** Skim `Module_05_Logstash/05_Logstash_Primer.md` (grok vocabulary).

**Config:** `assets/logstash_in_depth/grok-stdout-lab.conf.example`  
**Sample file:** `assets/logstash_in_depth/sample-auth-lines.log`

---

## 1. Why grok exists

Raw auth lines are **one string**. ADX (and KQL) work best on **columns**. Grok is a filter that applies a named pattern — built from tokens like `%{SYSLOGHOST:Hostname}` — and extracts substrings into fields.

The lab pipeline uses:

```
%{SYSLOGTIMESTAMP:syslog_timestamp} %{SYSLOGHOST:Hostname} %{DATA:Process}(?:\[%{POSINT:Pid}\])?: %{GREEDYDATA:Message}
```

Read it left to right:

| Token | Meaning |
|-------|---------|
| `SYSLOGTIMESTAMP` | `Aug 31 09:14:23` style timestamp |
| `SYSLOGHOST` | Hostname token |
| `DATA:Process` | Process name (`sudo`, `sshd`, …) |
| `(?:\[%{POSINT:Pid}\])?` | Optional `[12345]` pid in brackets |
| `GREEDYDATA:Message` | Everything after the colon |

The `(?: … )?` part is **optional**. Lines without `[pid]` still match; `Pid` is empty until the lab adds `0` in a later `mutate`.

---

## 2. Hands-on: stdout-only grok lab

**Why stdout first:** You see parsed events in the terminal immediately. No ADX delay, no Entra secret — fix grok before wiring kusto output.

### Do this exactly

On the lab VM:

```bash
mkdir -p /tmp/logstash-lab
cp ~/adx-aws-training/assets/logstash_in_depth/sample-auth-lines.log /tmp/logstash-lab/
cp ~/adx-aws-training/assets/logstash_in_depth/grok-stdout-lab.conf.example /tmp/logstash-lab/grok-stdout-lab.conf
```

Edit the `path =>` in the config if your copy landed elsewhere — it must match where `sample-auth-lines.log` lives.

Validate:

```bash
cd /usr/share/logstash
sudo bin/logstash --path.settings /etc/logstash \
  -f /tmp/logstash-lab/grok-stdout-lab.conf \
  --config.test_and_exit
```

Run (expect ~6 events, then Logstash may idle):

```bash
sudo bin/logstash --path.settings /etc/logstash \
  --path.data /tmp/logstash-lab/data-<your-login>-grok \
  -f /tmp/logstash-lab/grok-stdout-lab.conf
```

### Checkpoint

In the rubydebug output you should see, per event:

- `Hostname` = `ip-10-0-1-42`
- `Process` = `sudo` or `sshd` or `su`
- `Message` containing `student`, `baduser`, or `COMMAND=`
- **No** tag `_grokparsefailure` on the sample lines

Press Ctrl+C when done.

---

## 3. Break the pattern on purpose

**Goal:** See `_grokparsefailure` so you recognize it in production.

1. Copy the config to `grok-broken.conf`.
2. Change `GREEDYDATA:Message` to `WORD:Message` (too short — will not capture long sudo messages).
3. Re-run Logstash against the same sample file (`sincedb_path => "/dev/null"` replays from the start).

### Checkpoint

Events should carry `"tags" => ["_grokparsefailure"]` and `Message` may be wrong or missing.

**Fix:** Restore `GREEDYDATA:Message` or widen the pattern.

---

## 4. Match against live `/var/log/secure`

After the sample file works, point the **same grok block** at the real auth log (still stdout only):

```ruby
input {
  file {
    path => "/var/log/secure"
    start_position => "end"   # only new lines while you watch
    sincedb_path => "/dev/null"
    codec => "plain"
  }
}
```

In a second terminal:

```bash
sudo true
ssh baduser@127.0.0.1
```

### Checkpoint

New events in Logstash stdout within a few seconds of each action. If nothing appears, check path (`/var/log/auth.log` on Debian/Ubuntu) and permissions (`sudo tail` works?).

---

## 5. Common grok mistakes (Module 05 class)

| Mistake | Symptom |
|---------|---------|
| ECS left enabled | Fields renamed to `[host][name]` — ADX mapping misses `Hostname` |
| Pattern too strict | `_grokparsefailure` tags; ADX rows with null columns |
| Wrong timestamp token | `date` filter fails; `LogTime` empty |
| Forgetting optional pid | Usually OK — lab sets `Pid` to 0 |

---

## Next

[Session 02 — Debug pipeline with stdout](02_Debug_Pipeline_Stdout.md)
