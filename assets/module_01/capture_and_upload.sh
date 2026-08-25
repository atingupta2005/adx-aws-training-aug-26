#!/usr/bin/env bash
# Module 01 — capture live AWS inventory and upload to your lab bucket.
# Usage (Git Bash / WSL / Linux):
#   bash assets/module_01/capture_and_upload.sh <your-initials>
set -euo pipefail
INIT="${1:?Pass your initials, e.g. bash capture_and_upload.sh ag}"
BUCKET="adx-log-ingestion-${INIT}"
WORKDIR="${HOME}/adx-lab-m01"
mkdir -p "$WORKDIR"
cd "$WORKDIR"

OUT_JSON="aws_api_logs.ndjson"
: > "$OUT_JSON"
NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
USER_ID=$(aws sts get-caller-identity --query UserId --output text)
ARN=$(aws sts get-caller-identity --query Arn --output text)
printf '{"timestamp":"%s","level":"INFO","message":"sts Account=%s UserId=%s Arn=%s","service":"sts","host":"%s","requestId":"sts-caller","httpStatus":200}\n' \
  "$NOW" "$ACCOUNT" "$USER_ID" "$ARN" "$ARN" >> "$OUT_JSON"
while IFS= read -r B; do
  [ -z "$B" ] && continue
  printf '{"timestamp":"%s","level":"INFO","message":"s3 BucketName=%s","service":"s3","host":"%s","requestId":"s3-%s","httpStatus":200}\n' \
    "$NOW" "$B" "$B" "$B" >> "$OUT_JSON"
done < <(aws s3api list-buckets --query 'Buckets[].Name' --output text | tr '\t' '\n' | tr -d '\r')
while IFS=$'\t' read -r RNAME ENDPOINT OPTIN; do
  [ -z "$RNAME" ] && continue
  printf '{"timestamp":"%s","level":"INFO","message":"ec2 RegionName=%s","service":"ec2","host":"%s","requestId":"ec2-%s","httpStatus":200}\n' \
    "$NOW" "$RNAME" "$ENDPOINT" "$RNAME" >> "$OUT_JSON"
done < <(aws ec2 describe-regions --all-regions --query 'Regions[].[RegionName,Endpoint,OptInStatus]' --output text | tr -d '\r')

OUT_CSV="aws_regions.csv"
: > "$OUT_CSV"
while IFS=$'\t' read -r RNAME ENDPOINT OPTIN; do
  [ -z "$RNAME" ] && continue
  METRIC=0
  [ "$OPTIN" = "opt-in-not-required" ] && METRIC=1
  LEVEL="INFO"
  [ "$METRIC" -eq 0 ] && LEVEL="WARN"
  printf '%s,%s,RegionName=%s OptInStatus=%s,ec2,%s,%s\n' \
    "$NOW" "$LEVEL" "$RNAME" "$OPTIN" "$ENDPOINT" "$METRIC" >> "$OUT_CSV"
done < <(aws ec2 describe-regions --all-regions --query 'Regions[].[RegionName,Endpoint,OptInStatus]' --output text | tr -d '\r')

echo "Wrote $(wc -l < "$OUT_JSON") NDJSON lines and $(wc -l < "$OUT_CSV") CSV rows in $WORKDIR"
aws s3 cp "$OUT_JSON" "s3://${BUCKET}/aws_api_logs.ndjson"
aws s3 cp "$OUT_CSV" "s3://${BUCKET}/aws_regions.csv"
aws s3 ls "s3://${BUCKET}/"
