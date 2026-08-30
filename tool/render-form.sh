#!/bin/sh
# Render page 1 of a bundled permit form so it can be read.
#
# The register said auditing the wizards against these forms needed "someone
# who can open a PDF". It needs `qlmanage`, which every Mac has. There is no
# poppler and no Homebrew on this machine, so this renders the FIRST PAGE ONLY
# — enough for Boxes 1 to 5 on most of these forms, which is where the
# applicant-entered fields live, and not enough for the later boxes.
#
#   tool/render-form.sh Fencing-Permit-Form
#
# Writes a PNG beside the form under the system temp directory and prints its
# path.
set -eu
name="${1:?usage: tool/render-form.sh <form-basename-without-.pdf>}"
src="assets/permits/${name}.pdf"
[ -f "$src" ] || { echo "no such form: $src" >&2; exit 1; }
out="${TMPDIR:-/tmp}/ebpco-forms"
mkdir -p "$out"
qlmanage -t -s 2400 -o "$out" "$src" >/dev/null 2>&1
echo "$out/${name}.pdf.png"
