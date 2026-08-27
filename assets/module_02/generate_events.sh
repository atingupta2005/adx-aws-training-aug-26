#!/usr/bin/env bash
# Module 02 — generate CloudTrail-visible API activity.
# Usage: bash assets/module_02/generate_events.sh <region> <your-login>
set -euo pipefail
REGION="${1:?region, e.g. us-east-1}"
INIT="${2:?Pass your login, e.g. u01}"
ACTIVITY_BUCKET="adx-ct-activity-${INIT}"
if [ "$REGION" = "us-east-1" ]; then
  aws s3api create-bucket --bucket "$ACTIVITY_BUCKET" --region "$REGION"
else
  aws s3api create-bucket --bucket "$ACTIVITY_BUCKET" --region "$REGION" \
    --create-bucket-configuration LocationConstraint="$REGION"
fi
aws s3api delete-bucket --bucket "$ACTIVITY_BUCKET" --region "$REGION"
aws iam create-user --user-name "ct-lab-user-${INIT}"
aws iam delete-user --user-name "ct-lab-user-${INIT}"
aws sts get-caller-identity
aws s3api list-buckets
aws ec2 describe-regions --region "$REGION"
echo "Activity generated. A new trail object can take 5–15 minutes."
