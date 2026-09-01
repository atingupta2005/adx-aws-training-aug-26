# Module 05 — Logstash → ADX

**Cloud isolated lab VM** → tail `/var/log/secure` → Logstash → ADX table `LogstashHostLogs`.

## Reading order

1. [05_Logstash_Primer.md](05_Logstash_Primer.md)  
2. [05_Logstash_ADX_Integration_Concepts.md](05_Logstash_ADX_Integration_Concepts.md)  
3. [05_Logstash_ADX_Integration_Lab.md](05_Logstash_ADX_Integration_Lab.md)  
4. [05_Exercises.md](05_Exercises.md)  

**Assets:** `assets/module_05/` (pipeline example, KQL, sample `web.log`)

## In-depth practicals (after core lab)

[../Logstash_In_Depth/README.md](../Logstash_In_Depth/README.md) — grok, stdout debug, second log shape, troubleshooting.

## Prerequisites

- Modules 01–04 complete (ADX database exists; hybrid context from M04)  
- Linux lab VM running; coordinate turn-taking on shared Logstash  
