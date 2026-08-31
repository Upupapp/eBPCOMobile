#!/usr/bin/env bash
# One command, one answer.
#
# Written after a run of `flutter test` timed out during a disk-full incident,
# and that single occurrence was generalised into "the suite has outgrown a
# ten-minute invocation". It had not: the full suite is about two minutes warm.
# What the episode actually cost was three ad-hoc group runs whose exit codes
# were read off wrapped log lines, and one of those readings was wrong.
#
# So the point of this script is not speed. It is that verification produces a
# single unambiguous verdict rather than three tails to squint at.
set -u

cd "$(dirname "$0")/.."

fail=0
line() { printf '%-28s %s\n' "$1" "$2"; }

start=$(date +%s)

analyze_out=$(flutter analyze 2>&1)
if printf '%s' "$analyze_out" | grep -q 'No issues found'; then
  line "flutter analyze" "clean"
else
  line "flutter analyze" "ISSUES"
  printf '%s\n' "$analyze_out" | grep '•' | head -20
  fail=1
fi

# Run once in MOCK mode (the default) and once in LIVE mode.
#
# The live half is not a duplicate. `--dart-define=EBPCO_API_BASE_URL` is a
# compile-time constant, so the branch that reads it does not exist in a
# default build — every test in the suite runs against a build where
# `AppConfig.useLiveBackend` is const false. A define that stopped reaching
# `AppConfig` would pass the whole suite and ship fabricated data. B-1.
live_out=$(flutter test test/core/config/live_mode_define_test.dart \
  --dart-define=EBPCO_API_BASE_URL=https://api.example.gov.ph 2>&1)
live_code=$?

test_out=$(flutter test 2>&1)
test_code=$?
passed=$(printf '%s' "$test_out" | grep -oE '\+[0-9]+: All tests passed' | grep -oE '[0-9]+' | tail -1)
overflows=$(printf '%s' "$test_out" | grep -c 'overflowed by')

if [ "$live_code" -eq 0 ]; then
  line "live-mode define" "reaches the repositories"
else
  line "live-mode define" "FAILED"
  printf '%s\n' "$live_out" | grep -E '\[E\]$' | head -5
  fail=1
fi

if [ "$test_code" -eq 0 ]; then
  line "flutter test" "${passed:-?} passed"
  # Stamped so a document that QUOTES this number can be checked against a
  # measurement rather than against a plausibility range. The certification
  # gate used to assert only `> 1400`, which its own comment described as
  # comparing against what `flutter test` reports; it did not, and the
  # document went 608 tests stale without the gate noticing.
  printf '%s\n' "${passed:-0}" > test/contract/suite-count.txt
else
  line "flutter test" "FAILED"
  printf '%s\n' "$test_out" | grep -E '\[E\]$' | sed 's/.*dart: //;s/ \[E\]//' | sort -u | head -20
  fail=1
fi

if [ "$overflows" -eq 0 ]; then
  line "layout overflows" "0"
else
  line "layout overflows" "$overflows  <-- these do not fail a test on their own"
  fail=1
fi

line "wall time" "$(( $(date +%s) - start ))s"
echo
if [ "$fail" -eq 0 ]; then
  echo "VERIFIED"
else
  echo "NOT VERIFIED"
fi
exit "$fail"
