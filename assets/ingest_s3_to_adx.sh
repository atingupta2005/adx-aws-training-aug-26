#!/usr/bin/env bash
# Discover objects under an S3 prefix (nested folders) and ingest into ADX.
#
# ADX on this cluster does not support S3 wildcards or external tables over Amazon S3.
# This script lists keys with AWS CLI, builds multi-URI .ingest, and optionally runs ingest via Azure CLI.
#
# Usage — module presets (recommended):
#   bash assets/ingest_s3_to_adx.sh --module m01 --login u01 --region us-east-1 [--run]
#   bash assets/ingest_s3_to_adx.sh --module m02 --login u01 --region us-east-1 [--max 5] [--run]
#   bash assets/ingest_s3_to_adx.sh --module m03 --login u01 --region us-east-1 [--max 10] [--run]
#   bash assets/ingest_s3_to_adx.sh --module m08 --login u01 --region us-east-1 [--max 5] [--run]
#
# Usage — custom bucket:
#   bash assets/ingest_s3_to_adx.sh --bucket my-bucket --prefix path/nested/ --login u01 \
#     --table MyTable --mapping My_Mapping --format multijson --reader-env ~/reader.env [--run]
#
# Prerequisites:
#   - aws configure with card keys (for s3api list-objects-v2)
#   - Reader keys in ~/adx-lab-mNN/reader.env (see each module lab)
#   - For --run: az login with Entra account that can query ADX (trainer workstation or lab VM with az)
#
# Output (always):
#   ~/adx-lab-s3/<module>/ingest_generated.kql
#   ~/adx-lab-s3/<module>/ingest_keys.txt
set -euo pipefail
export MSYS_NO_PATHCONV=1

ASSETS_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "${ASSETS_DIR}/.." && pwd)"
KUSTO_PY="${ASSETS_DIR}/common/kusto_cmd.py"
CLUSTER="${ADX_CLUSTER_URI:-https://adxtrainaug26.centralindia.kusto.windows.net}"

MODULE=""
LOGIN=""
REGION="us-east-1"
BUCKET=""
PREFIX=""
SUFFIX=""
TABLE=""
MAPPING=""
FORMAT=""
READER_ENV=""
MAX_FILES=10
RUN=0
EXTRA_INGEST=0

usage() {
  sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'
  exit 1
}

while [ $# -gt 0 ]; do
  case "$1" in
    --module) MODULE="${2:?}"; shift 2 ;;
    --login) LOGIN="${2:?}"; shift 2 ;;
    --region) REGION="${2:?}"; shift 2 ;;
    --bucket) BUCKET="${2:?}"; shift 2 ;;
    --prefix) PREFIX="${2:?}"; shift 2 ;;
    --suffix) SUFFIX="${2:?}"; shift 2 ;;
    --table) TABLE="${2:?}"; shift 2 ;;
    --mapping) MAPPING="${2:?}"; shift 2 ;;
    --format) FORMAT="${2:?}"; shift 2 ;;
    --reader-env) READER_ENV="${2:?}"; shift 2 ;;
    --max) MAX_FILES="${2:?}"; shift 2 ;;
    --run) RUN=1; shift ;;
    -h|--help) usage ;;
    *) echo "Unknown option: $1" >&2; usage ;;
  esac
done

: "${LOGIN:?Pass --login u01 … u06}"

apply_preset() {
  local account
  account=$(aws sts get-caller-identity --query Account --output text)
  case "$MODULE" in
    m01)
      BUCKET="adx-log-ingestion-${LOGIN}"
      PREFIX=""
      SUFFIX=""
      TABLE="" # two tables — handled in run_m01_ingest
      MAPPING=""
      FORMAT=""
      READER_ENV="${READER_ENV:-${HOME}/adx-lab-m01/reader.env}"
      LAB_SUBDIR="m01"
      ;;
    m02)
      BUCKET="adx-classroom-cloudtrail"
      PREFIX="AWSLogs/${account}/CloudTrail/${REGION}/"
      SUFFIX=".json.gz"
      TABLE="CloudTrailRaw"
      MAPPING="CT_Raw_Mapping"
      FORMAT="multijson"
      READER_ENV="${READER_ENV:-${HOME}/adx-lab-m02/reader.env}"
      LAB_SUBDIR="m02"
      ;;
    m03)
      BUCKET="adx-cw-firehose-${LOGIN}"
      PREFIX=""
      SUFFIX=""
      TABLE="CloudWatchLogs"
      MAPPING="CW_Mapping"
      FORMAT="multijson"
      READER_ENV="${READER_ENV:-${HOME}/adx-lab-m03/reader.env}"
      LAB_SUBDIR="m03"
      ;;
    m08)
      BUCKET="adx-classroom-guardduty-export"
      PREFIX="guardduty/"
      SUFFIX=""
      TABLE="GuardDutyFindings"
      MAPPING="GD_Mapping"
      FORMAT="multijson"
      READER_ENV="${READER_ENV:-${HOME}/adx-lab-m08/reader.env}"
      LAB_SUBDIR="m08"
      ;;
    *)
      echo "Unknown --module ${MODULE} (use m01, m02, m03, m08)" >&2
      exit 1
      ;;
  esac
}

