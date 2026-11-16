#!/bin/sh
# Host test for scripts/write-part.sh: the Part file GFOpenUpTool reads.
# Copyright (c) 2026 AmiCradle Team. GPL 3 or later, like MilkyTracker.
set -eu
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
D="$T/Utilities/MilkyTracker"; mkdir -p "$D/Songs" "$D/Docs"
: > "$D/MilkyTracker"; : > "$D/Songs/milky.xm"; : > "$D/Docs/MilkyTracker.html"
sh "$HERE/../scripts/write-part.sh" "$T" 1.05.01
fail=0
expect() { grep -qxF "$1" "$T/Part" || { echo "FAIL: no line: $1"; fail=1; }; }
expect 'part MilkyTracker 1.05.01'
expect 'needs 68040'
expect 'needs part GFOpenGPU'
expect 'copy "Utilities/MilkyTracker/MilkyTracker" "SYS:Utilities/MilkyTracker/MilkyTracker"'
expect 'copy "Utilities/MilkyTracker/Songs/milky.xm" "SYS:Utilities/MilkyTracker/Songs/milky.xm"'
expect 'copy "Utilities/MilkyTracker/Docs/MilkyTracker.html" "SYS:Utilities/MilkyTracker/Docs/MilkyTracker.html"'
[ "$(head -1 "$T/Part")" = 'part MilkyTracker 1.05.01' ] || { echo "FAIL: first line"; fail=1; }
[ "$(grep -c '^copy' "$T/Part")" = 3 ] || { echo "FAIL: copy count (the Part file itself must not be listed)"; fail=1; }
sh "$HERE/../scripts/write-part.sh" "$T" 1.05.01   # a second run: same file
[ "$(grep -c '^copy' "$T/Part")" = 3 ] || { echo "FAIL: second run lists the Part file"; fail=1; }
[ $fail = 0 ] && echo "Part file: all checks passed"
exit $fail
