#!/usr/bin/env bash
# Module 03 — simulate realistic application traffic into YOUR CloudWatch log group.
#
# This is what a small microservice would emit (orders, auth, inventory, latency),
# written via PutLogEvents — the same API apps use when they log to CloudWatch directly.
#
# Prerequisites (lab Step 1 done):
#   - Log group + stream exist
#   - Firehose Active + subscription filter already created
#
# Usage:
#   export MSYS_NO_PATHCONV=1
#   bash assets/module_03/app_traffic_simulator.sh us-east-1 <your-login> [batch-count]
#
# Examples:
#   bash assets/module_03/app_traffic_simulator.sh us-east-1 u01
#   bash assets/module_03/app_traffic_simulator.sh us-east-1 u01 3
#
# Quick test (3 probe lines only): put_log_events.sh
set -euo pipefail
export MSYS_NO_PATHCONV=1

REGION="${1:?region, e.g. us-east-1}"
INIT="${2:?Pass your login, e.g. u01}"
BATCHES="${3:-2}"

LOG_GROUP="/adx-training/app-logs-${INIT}"
LOG_STREAM="Instance_01_${INIT}"
LAB_DIR="$HOME/adx-lab-m03"
mkdir -p "$LAB_DIR"
EVENTS_JSON="$LAB_DIR/app_traffic_events.json"
command -v cygpath >/dev/null && EVENTS_JSON="$(cygpath -m "$EVENTS_JSON")"

ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
ARN=$(aws sts get-caller-identity --query Arn --output text)
export ACCOUNT ARN EVENTS_JSON INIT BATCHES

PYTHON=python3
python3 -c "import json" 2>/dev/null || PYTHON=python

"$PYTHON" <<'PY'
import json, os, random, time, uuid

acct = os.environ["ACCOUNT"]
arn = os.environ["ARN"]
login = os.environ["INIT"]
batches = max(1, int(os.environ["BATCHES"]))
service = f"checkout-api-{login}"
host = f"ip-10-0-1-{random.randint(10, 90)}.ec2.internal"

def line(level, event, **extra):
    body = {
        "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "level": level,
        "service": service,
        "host": host,
        "accountId": acct,
        "callerArn": arn,
        "event": event,
        "traceId": str(uuid.uuid4()),
    }
    body.update(extra)
    return json.dumps(body, separators=(",", ":"))

scenarios = [
    ("INFO", "http.request", {"method": "GET", "path": "/health", "status": 200, "latencyMs": random.randint(3, 18)}),
    ("INFO", "auth.login.success", {"userId": f"cust-{random.randint(1000,9999)}", "method": "password"}),
    ("WARN", "auth.login.failed", {"userId": f"cust-{random.randint(1000,9999)}", "reason": "invalid_password", "status": 401}),
    ("INFO", "order.created", {"orderId": f"ord-{uuid.uuid4().hex[:8]}", "sku": "SKU-WIDGET-42", "qty": random.randint(1, 4), "amountUsd": round(random.uniform(19.99, 249.5), 2)}),
    ("INFO", "payment.authorized", {"orderId": f"ord-{uuid.uuid4().hex[:8]}", "provider": "stripe", "latencyMs": random.randint(80, 420)}),
    ("ERROR", "inventory.reserve.failed", {"sku": "SKU-WIDGET-42", "reason": "stock_out", "status": 409}),
    ("INFO", "http.request", {"method": "POST", "path": "/v1/orders", "status": 201, "latencyMs": random.randint(45, 260)}),
    ("WARN", "http.request", {"method": "GET", "path": "/v1/orders/slow", "status": 200, "latencyMs": random.randint(1200, 2800)}),
]

events = []
base = int(time.time() * 1000)
i = 0
for _ in range(batches):
    random.shuffle(scenarios)
    for level, event, extra in scenarios:
        events.append({"timestamp": base + i, "message": line(level, event, **extra)})
        i += 1
    # small gap between “minutes” of traffic
    base += 1000

path = os.environ["EVENTS_JSON"]
with open(path, "w", encoding="utf-8") as f:
    json.dump(events, f)
print(f"wrote {len(events)} application log lines -> {path}")
print(f"service={service} host={host}")
PY

URI="file://$EVENTS_JSON"
command -v cygpath >/dev/null && URI="file://$(cygpath -m "$EVENTS_JSON")"

TOKEN=$(aws logs describe-log-streams --region "$REGION" \
  --log-group-name "$LOG_GROUP" \
  --log-stream-name-prefix "$LOG_STREAM" \
  --query 'logStreams[0].uploadSequenceToken' --output text 2>/dev/null || true)

ARGS=(--region "$REGION" --log-group-name "$LOG_GROUP" --log-stream-name "$LOG_STREAM" --log-events "$URI")
if [ -n "${TOKEN:-}" ] && [ "$TOKEN" != "None" ] && [ "$TOKEN" != "null" ]; then
  ARGS+=(--sequence-token "$TOKEN")
fi

aws logs put-log-events "${ARGS[@]}"
echo ""
echo "Sent realistic checkout-api traffic to ${LOG_GROUP} / ${LOG_STREAM}"
echo "Wait 60–90 seconds (Firehose buffer), then:"
echo "  aws s3 ls s3://adx-cw-firehose-${INIT}/ --recursive"
echo "In CloudWatch console: Log groups → your group → Log stream → verify INFO/WARN/ERROR lines."