if [ -n "$MODULE" ]; then
  apply_preset
else
  : "${BUCKET:?Pass --module or --bucket}"
  : "${TABLE:?Pass --table for custom mode}"
  : "${MAPPING:?Pass --mapping for custom mode}"
  : "${FORMAT:?Pass --format for custom mode}"
  READER_ENV="${READER_ENV:-${HOME}/adx-lab-s3/reader.env}"
  LAB_SUBDIR="custom"
fi

LAB_DIR="${HOME}/adx-lab-s3/${LAB_SUBDIR}"
OUT_KQL="${LAB_DIR}/ingest_generated.kql"
OUT_KEYS="${LAB_DIR}/ingest_keys.txt"
mkdir -p "$LAB_DIR"

load_reader_keys() {
  if [ -f "$READER_ENV" ]; then
    # shellcheck disable=SC1090
    set -a; source "$READER_ENV"; set +a
  fi
  READER_ACCESS_KEY_ID="${READER_ACCESS_KEY_ID:-${M01_READER_ACCESS_KEY_ID:-${M02_READER_ACCESS_KEY_ID:-${M03_READER_ACCESS_KEY_ID:-${M08_READER_ACCESS_KEY_ID:-}}}}}"
  READER_SECRET_ACCESS_KEY="${READER_SECRET_ACCESS_KEY:-${M01_READER_SECRET_ACCESS_KEY:-${M02_READER_SECRET_ACCESS_KEY:-${M03_READER_SECRET_ACCESS_KEY:-${M08_READER_SECRET_ACCESS_KEY:-}}}}}"
  : "${READER_ACCESS_KEY_ID:?Create ${READER_ENV} with reader access keys}"
  : "${READER_SECRET_ACCESS_KEY:?Missing reader secret in ${READER_ENV}}"
}

list_keys() {
  aws s3api list-objects-v2 \
    --bucket "$BUCKET" \
    --prefix "$PREFIX" \
    --query 'sort_by(Contents,&LastModified)[*].Key' \
    --output text | tr '\t' '\n' | sed '/^$/d' | while read -r key; do
      if [ -z "$SUFFIX" ] || [[ "$key" == *"$SUFFIX" ]]; then
        echo "$key"
      fi
    done | tail -n "$MAX_FILES"
}

build_ingest_line() {
  local table=$1 key=$2 fmt=$3 map=$4
  printf '.ingest into table %s\nh@"https://%s.s3.%s.amazonaws.com/%s;AwsCredentials=%s,%s"\nwith (format="%s", ingestionMappingReference="%s")\n' \
    "$table" "$BUCKET" "$REGION" "$key" "$READER_ACCESS_KEY_ID" "$READER_SECRET_ACCESS_KEY" "$fmt" "$map"
}

write_m01_kql() {
  {
    echo "// Generated $(date -u +%Y-%m-%dT%H:%M:%SZ) ingest_s3_to_adx.sh --module m01"
    build_ingest_line "AppLogs_JSON" "aws_api_logs.ndjson" "json" "JSON_Mapping"
    echo ""
    build_ingest_line "AppLogs_CSV" "aws_regions.csv" "csv" "CSV_Mapping"
    echo ""
    echo "AppLogs_JSON | count"
    echo "AppLogs_CSV | count"
  } > "$OUT_KQL"
  printf 'aws_api_logs.ndjson\naws_regions.csv\n' > "$OUT_KEYS"
}

