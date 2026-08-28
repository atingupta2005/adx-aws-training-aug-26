#!/usr/bin/env bash
# Wrapper — use assets/ingest_s3_to_adx.sh --module m02 instead.
exec "$(cd "$(dirname "$0")/../.." && pwd)/assets/ingest_s3_to_adx.sh" --module m02 "$@"
