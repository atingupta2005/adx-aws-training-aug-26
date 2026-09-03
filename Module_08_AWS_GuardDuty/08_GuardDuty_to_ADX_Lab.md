# Module 08 — Lab (GuardDuty → EventBridge → Firehose → S3 → ADX)

**Reading order:** Primer → Concepts → **this Lab** → Exercises.

**Database:** `ADXTrainingDB_<your-login>`.

**KQL files:** `assets/module_08/`.

**S3 bucket:** `adx-classroom-guardduty-export` (prefix `guardduty/`).

**AWS sign-in:** use your normal lab IAM user from the access card (same as other modules). Region **`us-east-1`**.

---

## What you will do

```text
GuardDuty → Generate sample findings
  → wait for S3
  → create ADX table
  → .ingest one (or a few) S3 objects
  → query GuardDutyFindings
```

Findings move GuardDuty → EventBridge → Firehose → S3. Objects are EventBridge **envelopes** — map with `$.detail.*`.

After **Generate sample findings**, wait **60–90 seconds** before checking S3.

---

## Before Step 1

1. Azure portal → ADX cluster → **Query** → database `ADXTrainingDB_<your-login>`.  
2. Run: `print Database = current_database()`  
3. AWS console → region **US East (N. Virginia)** → open **GuardDuty**.

---

## Step 1 — Generate findings (AWS console)

1. GuardDuty → left menu → **Settings**.  
2. **Generate sample findings**.  
3. Open **Findings** — sample rows appear in about 30 seconds.  
4. Wait **60–90 seconds** (Firehose buffer).

### Checkpoint

Findings page shows sample findings (titles often start with `[SAMPLE]`).

---

## Step 2 — Confirm data in S3 (AWS console)

1. AWS console → **S3**.  
2. Open bucket **`adx-classroom-guardduty-export`**.  
3. Open folder **`guardduty/`**, then today’s date folders (year / month / day / …).  
4. Confirm at least one object is listed.  
5. Click one object → copy its **key** (path) or **Object URL** — you need this for ingest.

### Checkpoint

You can see a recent object under `guardduty/` and have copied its key or URL.

### If S3 looks empty

Wait another minute, refresh the bucket. If it is still empty, ask the trainer.

---

## Step 3 — Create the ADX table

In your ADX database, run **`assets/module_08/create_tables.kql`**.

Confirm the mapping uses `$.detail.id` and `$.detail.type` (not bare `$.id` / `$.type`).

```kusto
.show table GuardDutyFindings ingestion mappings
```

---

## Step 4 — Ingest from S3 into ADX

Use your **lab access-card** Access Key ID and Secret (same AWS user you use for the console). Do **not** create a separate IAM user for this module.

In the ADX query window, run an ingest like this (paste your values):

```kusto
.ingest into table GuardDutyFindings
h@"https://adx-classroom-guardduty-export.s3.us-east-1.amazonaws.com/<object-key>;AwsCredentials=<AccessKeyId>,<SecretAccessKey>"
with (format="multijson", ingestionMappingReference="GD_Mapping")
```

Replace:

| Placeholder | From |
|-------------|------|
| `<object-key>` | S3 object key, e.g. `guardduty/2026/09/03/01/....` |
| `<AccessKeyId>` / `<SecretAccessKey>` | Your lab IAM keys on the access card |

Then:

```kusto
GuardDutyFindings | count
GuardDutyFindings
| take 5
| project EventTime, FindingId, FindingType, Severity
```

`FindingId` and `FindingType` must be non-empty.

You can repeat the `.ingest` for one or two more objects if you want more rows.

---

## Step 5 — Query

```kusto
GuardDutyFindings
| summarize Count = count() by FindingType, Severity
| order by Severity desc
```

Also try `assets/module_08/validate.kql` and `explore.kql`.

### Done when

- You generated sample findings in the **console**  
- You saw objects in S3 in the **console**  
- ADX has rows with populated `FindingType`  
- You know why the mapping uses `$.detail.*`

---

## Quick failure guide

| Problem | Fix |
|---------|-----|
| Empty S3 | Wait for Firehose; ask trainer if still empty |
| `FindingId` empty | Mapping must use `$.detail.id` |
| Ingest auth error | Use your lab access-card keys; check key/secret typos |
| Wrong database | `print Database = current_database()` |
