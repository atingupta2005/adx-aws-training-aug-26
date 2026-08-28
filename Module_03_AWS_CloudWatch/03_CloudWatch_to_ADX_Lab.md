# Module 03 — Lab

Build log group → Firehose → S3 in the console, create the ADX table, put a few live events, wait for an object, ingest the envelope.

Scripts and KQL: `assets/module_03/`.

**Names** (use your login from the access card: `u01` … `u06`. Do not invent initials.)

| Resource | Example for `u01` |
|----------|-------------------|
| Database | `ADXTrainingDB_u01` |
| Log group | `/adx-training/app-logs-u01` |
| Stream | `Instance_01_u01` |
| Bucket | `adx-cw-firehose-u01` |
| Firehose | `cw-to-adx-stream-u01` |
| Subscription filter | `ADX-Export-Filter-u01` |
| IAM reader | `adx-cw-s3-reader-u01` |

Before you start:

- Git Bash: `export MSYS_NO_PATHCONV=1` before any `aws logs` command
- Do not put events until the subscription filter exists
- On Windows the put script uses `python` if `python3` is the Store stub

**Two key pairs:**

| Keys | Where they go |
|------|----------------|
| Access card (`u01` … `u06`) | Console + `aws configure` + Firehose / CloudWatch setup |
| `adx-cw-s3-reader-*` from Step 2 | `.ingest` URI only — never `aws configure` |

## AWS console path

```mermaid
%%{init: {"theme":"base","flowchart":{"htmlLabels":true,"padding":12}}}%%
flowchart TB
  subgraph cw [CloudWatch]
    LG["Log groups<br/>/adx-training/app-logs-u01"]
    STR["Log stream<br/>Instance_01_u01"]
    SF["Subscription filter<br/>ADX-Export-Filter-u01"]
  end
  subgraph kin [Amazon Data Firehose]
    FH["cw-to-adx-stream-u01<br/>decompress ON"]
  end
  subgraph s3 [S3]
    BKT[("adx-cw-firehose-u01")]
  end
  subgraph adx [ADX]
    TBL[("CloudWatchLogs")]
  end
  PUT["put-log-events"] --> LG
  LG --> STR
  STR --> SF
  SF --> FH
  FH --> BKT
  BKT -->|".ingest"| TBL
  style cw fill:#FFF4E5,stroke:#FF9900,color:#232F3E
  style kin fill:#E8EAF6,stroke:#3B48CC,color:#1B2266
  style s3 fill:#232F3E,stroke:#FF9900,color:#fff
  style adx fill:#E6F2FB,stroke:#0078D4,color:#003A5D
  style LG fill:#FF9900,stroke:#232F3E,color:#fff
  style FH fill:#3B48CC,stroke:#1B2266,color:#fff
  style BKT fill:#232F3E,stroke:#FF9900,color:#fff
  style TBL fill:#0078D4,stroke:#005A9E,color:#fff
```

## Step 1 — AWS console (order matters)

**Goal:** CloudWatch log events flow to S3 through Firehose so ADX can pull one object.

**Correct order:** log group + stream → S3 bucket → Firehose (Active) → subscription filter → put events.

Events written **before** the subscription filter exists are **not** shipped retroactively.

### 1a — Log group and stream

1. **CloudWatch** → **Log groups** → **Create log group**
2. Name: `/adx-training/app-logs-<your-login>` (leading `/` is required)
3. Retention: **1 day** → **Create**
4. Open the log group → **Create log stream** → name `Instance_01_<your-login>` → **Create**

**Checkpoint:** Log group and stream appear in the console.

### 1b — S3 bucket

1. **S3** → **Create bucket**
2. Name: `adx-cw-firehose-<your-login>`
3. Region: **us-east-1**
4. **Block all public access** = on → **Create bucket**

### 1c — Firehose delivery stream

1. Search **Firehose** (console may also list this under **Amazon Data Firehose** or **Kinesis**)
2. **Create Firehose stream** (or **Create delivery stream**)
3. **Source:** **Direct PUT**
4. **Destination:** **Amazon S3** → bucket `adx-cw-firehose-<your-login>`
5. **Buffer hints:** **1 MiB** and **60 seconds**
6. **S3 compression:** **UNCOMPRESSED**
7. **Transform records** (important — matches current AWS docs):
   - Do **not** enable **Transform source records with AWS Lambda** / **Enable data transformation**
   - Under **Decompress source records from Amazon CloudWatch Logs**, choose **Turn on decompression**
8. Create a new IAM role when prompted (Firehose → S3 write)
9. **Create** → wait until stream status is **Active**

