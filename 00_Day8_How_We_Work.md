# How we work — Module 08 (GuardDuty)

Same logins (`u01` … `u06`). Same lab VS Code host and AWS console. Use your **access-card** AWS user.

## Start here

```bash
cd ~/adx-aws-training
ls Module_08_AWS_GuardDuty assets/module_08
```

Open AWS console in **`us-east-1`** and ADX Query on `ADXTrainingDB_<your-login>`.

## Reading order

1. `08_GuardDuty_Primer.md` — GuardDuty, EventBridge, envelope (read carefully)  
2. `08_GuardDuty_to_ADX_Concepts.md` — full path, mapping, why `$.detail.*`  
3. `08_GuardDuty_to_ADX_Lab.md` — short console + ADX practical  
4. `08_Exercises.md`

## Remember

- Concepts are detailed; the **lab clicks** stay short (console + ADX `.ingest`)  
- Path: GuardDuty → EventBridge → Firehose → `adx-classroom-guardduty-export` / `guardduty/`  
- Wait **60–90 seconds** after Generate sample findings before checking S3  
- Map with `$.detail.*`
