#!/usr/bin/env bash
set -euo pipefail

dbt deps

SRC="dbt_packages/dbt_core/.cursor/rules/dbt.md"
DST=".cursor/rules/dbt.md"

if [ -f "$SRC" ]; then
  mkdir -p .cursor/rules
  cp "$SRC" "$DST"
  echo "Synced Cursor dbt rules from $SRC to $DST"
else
  echo "Source rules file not found: $SRC" >&2
  exit 1
fi