#!/usr/bin/env bash
# Этапы CI: prepare | build | unit | ui <iphone|ipad>
set -uo pipefail
cd "$(dirname "$0")/.."
mkdir -p build screenshots

pick() {  # UDID самого нового доступного симулятора с именем, начинающимся с $1
  xcrun simctl list devices available -j | python3 -c "
import json,sys,re
d=json.load(sys.stdin)['devices']
best=None
for rt,devs in d.items():
    if 'iOS' not in rt: continue
    ver=tuple(int(x) for x in re.findall(r'(\d+)', rt.split('iOS')[-1])[:2])
    for x in devs:
        if x['name'].startswith('$1'):
            if best is None or ver>best[0]: best=(ver,x['name'],x['udid'])
print(best[2] if best else '')
"
}

device_udid() {
  case "$1" in
    iphone) u=$(pick "iPhone 16 Pro"); [ -z "$u" ] && u=$(pick "iPhone") ;;
    ipad)   u=$(pick "iPad Pro 13"); [ -z "$u" ] && u=$(pick "iPad Pro"); [ -z "$u" ] && u=$(pick "iPad") ;;
  esac
  echo "$u"
}

prepare_sim() {
  local udid=$1
  xcrun simctl boot "$udid" 2>/dev/null || true
  xcrun simctl bootstatus "$udid" -b
  xcrun simctl status_bar "$udid" override --time "9:41" --batteryState charged --batteryLevel 100 --cellularBars 4 --wifiBars 3 || true
}

case "${1:-}" in
  prepare)
    xcodegen generate
    ;;
  build)
    udid=$(device_udid iphone)
    xcodebuild build-for-testing -project MedicineTracker.xcodeproj -scheme MedicineTracker \
      -destination "id=$udid" -derivedDataPath build/DerivedData CODE_SIGNING_ALLOWED=NO \
      > build/build.log 2>&1
    status=$?
    grep -E "error:|warning: .*deprecated|\*\* TEST BUILD" build/build.log | tail -60
    exit $status
    ;;
  unit)
    udid=$(device_udid iphone)
    prepare_sim "$udid"
    xcodebuild test-without-building -project MedicineTracker.xcodeproj -scheme MedicineTracker \
      -destination "id=$udid" -derivedDataPath build/DerivedData \
      -only-testing:MedicineTrackerTests \
      -test-timeouts-enabled YES -default-test-execution-time-allowance 120 \
      > build/unit.log 2>&1
    status=$?
    grep -E "error:|Test Case .*(passed|failed)|Executed [0-9]+ test|\*\* TEST" build/unit.log | tail -80
    exit $status
    ;;
  ui)
    udid=$(device_udid "$2")
    prepare_sim "$udid"
    export TEST_RUNNER_SCREENSHOT_DIR="$PWD/screenshots/$2"
    xcodebuild test-without-building -project MedicineTracker.xcodeproj -scheme MedicineTracker \
      -destination "id=$udid" -derivedDataPath build/DerivedData \
      -only-testing:MedicineTrackerUITests \
      -test-timeouts-enabled YES -default-test-execution-time-allowance 300 \
      -resultBundlePath "build/UI-$2.xcresult" \
      > "build/ui-$2.log" 2>&1
    status=$?
    grep -E "error:|Test Case .*(passed|failed)|Executed [0-9]+ test|\*\* TEST" "build/ui-$2.log" | tail -80
    exit $status
    ;;
  *)
    echo "usage: $0 prepare|build|unit|ui <iphone|ipad>"; exit 2 ;;
esac
