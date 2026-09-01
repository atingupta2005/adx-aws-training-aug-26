# Logstash — in-depth practical sessions

Use this folder **after** you complete the core path in `Module_05_Logstash/` (Primer → Concepts → Lab → Exercises).

The core lab wires one pipeline: **live `/var/log/secure` → grok → ADX `LogstashHostLogs`**. These sessions go deeper on the parts students struggle with in class: **grok**, **debugging**, **extra filters**, a **second log shape** (web access lines), and **operations** (sincedb, queued ingest, shared VM).

---

## Reading order

| Session | File | What you practice |
|---------|------|-------------------|
| 1 | [01_Grok_Deep_Dive.md](01_Grok_Deep_Dive.md) | Pattern anatomy, optional `[pid]`, `_grokparsefailure`, fixing mismatches |
| 2 | [02_Debug_Pipeline_Stdout.md](02_Debug_Pipeline_Stdout.md) | `--config.test_and_exit`, `stdout { codec => rubydebug }`, no ADX until it parses |
| 3 | [03_Filters_Mutate_and_Date.md](03_Filters_Mutate_and_Date.md) | `mutate`, `convert`, defaults, `date` targets, field cleanup |
| 4 | [04_Second_Pipeline_Web_Logs.md](04_Second_Pipeline_Web_Logs.md) | Tail `assets/module_05/web.log`, grok HTTP fields, stdout then optional ADX stretch |
| 5 | [05_Operations_and_Troubleshooting.md](05_Operations_and_Troubleshooting.md) | sincedb, `--path.data`, ingest lag, empty table checklist |

**Config examples:** `assets/logstash_in_depth/*.conf.example`  
**Sample lines:** `assets/logstash_in_depth/sample-auth-lines.log`

---

## Where you run these

Same **cloud isolated lab VM** as Module 05 (Amazon Linux, Logstash pre-installed). Coordinate **turn-taking** — one Logstash process at a time unless you use a unique `--path.data` per login.

Sessions 1–3 can use **stdout only** (no ADX, no Entra secret) so you can iterate quickly. Session 4 adds a file tail; Session 5 ties back to the production kusto output from the core lab.

---

## Quick command reference

```bash
# Syntax check (no pipeline run)
sudo /usr/share/logstash/bin/logstash \
  --path.settings /etc/logstash \
  -f /tmp/logstash-lab/my.conf \
  --config.test_and_exit

# Run with debug output to terminal
sudo /usr/share/logstash/bin/logstash \
  --path.settings /etc/logstash \
  --path.data /tmp/logstash-lab/data-<your-login> \
  -f /tmp/logstash-lab/my.conf
```

Always set `ecs_compatibility => disabled` inside `grok { }` blocks when field names must match ADX JSON mapping exactly.
