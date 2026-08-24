#!/usr/bin/env bash
set -euo pipefail

grep -Fx 'v26.3.1' "$1"
