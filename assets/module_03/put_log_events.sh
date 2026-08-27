#!/usr/bin/env bash
# Module 03 — write three live identity-shaped events into your log stream.
# Usage: bash assets/module_03/put_log_events.sh <region> <your-login>
# Git Bash: export MSYS_NO_PATHCONV=1 first. Do not run until the subscription filter exists.
set -euo pipefail
export MSYS_NO_PATHCONV=1
REGION="${1:?region}"
INIT="${2:?Pass your login, e.g. u01}"
LOG_GROUP="/adx-training/app-logs-${INIT}"
LOG_STREAM="Instance_01_${INIT}"
LAB_DIR="$HOME/adx-lab-m03"
mkdir -p "$LAB_DIR"
EVENTS_JSON="$LAB_DIR/cw_log_events.json"
command -v cygpath >/dev/null && EVENTS_JSON="$(cygpath -m "$EVENTS_JSON")"
ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
ARN=$(aws sts get-caller-identity --query Arn --output text)
export ACCOUNT ARN EVENTS_JSON
PYTHON=python3
python3 -c "import json" 2>/dev/null || PYTHON=python
"$PYTHON" <<'PY'
import json, os, time
ts = int(time.time() * 1000)
acct, arn = os.environ["ACCOUNT"], os.environ["ARN"]
def msg(level, text):
    return json.dumps({"level": level, "accountId": acct, "arn": arn, "msg": text})
events = [
    {"timestamp": ts, "message": msg("INFO", "sts get-caller-identity")},
    {"timestamp": ts + 1, "message": msg("INFO", "s3 list-buckets")},
    {"timestamp": ts + 2, "message": msg("WARN", "iam identity-probe")},
]
with open(os.environ["EVENTS_JSON"], "w") as f:
    json.dump(events, f)
print("wrote", len(events), "events")
PY
URI="file://$EVENTS_JSON"
command -v cygpath >/dev/null && URI="file://$(cygpath -m "$EVENTS_JSON")"
aws logs put-log-events --region "$REGION" --log-group-name "$LOG_GROUP" \
  --log-stream-name "$LOG_STREAM" --log-events "$URI"
echo "Wait 60–90 seconds, then list s3://adx-cw-firehose-${INIT}/"