write_multi_kql() {
  mapfile -t KEYS < <(list_keys)
  if [ "${#KEYS[@]}" -eq 0 ] || [ -z "${KEYS[0]:-}" ]; then
    echo "No objects under s3://${BUCKET}/${PREFIX} (suffix=${SUFFIX:-any})" >&2
    exit 1
  fi
  printf '%s\n' "${KEYS[@]}" > "$OUT_KEYS"
  {
    echo "// Generated $(date -u +%Y-%m-%dT%H:%M:%SZ) ingest_s3_to_adx.sh --module ${MODULE:-custom}"
    echo "// Files: ${#KEYS[@]}  Database: ADXTrainingDB_${LOGIN}"
    echo ""
    echo -n ".ingest into table ${TABLE} ("
    local first=1 key
    for key in "${KEYS[@]}"; do
      [ "$first" -eq 1 ] || echo -n ","
      first=0
      printf '\n  h@"https://%s.s3.%s.amazonaws.com/%s;AwsCredentials=%s,%s"' \
        "$BUCKET" "$REGION" "$key" "$READER_ACCESS_KEY_ID" "$READER_SECRET_ACCESS_KEY"
    done
    echo ""
    echo ")"
    echo "with (format=\"${FORMAT}\", ingestionMappingReference=\"${MAPPING}\")"
    echo ""
    echo "${TABLE} | count"
  } > "$OUT_KQL"

  if [ "$MODULE" = "m02" ]; then
    cat >> "$OUT_KQL" <<KQL

.set-or-append CloudTrailEvents <|
CloudTrailRaw
| mv-expand Record = Records
| project
    EventTime = todatetime(Record.eventTime),
    EventName = tostring(Record.eventName),
    EventSource = tostring(Record.eventSource),
    AwsRegion = tostring(Record.awsRegion),
    SourceIP = tostring(Record.sourceIPAddress),
    UserAgent = tostring(Record.userAgent),
    UserIdentityType = tostring(Record.userIdentity.type),
    UserArn = tostring(Record.userIdentity.arn),
    AccountId = tostring(Record.userIdentity.accountId),
    ReadOnly = tobool(Record.readOnly),
    ErrorCode = tostring(Record.errorCode),
    RequestParameters = Record.requestParameters,
    ResponseElements = Record.responseElements,
    RawRecord = Record

CloudTrailEvents | count
CloudTrailEvents | where UserArn contains "${LOGIN}" | summarize n = count() by EventName | order by n desc | take 10
KQL
  fi

  if [ "$MODULE" = "m08" ]; then
    cat >> "$OUT_KQL" <<KQL

GuardDutyFindings | count
GuardDutyFindings | summarize n = count() by FindingType | order by n desc
KQL
  fi

  if [ "$MODULE" = "m03" ]; then
    cat >> "$OUT_KQL" <<KQL

CloudWatchLogs | where messageType == "DATA_MESSAGE" | count
KQL
  fi
}

run_adx() {
  local db="ADXTrainingDB_${LOGIN}"
  export ADX_DATABASE="$db"
  export ADX_CLUSTER_URI="$CLUSTER"
  if [ ! -f "$KUSTO_PY" ]; then
    echo "Missing ${KUSTO_PY}" >&2
    exit 1
  fi
  if ! command -v az >/dev/null 2>&1 && [ -z "${AZ_CMD:-}" ]; then
    echo "--run requires Azure CLI (az login). Generated KQL only: ${OUT_KQL}" >&2
    exit 1
  fi
  echo "Running ingest against ${db} on ${CLUSTER} ..."
  if command -v python >/dev/null 2>&1; then
    PYTHON=python
  elif command -v python3 >/dev/null 2>&1; then
    PYTHON=python3
  else
    echo "Python not found (required for --run)" >&2
    exit 1
  fi
  # Git Bash: avoid c:\c\... when Python opens ASSETS_DIR paths
  (cd "$ROOT" && "$PYTHON" "assets/common/kusto_cmd.py" run-file "$OUT_KQL" --database "$db" --cluster "$CLUSTER")
}

load_reader_keys

echo "S3 source: s3://${BUCKET}/${PREFIX} (max ${MAX_FILES} objects)"

if [ "$MODULE" = "m01" ]; then
  write_m01_kql
else
  write_multi_kql
fi

echo "Wrote $(wc -l < "$OUT_KEYS" | tr -d ' ') key(s) -> ${OUT_KEYS}"
echo "Wrote KQL -> ${OUT_KQL}"

if [ "$RUN" -eq 1 ]; then
  run_adx
  echo "ADX ingest complete."
else
  echo ""
  echo "Paste ${OUT_KQL} into ADX Web UI on ADXTrainingDB_${LOGIN}, or re-run with --run (requires az login)."
fi
