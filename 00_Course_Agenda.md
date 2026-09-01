# Course agenda

## Course map

```mermaid
%%{init: {"theme":"base","flowchart":{"htmlLabels":true,"padding":12}}}%%
flowchart TB
  D1["M01 S3"] --> D2["M02 CloudTrail"]
  D2 --> D3["M03 CloudWatch"]
  D3 --> D4["M04 Hybrid"]
  D4 --> D567["M05–07 Beats"]
  D567 --> D8["M08 GuardDuty"]
  D8 --> ADX["ADX + KQL"]
  style D1 fill:#FF9900,stroke:#232F3E,color:#fff
  style D2 fill:#EC7211,stroke:#232F3E,color:#fff
  style D3 fill:#3B48CC,stroke:#1B2266,color:#fff
  style D4 fill:#0078D4,stroke:#005A9E,color:#fff
  style D567 fill:#7FBA00,stroke:#3A6B00,color:#fff
  style D8 fill:#D13212,stroke:#8B1A00,color:#fff
  style ADX fill:#50E6FF,stroke:#0078D4,color:#003A5D
```

## Module document set

Each module folder: **Primer** → **Concepts** → **Lab** → **Exercises** + `assets/module_XX/explore.kql`.

## Days

| Day | Modules | Start |
|-----|---------|--------|
| 1 | 01 S3 | `00_Day1_How_We_Work.md` |
| 2 | 02 CloudTrail + 03 CloudWatch (or **one module per day**) | `00_Day2_How_We_Work.md` |
| Later | 04 Hybrid (issued) · 05 Logstash + in-depth (issued) · 06–08 as issued | Prerequisite notes in each Primer |

Shared resources: trail bucket **`adx-classroom-cloudtrail`** · GuardDuty export **`adx-classroom-guardduty-export`** · Linux VM for M05–07 (turn-taking).
