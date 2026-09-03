# Module 08 — Exercises

After the core lab. KQL: `assets/module_08/explore.kql`.

## Practice

### E1 — By severity

```kusto
GuardDutyFindings
| summarize Findings = count() by Severity
| order by Severity desc
```

### E2 — Top types

```kusto
GuardDutyFindings
| summarize Findings = count() by FindingType
| order by Findings desc
| take 15
```

### E3 — Recent titles

```kusto
GuardDutyFindings
| order by EventTime desc
| take 10
| project EventTime, Severity, FindingType, Title
```

### E4 — FindingId populated

```kusto
GuardDutyFindings
| where isnotempty(FindingId)
| count
```

## Stretch

### E5 — High severity

```kusto
GuardDutyFindings
| where Severity >= 7
| project EventTime, FindingType, Title, Description
```

### E6 — GuardDuty vs CloudTrail

One paragraph: when would you use each?

### E7 — Resource field

```kusto
GuardDutyFindings
| where isnotempty(ResourceData)
| take 5
| project FindingType, ResourceData
```
