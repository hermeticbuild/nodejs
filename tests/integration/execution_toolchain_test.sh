#!/usr/bin/env bash
set -euo pipefail

grep -Fx 'v26.13.0' "$1"
