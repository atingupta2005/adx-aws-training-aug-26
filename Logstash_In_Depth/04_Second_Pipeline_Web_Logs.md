# Session 04 — Second pipeline: web access logs

**Goal:** Parse a **different log shape** (HTTP access lines) with grok — same input/filter/output pattern as auth logs, different pattern.

**Sample file:** `assets/module_05/web.log` (also copied in repo)  
**Config:** `assets/logstash_in_depth/nginx-stdout-lab.conf.example`

This session is **stdout-only** by default. Sending web logs to ADX is an optional stretch at the end.

---

## 1. Why a second shape?

Production hosts write many file types:

| File | Typical content |
|------|-----------------|
| `/var/log/secure` | SSH, sudo, PAM |
| `/var/log/nginx/access.log` | HTTP requests |
| Application logs | JSON or custom text |

Each shape needs its **own grok pattern** (or JSON filter). Module 05 lab uses auth logs. This session practices **HTTP-style** lines so grok does not feel like a one-off magic string.

---

## 2. Sample line anatomy

From `web.log`:

```
2026-07-31T12:05:00Z 192.168.1.10 GET /index.html 200 1024
```

Target fields:

| Field | Example |
|-------|---------|
| `EventTime` | ISO8601 prefix |
| `ClientIp` | `192.168.1.10` |
| `HttpMethod` | `GET` |
| `RequestPath` | `/index.html` |
| `StatusCode` | `200` |
| `Bytes` | `1024` |

Pattern used in the example config:

```
%{TIMESTAMP_ISO8601:EventTime} %{IPORHOST:ClientIp} %{WORD:HttpMethod} %{URIPATH:RequestPath} %{NUMBER:StatusCode:int} %{NUMBER:Bytes:int}
```

---

## 3. Hands-on

```bash
cp ~/adx-aws-training/assets/logstash_in_depth/nginx-stdout-lab.conf.example \
   /tmp/logstash-lab/nginx-stdout-lab.conf
```

Fix the `path =>` in the input block to your clone path, e.g.:

```ruby
path => "/home/student/adx-aws-training/assets/module_05/web.log"
```

Validate and run:

```bash
sudo /usr/share/logstash/bin/logstash --path.settings /etc/logstash \
  -f /tmp/logstash-lab/nginx-stdout-lab.conf --config.test_and_exit

sudo /usr/share/logstash/bin/logstash --path.settings /etc/logstash \
  --path.data /tmp/logstash-lab/data-<your-login>-web \
  -f /tmp/logstash-lab/nginx-stdout-lab.conf
```

### Checkpoint

- At least 15 events printed  
- `StatusCode` is integer `200`, `401`, `403`, or `500`  
- `_grokparsefailure` absent on standard lines  

---

## 4. Query-style thinking (stdout → KQL)

Even before ADX, decide what you would ask:

- How many `401` responses? → count where `StatusCode == 401`  
- Top paths? → summarize by `RequestPath`  
- Same client scanning `/admin`? → filter `ClientIp` and path prefix  

When you later store similar fields in ADX, the KQL mirrors these questions.

---

## 5. Stretch — send web logs to ADX

Only if instructor approves (extra table + mapping):

1. Extend `create_tables.kql` with `LogstashWebLogs` and mapping (or a trainer-provided KQL file).  
2. Copy nginx config; replace `stdout` with `kusto { ... table => "LogstashWebLogs" ... }`.  
3. Use **ingest** URL and Entra app from Module 05.  
4. Wait 2–5 minutes; validate row count.

Most classes stop at stdout for this session — the learning goal is **second grok pattern**, not a second ADX table.

---

## Next

[Session 05 — Operations and troubleshooting](05_Operations_and_Troubleshooting.md)
