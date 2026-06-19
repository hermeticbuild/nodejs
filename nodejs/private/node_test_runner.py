"""Starts the upstream Node.js test runner."""

import os
import runpy

import utils

# rules_python's system_python launcher sets PYTHONSAFEPATH=1. Upstream Node.js
# tests that start tools/test.py require Python's script-directory import path.
os.environ.pop("PYTHONSAFEPATH", None)
runpy.run_path(
    os.path.join(os.path.dirname(utils.__file__), "test.py"),
    run_name="__main__",
)
