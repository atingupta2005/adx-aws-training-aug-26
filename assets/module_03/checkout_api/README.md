# Tiny checkout API for Module 03

This is a **real HTTP service**. Logs appear because the API handled a request — the same pattern as a microservice in production.

You do **not** run a script whose only job is to push log lines.

## Run the API

```bash
export MSYS_NO_PATHCONV=1
export ADX_LOGIN=<your-login>          # must match your access card (e.g. u01)
export AWS_DEFAULT_REGION=us-east-1
pip install boto3                      # once, if needed
python assets/module_03/checkout_api/server.py
```

On startup the server prints the log group and stream it will use. Both must include **your** login. Leave that terminal open.

## Generate traffic (second terminal or browser)

```bash
# Health check
curl -s http://127.0.0.1:8080/health

# Successful order
curl -s -X POST http://127.0.0.1:8080/v1/orders \
  -H "Content-Type: application/json" \
  -d '{"sku":"WIDGET","qty":2}'

# Stock-out style error
curl -s -X POST http://127.0.0.1:8080/v1/orders \
  -H "Content-Type: application/json" \
  -d '{"sku":"WIDGET","qty":99}'

# Failed login
curl -s -X POST http://127.0.0.1:8080/v1/login \
  -H "Content-Type: application/json" \
  -d '{"user":"alice","password":"wrong"}'

# Successful login
curl -s -X POST http://127.0.0.1:8080/v1/login \
  -H "Content-Type: application/json" \
  -d '{"user":"alice","password":"secret"}'
```

Repeat a few times. Then open CloudWatch → **your** log group `/adx-training/app-logs-<your-login>` → stream `Instance_01_<your-login>` and confirm `order.created`, `auth.login.failed`, etc.

Wait 60–90 seconds for Firehose → list your S3 bucket → peek an object for `"messageType":"DATA_MESSAGE"` (not only `CONTROL_MESSAGE`) → ingest to ADX.
