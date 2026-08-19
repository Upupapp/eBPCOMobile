#!/usr/bin/env bash
# Refresh the vendored contract fixtures from the contract repository.
#
# The fixtures are vendored rather than read across a path so `flutter test`
# works in a checkout that has only this repository -- but vendoring is only
# safe if refreshing it is one command and the diff is reviewed. Run this
# whenever the contract version changes, and commit the result deliberately:
# a diff here means the contract moved and this client may no longer conform.
set -euo pipefail

CONTRACT="${EBPCO_CONTRACT_REPO:-$HOME/ebpco-contract}"
DEST="$(cd "$(dirname "$0")/.." && pwd)/test/contract"

if [ ! -d "$CONTRACT" ]; then
  echo "contract repository not found at $CONTRACT" >&2
  echo "set EBPCO_CONTRACT_REPO to its path" >&2
  exit 1
fi

cp "$CONTRACT/reconciliation/lifecycle-projection.json" "$DEST/lifecycle-projection.json"
echo "synced lifecycle-projection.json from $CONTRACT"
git -C "$(dirname "$DEST")/.." diff --stat -- test/contract || true
