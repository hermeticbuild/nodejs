#!/usr/bin/env bash
set -euo pipefail

snapshot_source="$1"

[[ "$(wc -c < "$snapshot_source")" -gt 10000000 ]]
grep -Fq 'static const char *v8_snapshot_blob_data' "$snapshot_source"
grep -Fq 'const SnapshotData snapshot_data' "$snapshot_source"
grep -Fq 'SnapshotBuilder::GetEmbeddedSnapshotData()' "$snapshot_source"
