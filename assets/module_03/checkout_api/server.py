#!/usr/bin/env python3
"""
Module 03 — tiny checkout HTTP API (real service, not a log generator).

In production, logs appear because the application handled a request.
Same here: start this API, then use curl/browser. Each request logs as a side effect.

Prerequisites:
  - Lab Step 1 done (log group, stream, Firehose, subscription filter)
  - aws configure with your card keys
  - pip install boto3   (once, if missing)

Usage:
  export MSYS_NO_PATHCONV=1
  export ADX_LOGIN=u01          # your login
  export AWS_DEFAULT_REGION=us-east-1
  python assets/module_03/checkout_api/server.py

Then in another terminal (examples):
  curl -s http://127.0.0.1:8080/health
  curl -s -X POST http://127.0.0.1:8080/v1/orders -H "Content-Type: application/json" -d "{\"sku\":\"WIDGET\",\"qty\":2}"
  curl -s -X POST http://127.0.0.1:8080/v1/login -H "Content-Type: application/json" -d "{\"user\":\"alice\",\"password\":\"wrong\"}"
"""
from __future__ import annotations

import json
import os
import random
import time
import uuid
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

try:
    import boto3
    from botocore.exceptions import ClientError
except ImportError as e:
    raise SystemExit("Install boto3 once: pip install boto3") from e

LOGIN = os.environ.get("ADX_LOGIN", "").strip()
if not LOGIN:
    raise SystemExit("Set ADX_LOGIN to your login (e.g. export ADX_LOGIN=u01)")

REGION = os.environ.get("AWS_DEFAULT_REGION", "us-east-1")
LOG_GROUP = f"/adx-training/app-logs-{LOGIN}"
LOG_STREAM = f"Instance_01_{LOGIN}"
PORT = int(os.environ.get("CHECKOUT_PORT", "8080"))
SERVICE = f"checkout-api-{LOGIN}"

logs = boto3.client("logs", region_name=REGION)
_seq_token = None


def _ensure_stream() -> None:
    try:
        logs.create_log_stream(logGroupName=LOG_GROUP, logStreamName=LOG_STREAM)
    except ClientError as e:
        if e.response["Error"]["Code"] not in ("ResourceAlreadyExistsException",):
            raise


def emit(level: str, event: str, **fields) -> None:
    """Application logging — called from request handlers, not from a batch script."""
    global _seq_token
    body = {
        "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "level": level,
        "service": SERVICE,
        "event": event,
        "traceId": str(uuid.uuid4()),
        **fields,
    }
    message = json.dumps(body, separators=(",", ":"))
    kwargs = {
        "logGroupName": LOG_GROUP,
        "logStreamName": LOG_STREAM,
        "logEvents": [{"timestamp": int(time.time() * 1000), "message": message}],
    }
    if _seq_token:
        kwargs["sequenceToken"] = _seq_token
    try:
        resp = logs.put_log_events(**kwargs)
    except ClientError as e:
        code = e.response["Error"]["Code"]
        if code in ("InvalidSequenceTokenException", "DataAlreadyAcceptedException"):
            _seq_token = e.response["Error"].get("expectedSequenceToken") or e.response.get(
                "expectedSequenceToken"
            )
            if not _seq_token:
                streams = logs.describe_log_streams(
                    logGroupName=LOG_GROUP, logStreamNamePrefix=LOG_STREAM, limit=1
                )
                _seq_token = streams["logStreams"][0].get("uploadSequenceToken")
            kwargs["sequenceToken"] = _seq_token
            resp = logs.put_log_events(**kwargs)
        else:
            raise
    _seq_token = resp.get("nextSequenceToken")
    print(f"  log -> {level} {event}", flush=True)


class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):  # quieter access log
        pass

    def _read_json(self):
        length = int(self.headers.get("Content-Length", 0))
        if length <= 0:
            return {}
        return json.loads(self.rfile.read(length).decode("utf-8") or "{}")

    def _send(self, code: int, payload: dict):
        data = json.dumps(payload).encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self):
        started = time.time()
        if self.path.rstrip("/") == "/health":
            latency = int((time.time() - started) * 1000)
            emit("INFO", "http.request", method="GET", path="/health", status=200, latencyMs=latency)
            return self._send(200, {"status": "ok", "service": SERVICE})
        emit("WARN", "http.request", method="GET", path=self.path, status=404, latencyMs=1)
        self._send(404, {"error": "not_found"})

    def do_POST(self):
        started = time.time()
        body = self._read_json()
        path = self.path.rstrip("/")

        if path == "/v1/login":
            user = body.get("user", "unknown")
            ok = body.get("password") == "secret"
            latency = int((time.time() - started) * 1000)
            if ok:
                emit("INFO", "auth.login.success", userId=user, method="password", latencyMs=latency)
                return self._send(200, {"token": "demo-token", "user": user})
            emit(
                "WARN",
                "auth.login.failed",
                userId=user,
                reason="invalid_password",
                status=401,
                latencyMs=latency,
            )
            return self._send(401, {"error": "invalid_password"})

        if path == "/v1/orders":
            sku = body.get("sku", "SKU-WIDGET-42")
            qty = int(body.get("qty", 1))
            if qty > 10:
                emit(
                    "ERROR",
                    "inventory.reserve.failed",
                    sku=sku,
                    reason="stock_out",
                    status=409,
                )
                return self._send(409, {"error": "stock_out"})
            order_id = f"ord-{uuid.uuid4().hex[:8]}"
            amount = round(qty * random.uniform(19.99, 49.99), 2)
            latency = int((time.time() - started) * 1000)
            emit(
                "INFO",
                "order.created",
                orderId=order_id,
                sku=sku,
                qty=qty,
                amountUsd=amount,
                latencyMs=latency,
            )
            emit(
                "INFO",
                "payment.authorized",
                orderId=order_id,
                provider="stripe",
                latencyMs=random.randint(40, 200),
            )
            emit(
                "INFO",
                "http.request",
                method="POST",
                path="/v1/orders",
                status=201,
                latencyMs=latency,
            )
            return self._send(201, {"orderId": order_id, "amountUsd": amount})

        emit("WARN", "http.request", method="POST", path=path, status=404, latencyMs=1)
        self._send(404, {"error": "not_found"})


def main():
    _ensure_stream()
    # seed sequence token if stream already has events
    global _seq_token
    streams = logs.describe_log_streams(
        logGroupName=LOG_GROUP, logStreamNamePrefix=LOG_STREAM, limit=1
    )
    if streams.get("logStreams"):
        _seq_token = streams["logStreams"][0].get("uploadSequenceToken")

    server = ThreadingHTTPServer(("127.0.0.1", PORT), Handler)
    print(f"checkout API listening on http://127.0.0.1:{PORT}", flush=True)
    print(f"logging to {LOG_GROUP} / {LOG_STREAM}", flush=True)
    print("Drive the API with curl/browser — do not run a log-generator script.", flush=True)
    server.serve_forever()


if __name__ == "__main__":
    main()
