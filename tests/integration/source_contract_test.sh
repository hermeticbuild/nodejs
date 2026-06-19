#!/usr/bin/env bash
set -euo pipefail

metadata="$1"
configure="$2"
common_gypi="$3"
node_gyp="$4"

grep -F '"release": "26.3.1"' "$metadata"
grep -F '"node_module_version": 147' "$metadata"
grep -F '"v8_version": "14.6.202.34"' "$metadata"
grep -F '"uv_version": "1.52.1"' "$metadata"

grep -F "parser = argparse.ArgumentParser()" "$configure"
grep -F "'v8_embedder_string': '-node.20'" "$common_gypi"
grep -F "'node_sources': [" "$node_gyp"
