#!/usr/bin/env bash
# Сборка, модульные и UI-тесты в симуляторах iPhone и iPad; скриншоты складываются в ./screenshots
set -euo pipefail
cd "$(dirname "$0")/.."

xcodegen generate

pick() {  # первый доступный симулятор, имя которого начинается с $1
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
IPHONE=$(pick "iPhone 16 Pro")
[ -z "$IPHONE" ] && IPHONE=$(pick "iPhone")
IPAD=$(pick "iPad Pro 13")
[ -z "$IPAD" ] && IPAD=$(pick "iPad")
echo "iPhone: $IPHONE  iPad: $IPAD"

for UDID in "$IPHONE" "$IPAD"; do
  xcrun simctl boot "$UDID" || true
  # русский язык и регион для системных элементов интерфейса
  xcrun simctl spawn "$UDID" defaults write "Apple Global Domain" AppleLanguages -array ru
  xcrun simctl spawn "$UDID" defaults write "Apple Global Domain" AppleLocale -string ru_RU
  xcrun simctl status_bar "$UDID" override --time "9:41" --batteryState charged --batteryLevel 100 --cellularBars 4 --wifiBars 3 || true
done

mkdir -p screenshots build
export TEST_RUNNER_SCREENSHOT_DIR="$PWD/screenshots"

set +e
xcodebuild test   -project InventoryQR.xcodeproj   -scheme InventoryQR   -destination "id=$IPHONE"   -destination "id=$IPAD"   -parallel-testing-enabled NO   -resultBundlePath build/Tests.xcresult   CODE_SIGNING_ALLOWED=NO > build/xcodebuild.log 2>&1
STATUS=$?
set -e
grep -E "(error:|Test Case .*(passed|failed)|Executed [0-9]+ test|\*\* TEST)" build/xcodebuild.log | tail -80 || true
exit $STATUS
