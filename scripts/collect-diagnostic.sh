#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPORT_DIR="${SCRIPT_DIR}/reports"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

mkdir -p "$REPORT_DIR"

echo "=== Tablet Diagnostic - Multi-Device ADB Collector ==="
echo "Timestamp: $TIMESTAMP"
echo ""

# Ensure ADB server is running
adb start-server 2>/dev/null || true

# Get list of all connected devices
DEVICES=$(adb devices -l | tail -n +2 | grep -v "^$" | awk '{print $1}')

if [ -z "$DEVICES" ]; then
    echo "ERROR: No ADB devices found. Connect tablets via USB or TCP/IP."
    exit 1
fi

DEVICE_COUNT=$(echo "$DEVICES" | wc -l | tr -d ' ')
echo "Found $DEVICE_COUNT device(s):"
echo "$DEVICES" | while read -r serial; do
    INFO=$(adb -s "$serial" devices -l 2>/dev/null | grep "^$serial" || echo "$serial")
    echo "  - $INFO"
done
echo ""

for SERIAL in $DEVICES; do
    echo "--- Processing device: $SERIAL ---"

    # Get device info via ADB
    MANUFACTURER=$(adb -s "$SERIAL" shell getprop ro.product.manufacturer 2>/dev/null || echo "")
    MODEL=$(adb -s "$SERIAL" shell getprop ro.product.model 2>/dev/null || echo "")
    ANDROID_VERSION=$(adb -s "$SERIAL" shell getprop ro.build.version.release 2>/dev/null || echo "")
    SDK_VERSION=$(adb -s "$SERIAL" shell getprop ro.build.version.sdk 2>/dev/null || echo "")
    DEVICE_NAME=$(adb -s "$SERIAL" shell getprop ro.product.name 2>/dev/null || echo "")

    # Battery info
    BATTERY_INFO=$(adb -s "$SERIAL" shell dumpsys battery 2>/dev/null || echo "")
    BATTERY_LEVEL=$(echo "$BATTERY_INFO" | grep "level:" | head -1 | awk '{print $2}')
    BATTERY_PLUGGED=$(echo "$BATTERY_INFO" | grep "AC powered:\|USB powered:\|Wireless powered:" | grep -c "true" || echo "0")
    if [ "$BATTERY_PLUGGED" -gt 0 ] 2>/dev/null; then
        BATTERY_PLUGGED="true"
    else
        BATTERY_PLUGGED="false"
    fi
    [ -z "$BATTERY_LEVEL" ] && BATTERY_LEVEL="null"

    # Network info
    NETWORK_TYPE=$(adb -s "$SERIAL" shell dumpsys connectivity 2>/dev/null | grep -A5 "NetworkAgentInfo" | head -20 || echo "")
    NETWORK_ONLINE=$(adb -s "$SERIAL" shell ping -c 1 8.8.8.8 2>/dev/null && echo "true" || echo "false")

    # Screen info
    SCREEN_SIZE=$(adb -s "$SERIAL" shell wm size 2>/dev/null || echo "")
    SCREEN_DENSITY=$(adb -s "$SERIAL" shell wm density 2>/dev/null || echo "")
    SCREEN_WIDTH=$(echo "$SCREEN_SIZE" | grep -oE '[0-9]+x[0-9]+' | head -1 | cut -d'x' -f1)
    SCREEN_HEIGHT=$(echo "$SCREEN_SIZE" | grep -oE '[0-9]+x[0-9]+' | head -1 | cut -d'x' -f2)
    if [ -z "$SCREEN_DENSITY" ]; then
        SCREEN_DENSITY=1.0
    else
        SCREEN_DENSITY=$(echo "$SCREEN_DENSITY" | grep -oE '[0-9]+' | head -1)
        SCREEN_DENSITY=$(echo "scale=1; $SCREEN_DENSITY / 160" | bc 2>/dev/null || echo "1.0")
    fi

    # Storage info
    STORAGE_INFO=$(adb -s "$SERIAL" shell df /data 2>/dev/null || echo "")
    STORAGE_TOTAL=$(echo "$STORAGE_INFO" | tail -1 | awk '{print $2}')
    STORAGE_FREE=$(echo "$STORAGE_INFO" | tail -1 | awk '{print $3}')
    # Convert from KB to bytes
    if [ -n "$STORAGE_TOTAL" ]; then
        STORAGE_TOTAL=$((STORAGE_TOTAL * 1024))
    else
        STORAGE_TOTAL=""
    fi
    if [ -n "$STORAGE_FREE" ]; then
        STORAGE_FREE=$((STORAGE_FREE * 1024))
    else
        STORAGE_FREE=""
    fi

    # Build JSON report for this device
    SAFE_SERIAL=$(echo "$SERIAL" | sed 's/[^a-zA-Z0-9_-]/_/g')
    REPORT_FILE="${REPORT_DIR}/report_${SAFE_SERIAL}_${TIMESTAMP}.json"

    cat > "$REPORT_FILE" <<JSONEOF
{
  "generatedAt": "${TIMESTAMP}",
  "device": {
    "manufacturer": "${MANUFACTURER:-}",
    "model": "${MODEL:-}",
    "serial": "${SERIAL}",
    "uuid": null
  },
  "android": {
    "version": "${ANDROID_VERSION:-}",
    "sdk": ${SDK_VERSION:-null},
    "cordovaVersion": null,
    "appVersion": null
  },
  "battery": {
    "level": ${BATTERY_LEVEL:-null},
    "plugged": ${BATTERY_PLUGGED}
  },
  "network": {
    "online": ${NETWORK_ONLINE:-null},
    "type": null
  },
  "display": {
    "width": ${SCREEN_WIDTH:-null},
    "height": ${SCREEN_HEIGHT:-null},
    "pixelRatio": ${SCREEN_DENSITY:-null},
    "orientation": null
  },
  "storage": {
    "totalBytes": ${STORAGE_TOTAL:-null},
    "freeBytes": ${STORAGE_FREE:-null}
  },
  "permissions": {
    "camera": "unknown",
    "microphone": "unknown",
    "notifications": "unknown"
  },
  "adb": {
    "source": "adb -s ${SERIAL}",
    "commandsExecuted": [
      "adb devices -l",
      "adb -s ${SERIAL} shell getprop ro.product.manufacturer",
      "adb -s ${SERIAL} shell getprop ro.product.model",
      "adb -s ${SERIAL} shell getprop ro.build.version.release",
      "adb -s ${SERIAL} shell dumpsys battery",
      "adb -s ${SERIAL} shell wm size",
      "adb -s ${SERIAL} shell wm density",
      "adb -s ${SERIAL} shell df /data"
    ]
  }
}
JSONEOF

    echo "  Report saved to: $REPORT_FILE"
    echo "  Manufacturer: $MANUFACTURER"
    echo "  Model: $MODEL"
    echo "  Android: $ANDROID_VERSION (SDK: $SDK_VERSION)"
    echo "  Battery: $BATTERY_LEVEL% (plugged: $BATTERY_PLUGGED)"
    echo ""
done

echo "=== All reports generated in: $REPORT_DIR ==="
echo ""

# Generate combined report if multiple devices
if [ "$DEVICE_COUNT" -gt 1 ]; then
    COMBINED="${REPORT_DIR}/combined_${TIMESTAMP}.json"
    echo "[" > "$COMBINED"
    FIRST=true
    for SERIAL in $DEVICES; do
        SAFE_SERIAL=$(echo "$SERIAL" | sed 's/[^a-zA-Z0-9_-]/_/g')
        REPORT_FILE=$(ls "${REPORT_DIR}/report_${SAFE_SERIAL}_${TIMESTAMP}.json" 2>/dev/null || true)
        if [ -n "$REPORT_FILE" ]; then
            if [ "$FIRST" = true ]; then
                FIRST=false
            else
                echo "," >> "$COMBINED"
            fi
            cat "$REPORT_FILE" >> "$COMBINED"
        fi
    done
    echo "" >> "$COMBINED"
    echo "]" >> "$COMBINED"
    echo "Combined report saved to: $COMBINED"
fi
