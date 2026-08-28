#!/usr/bin/env python3
"""Run Kusto mgmt/query against the lab ADX cluster (Azure CLI bearer token)."""
from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import urllib.error
import urllib.request
from pathlib import Path


def find_az() -> str:
    if os.environ.get("AZ_CMD"):
        return os.environ["AZ_CMD"]
    w = r"C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin\az.cmd"
    if os.path.isfile(w):
        return w
    az = shutil.which("az")
    if az:
        return az
    raise SystemExit("Azure CLI (az) not found. Install az or set AZ_CMD.")


def token(cluster: str) -> str:
    az = find_az()
    out = subprocess.check_output(
        [az, "account", "get-access-token", "--resource", cluster, "-o", "json"],
        text=True,
    )
    return json.loads(out)["accessToken"]


def post(kind: str, csl: str, cluster: str, database: str) -> dict:
    url = f"{cluster.rstrip('/')}/v1/rest/{kind}"
    body = json.dumps(
        {"db": database, "csl": csl, "properties": {"Options": {"request_readonly": False}}}
    ).encode()
    req = urllib.request.Request(
        url,
        data=body,
        headers={
            "Authorization": f"Bearer {token(cluster)}",
            "Content-Type": "application/json; charset=utf-8",
            "Accept": "application/json",
            "Host": cluster.replace("https://", ""),
        },
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=300) as resp:
            return json.loads(resp.read().decode())
    except urllib.error.HTTPError as e:
        err = e.read().decode("utf-8", "replace")
        raise SystemExit(f"Kusto HTTP {e.code}: {err[:2500]}")


def primary_table(resp: dict):
    tables = resp.get("Tables") or []
    if not tables:
        return []
    cols = [c["ColumnName"] for c in tables[0].get("Columns", [])]
    return [dict(zip(cols, row)) for row in tables[0].get("Rows", [])]


def split_mgmt_commands(text: str) -> list[str]:
    """Split a KQL file into individual mgmt/query statements."""
    parts: list[str] = []
    buf: list[str] = []
    for line in text.splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith("//"):
            continue
        if re.match(r"^[.|]", stripped) and buf:
            parts.append("\n".join(buf))
            buf = [line]
        else:
            buf.append(line)
    if buf:
        parts.append("\n".join(buf))
    return parts


def main():
    ap = argparse.ArgumentParser(description="Run Kusto against lab ADX cluster")
    ap.add_argument("kind", choices=["mgmt", "query", "run-file"])
    ap.add_argument("csl_or_path", help="CSL string, file path, or - for stdin")
    ap.add_argument("--database", default=os.environ.get("ADX_DATABASE"))
    ap.add_argument(
        "--cluster",
        default=os.environ.get(
            "ADX_CLUSTER_URI", "https://adxtrainaug26.centralindia.kusto.windows.net"
        ),
    )
    args = ap.parse_args()
    if not args.database:
        raise SystemExit("Set ADX_DATABASE or pass --database")
    cluster = args.cluster.rstrip("/")

    if args.csl_or_path == "-":
        text = sys.stdin.read()
    elif Path(args.csl_or_path).is_file():
        text = Path(args.csl_or_path).read_text(encoding="utf-8")
    else:
        text = args.csl_or_path

    if args.kind == "run-file":
        commands = split_mgmt_commands(text)
        results = []
        for cmd in commands:
            kind = "mgmt" if cmd.lstrip().startswith(".") else "query"
            resp = post(kind, cmd, cluster, args.database)
            rows = primary_table(resp)
            results.append({"kind": kind, "n": len(rows), "rows": rows[:10]})
        json.dump({"ok": True, "commands": len(commands), "results": results}, sys.stdout, default=str)
        sys.stdout.write("\n")
        return

    resp = post(args.kind, text, cluster, args.database)
    rows = primary_table(resp)
    json.dump({"ok": True, "n": len(rows), "rows": rows[:20]}, sys.stdout, default=str)
    sys.stdout.write("\n")


if __name__ == "__main__":
    main()
