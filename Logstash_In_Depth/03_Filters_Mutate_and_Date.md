# Session 03 — Filters: mutate and date

**Goal:** Understand what happens **after** grok — defaults, types, timestamps, and field cleanup — before events reach ADX.

Use the same stdout lab config from Session 01.

---

## 1. Order matters

Logstash runs filters **top to bottom** for each event:

1. **grok** — extract raw tokens  
2. **date** — parse `syslog_timestamp` → `LogTime`  
3. **if ![Pid]** — default missing pid  
4. **mutate convert** — string `"0"` → integer `0`  
5. **mutate remove_field** — drop noise (never remove `@timestamp` when using kusto plugin v2)

If you `remove_field` before `date`, the date filter has nothing to parse.

---

## 2. `date` filter and ADX

Syslog timestamps often lack a year. The lab uses:

```ruby
date {
  match => [ "syslog_timestamp", "MMM  d HH:mm:ss", "MMM dd HH:mm:ss" ]
  target => "LogTime"
}
```

- **`target => "LogTime"`** creates the column ADX expects (via JSON mapping `$.LogTime`).
- Logstash still keeps **`@timestamp`** for internal use (staging path token in kusto output).

**Checkpoint:** On stdout, both `@timestamp` and `LogTime` may appear. Only mapped fields land in `LogstashHostLogs`.

---

## 3. Default `Pid` with `mutate`

```ruby
if ![Pid] {
  mutate { add_field => { "Pid" => "0" } }
}
mutate { convert => { "Pid" => "integer" } }
```

**Why:** ADX column is `int`. Grok leaves `Pid` unset when the line has no `[12345]` bracket. Kusto plugin sends JSON; ADX rejects or nulls wrong types if you skip conversion.

---

## 4. Practice: add a derived field

Add after grok (stdout lab only):

```ruby
mutate {
  add_field => { "LogSource" => "lab-vm-auth" }
}
```

Run Logstash. **Do not** add this to the ADX pipeline unless you also extend `create_tables.kql` and the JSON mapping — unmapped fields are dropped.

**Lesson:** Every ADX column needs a mapping path. Logstash can carry extra fields; ADX ignores them unless mapped.

---

## 5. `remove_field` safety list

Safe to remove in the lab pipeline (not sent to ADX):

- `message`, `syslog_timestamp`, `@version`, `host`, `path`, `event`, `log`

**Never remove in kusto pipeline:**

- `@timestamp` (staging path `%{+YYYY-MM-dd-HH-mm}` breaks)

---

## 6. Exercise — strip noise from Message

Some lines include `last message repeated N times`. Optional stretch:

```ruby
mutate {
  gsub => [ "Message", " last message repeated \d+ times", "" ]
}
```

Re-run against sample file. Confirm `Message` is cleaner on stdout.

---

## Next

[Session 04 — Second pipeline: web access logs](04_Second_Pipeline_Web_Logs.md)