CloudWatch sends gzip-compressed batches to Firehose. Decompression must be on so S3 objects are readable JSON envelopes.

### 1d — Subscription filter

**Recommended path** (matches AWS console today):

1. **CloudWatch** → your log group `/adx-training/app-logs-<your-login>`
2. **Actions** → **Subscription filters** → **Create Amazon Data Firehose subscription filter**
3. Select your stream `cw-to-adx-stream-<your-login>`
4. Filter pattern: leave blank (match all) for the lab
5. Create a new IAM role (CloudWatch Logs → Firehose) → name example `ADX-Export-Filter-<your-login>` → **Create**

**Alternate path:** Log group → **Subscription filters** tab → **Create** → destination **Firehose** → same stream name.

**Checkpoint:** Subscription filter listed on the log group; Firehose stream status **Active**.

## Step 2 — ADX table and IAM reader

**Goal:** Table and mapping match the **CloudWatch envelope** (`messageType`, `logEvents`, …), not the inner JSON in `message`.

1. In `ADXTrainingDB_<your-login>`, run `assets/module_03/create_tables.kql`
2. IAM user **`adx-cw-s3-reader-<your-login>`** with `assets/iam/s3-reader-policy.json` where `BUCKET_NAME` is **`adx-cw-firehose-<your-login>`** (your Firehose bucket, not Module 01 or the trail bucket)
3. Create access keys → notepad for ingest URI only

**Checkpoint:** `.show tables` includes `CloudWatchLogs`.

## Step 3 — Put events

**Goal:** Three live messages (with your account id and ARN) reach S3 via the filter + Firehose path.

```bash
export MSYS_NO_PATHCONV=1
bash assets/module_03/put_log_events.sh us-east-1 <your-login>
```

**Example:** `bash assets/module_03/put_log_events.sh us-east-1 u01`

Wait **60–90 seconds** (Firehose buffer), then:

```bash
aws s3 ls s3://adx-cw-firehose-<your-login>/ --recursive
```

You should see a new object under a path like `2026/08/28/01/cw-to-adx-stream-u01-...`.

**If the bucket is empty:** confirm subscription filter exists and Firehose **decompress for CloudWatch Logs** is on before re-running the put script.

## Step 4 — Ingest and check

**Goal:** All Firehose objects in nested folders ingested into `CloudWatchLogs`.

1. Run `assets/module_03/create_tables.kql` if not done in Step 2
2. Ingest without copying each nested key:

```bash
bash assets/ingest_s3_to_adx.sh --module m03 --login <your-login> --region us-east-1 --max 10 --run
```

Or open `assets/module_03/ingest.kql` for a single object, or paste `~/adx-lab-s3/m03/ingest_generated.kql` in the Web UI.
3. Run `assets/module_03/validate.kql`
4. Filter to `messageType == "DATA_MESSAGE"`
5. Leave `CloudWatchLogs` for Module 04

**You're done when**

- An object showed up in `adx-cw-firehose-<your-login>`
- `CloudWatchLogs` has a `DATA_MESSAGE` row
- `logEvents` is not empty

**If S3 is empty**

```mermaid
%%{init: {"theme":"base","flowchart":{"htmlLabels":true,"padding":12}}}%%
flowchart TD
  START["S3 bucket empty?"] --> Q1{"Subscription filter exists?"}
  Q1 -->|no| FIX1["Create filter first<br/>then put events again"]
  Q1 -->|yes| Q2{"Events sent before filter?"}
  Q2 -->|yes| FIX2["Re-run put_log_events.sh"]
  Q2 -->|no| Q3{"Firehose decompress ON?"}
  Q3 -->|no| FIX3["Turn on decompression<br/>under Transform records"]
  Q3 -->|yes| Q4{"Firehose Active?"}
  Q4 -->|no| FIX4["Wait until Active"]
  Q4 -->|yes| Q5{"Git Bash ate log group /?"}
  Q5 -->|yes| FIX5["export MSYS_NO_PATHCONV=1"]
  Q5 -->|no| HELP["Ask trainer"]
  style START fill:#F25022,stroke:#8B1A00,color:#fff
  style FIX1 fill:#107C10,stroke:#0B5A0B,color:#fff
  style FIX2 fill:#107C10,stroke:#0B5A0B,color:#fff
  style FIX3 fill:#107C10,stroke:#0B5A0B,color:#fff
  style FIX4 fill:#107C10,stroke:#0B5A0B,color:#fff
  style FIX5 fill:#107C10,stroke:#0B5A0B,color:#fff
  style HELP fill:#8764B8,stroke:#5C2D91,color:#fff
```
