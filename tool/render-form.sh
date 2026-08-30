#!/bin/sh
# Render one page of a bundled permit form so it can be read.
#
#   tool/render-form.sh Fencing-Permit-Form        # page 1
#   tool/render-form.sh Fencing-Permit-Form 2      # page 2
#
# Uses PDFKit through JavaScript for Automation, which every Mac ships. There
# is no poppler and no Homebrew on this machine, and `qlmanage` — what this
# script used until 31 August 2026 — renders the FIRST PAGE ONLY. That limit
# was recorded as blocking the audit of the fixture inventories and
# specification tables, which are overleaf. It was not blocking; it was
# unexamined.
#
# Prints the path of the PNG it wrote.
set -eu
name="${1:?usage: tool/render-form.sh <form-basename> [page]}"
page="${2:-1}"
src="assets/permits/${name}.pdf"
[ -f "$src" ] || { echo "no such form: $src" >&2; exit 1; }
out="${TMPDIR:-/tmp}/ebpco-forms"
mkdir -p "$out"
dest="$out/${name}-p${page}.png"
osascript -l JavaScript "$(dirname "$0")/render-pdf-page.js" \
  "$src" "$((page - 1))" "$dest" 2.5 >/dev/null
echo "$dest"
