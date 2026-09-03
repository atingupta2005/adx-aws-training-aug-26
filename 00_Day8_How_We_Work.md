# How we work — Module 08 (GuardDuty)

Same logins (`u01` … `u06`). Same lab VS Code / AWS console. Use your **access-card** AWS user (no extra IAM user for this module).

## Start here

```bash
cd ~/adx-aws-training
ls Module_08_AWS_GuardDuty assets/module_08
```

Open the AWS console in **`us-east-1`** and ADX Query on `ADXTrainingDB_<your-login>`.

## Reading order

1. `08_GuardDuty_Primer.md`  
2. `08_GuardDuty_to_ADX_Concepts.md`  
3. `08_GuardDuty_to_ADX_Lab.md`  
4. `08_Exercises.md`

## Remember

- Mostly **console** for GuardDuty + S3; **ADX Query** for table + `.ingest` + queries  
- Path: GuardDuty → EventBridge → Firehose → `adx-classroom-guardduty-export` / `guardduty/`  
- Wait **60–90 seconds** after Generate sample findings  
- Map with `$.detail.*`
