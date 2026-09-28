#!/bin/bash
set -euo pipefail

# Usage: ./scripts/device-list.sh [-l|--long]
# Lists all ADB-connected devices with details.
# Never assumes a single device is connected.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

adb start-server 2>/dev/null || true

OUTPUT_MODE="short"
if [[ "${1:-}" == "-l" || "${1:-}" == "--long" ]]; then
    OUTPUT_MODE="long"
fi

DEVICES=$(adb devices -l 2>/dev/null | tail -n +2 | grep -v "^$" || true)

if [ -z "$DEVICES" ]; then
    echo "No ADB devices found."
    exit 1
fi

COUNT=$(echo "$DEVICES" | wc -l | tr -d ' ')

if [ "$OUTPUT_MODE" = "long" ]; then
    echo "=== ADB Devices ($COUNT found) ==="
    echo ""
    echo "$DEVICES" | while IFS= read -r line; do
        SERIAL=$(echo "$line" | awk '{print $1}')
        MODEL=$(adb -s "$SERIAL" shell getprop ro.product.model 2>/dev/null || echo "unknown")
        MANUFACTURER=$(adb -s "$SERIAL" shell getprop ro.product.manufacturer 2>/dev/null || echo "unknown")
        ANDROID_VER=$(adb -s "$SERIAL" shell getprop ro.build.version.release 2>/dev/null || echo "unknown")
        STATE=$(echo "$line" | awk '{print $2}')
        echo "Serial: $SERIAL"
        echo "  State: $STATE"
        echo "  Model: $MODEL"
        echo "  Manufacturer: $MANUFACTURER"
        echo "  Android: $ANDROID_VER"
        echo ""
    done
else
    echo "$DEVICES"
fi
