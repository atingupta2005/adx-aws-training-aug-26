# How we work on Day 2 (Modules 02–03)

Same logins as Day 1 (`u01` … `u06`). Course folder is already at `~/adx-aws-training` — do **not** `git clone` again.

```bash
cd ~/adx-aws-training
ls Module_02_AWS_CloudTrail Module_03_AWS_CloudWatch assets/module_02 assets/module_03
aws sts get-caller-identity
```

ARN must end with `user/u01` (or **your** login). If not, run `aws configure` again with the **card** keys.

## Write these names once (do not invent initials)

| What | Pattern (example `u01`) |
|------|-------------------------|
| ADX database | `ADXTrainingDB_u01` |
| Shared CloudTrail bucket | **`adx-classroom-cloudtrail`** (everyone — do not create or delete) |
| Shared trail name | `adx-classroom-trail` (trainer only) |
| M02 activity bucket (temp) | `adx-ct-activity-u01` |
| M02 reader IAM | `adx-cloudtrail-reader-u01` |
| M03 log group | `/adx-training/app-logs-u01` |
| M03 Firehose | `cw-to-adx-stream-u01` |
| M03 landing bucket | `adx-cw-firehose-u01` |
| M03 reader IAM | `adx-cw-s3-reader-u01` |

## Two key pairs (same rule as Module 01)

| Keys | Used for |
|------|----------|
| Access card (`u01` … `u06`) | Console, `aws configure`, scripts that call AWS APIs |
| Reader users (`adx-*-reader-*`) | **Only** the ADX `.ingest` URI. Never `aws configure` |

You will create a **new** reader per module (CloudTrail reader for M02, Firehose-bucket reader for M03). Do not reuse the Module 01 reader policy on the wrong bucket.

## Module order

1. Concepts + lab: `Module_02_AWS_CloudTrail/`
2. Concepts + lab: `Module_03_AWS_CloudWatch/`

## Day 2 traps (read before you click)

1. **Trail wait is normal** — empty S3 for 5–15 minutes after `generate_events.sh` is expected. Build tables and IAM while waiting.
2. **Reader policy bucket must match the module** — M02 = `adx-classroom-cloudtrail`; M03 = `adx-cw-firehose-<your-login>`; never paste `adx-log-ingestion-*` into the M02/M03 reader.
3. **Reader policy must keep `s3:GetBucketLocation`** — copy the full `assets/iam/s3-reader-policy.json` and replace both `BUCKET_NAME` strings.
4. **M03 order** — log group → S3 → Firehose **Active** → subscription filter → **then** `put_log_events.sh`. Events before the filter never appear in S3.
5. **Git Bash / VS Code** — before any `aws logs` command: `export MSYS_NO_PATHCONV=1`
6. **Do not delete** the shared trail or `adx-classroom-cloudtrail`. Do not drop `CloudTrailEvents` or `CloudWatchLogs` — Module 04 needs them.

## ADX

Portal → cluster **adxtrainaug26** → database **`ADXTrainingDB_<your-login>`** only.

```kusto
print Database = current_database()
```

Must show your database before any `.create` / `.ingest`.
