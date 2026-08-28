#!/usr/bin/env bash
# Re-extract the admin portal's closed vocabularies into the vendored fixture.
#
# Vendored rather than read across a path so `flutter test` works in a checkout
# that has only this repository — but vendoring is only safe if refreshing it
# is one command and the diff is reviewed. Run this whenever the admin moves,
# and commit the result deliberately with the new commit recorded in `source`.
set -euo pipefail

ADMIN="${EBPCO_ADMIN_REPO:-$HOME/ebpco-web/EBPCO WEB ADMIN/E-BPCO-Software-main}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="$ROOT/test/contract/admin-vocabulary.json"

if [ ! -d "$ADMIN/src/app/core/domain" ]; then
  echo "admin portal not found at $ADMIN" >&2
  echo "set EBPCO_ADMIN_REPO to its path" >&2
  exit 1
fi

COMMIT="$(git -C "$ADMIN" rev-parse --short HEAD)"
COMMIT_DATE="$(git -C "$ADMIN" log -1 --format=%ad --date=short)"
TODAY="$(date +%Y-%m-%d)"

node "$ROOT/scripts/extract_admin_vocabulary.mjs" "$ADMIN/src/app/core/domain" \
  > "$ROOT/.admin-vocabulary.tmp"

python3 - "$ROOT/.admin-vocabulary.tmp" "$DEST" "$COMMIT" "$COMMIT_DATE" "$TODAY" <<'PY'
import json, sys, collections
src, dest, commit, commit_date, today = sys.argv[1:6]
data = json.load(open(src), object_pairs_hook=collections.OrderedDict)
out = collections.OrderedDict()
out['_comment'] = (
    'EXTRACTED, not transcribed. Produced by '
    "scripts/extract_admin_vocabulary.mjs from the admin portal's "
    'src/app/core/domain/. Regenerate with scripts/sync_admin_vocabulary.sh '
    'and review the diff: a change here means the admin moved and this app '
    'may no longer speak its language. A fixture edited to make a test pass '
    'is worse than no fixture.'
)
out['source'] = collections.OrderedDict([
    ('repository', 'Upupapp/eBPCO-Web'),
    ('commit', commit),
    ('commitDate', commit_date),
    ('extractedOn', today),
    ('path', 'src/app/core/domain/'),
])
out.update(data)
open(dest, 'w').write(json.dumps(out, indent=2, ensure_ascii=False) + '\n')
PY

rm -f "$ROOT/.admin-vocabulary.tmp"
echo "extracted from $ADMIN @ $COMMIT ($COMMIT_DATE)"
git -C "$ROOT" diff --stat -- test/contract/admin-vocabulary.json || true
