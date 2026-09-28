#!/bin/bash
set -euo pipefail

# Usage: ./scripts/generate-report.sh [SERIAL]
# Generates a diagnostic report for an ADB device.
# If no serial is given, uses the first available device.
# Exits with error if no device is connected or if multiple devices
# are connected and no serial is specified.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

adb start-server 2>/dev/null || true

DEVICES=$(adb devices -l 2>/dev/null | tail -n +2 | grep -v "^$" | awk '{print $1}' || true)

if [ -z "$DEVICES" ]; then
    echo "ERROR: No ADB devices found."
    exit 1
fi

DEVICE_COUNT=$(echo "$DEVICES" | wc -l | tr -d ' ')

if [ "$DEVICE_COUNT" -gt 1 ] && [ -z "${1:-}" ]; then
    echo "ERROR: Multiple devices connected ($DEVICE_COUNT). Please specify a serial."
    echo ""
    echo "Available devices:"
    echo "$DEVICES" | while read -r s; do
        echo "  $s"
    done
    exit 1
fi

if [ -n "${1:-}" ]; then
    SERIAL="$1"
    if ! echo "$DEVICES" | grep -q "^${SERIAL}$"; then
        echo "ERROR: Device with serial '$SERIAL' not found."
        echo "Available devices:"
        echo "$DEVICES" | while read -r s; do
            echo "  $s"
        done
        exit 1
    fi
else
    SERIAL=$(echo "$DEVICES" | head -1)
fi

echo "Generating report for device: $SERIAL"

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
REPORT_DIR="${SCRIPT_DIR}/reports"
mkdir -p "$REPORT_DIR"

# Collect device info
MANUFACTURER=$(adb -s "$SERIAL" shell getprop ro.product.manufacturer 2>/dev/null || echo "")
MODEL=$(adb -s "$SERIAL" shell getprop ro.product.model 2>/dev/null || echo "")
ANDROID_VERSION=$(adb -s "$SERIAL" shell getprop ro.build.version.release 2>/dev/null || echo "")
SDK_VERSION=$(adb -s "$SERIAL" shell getprop ro.build.version.sdk 2>/dev/null || echo "")
UUID=$(adb -s "$SERIAL" shell getprop ro.serialno 2>/dev/null || echo "")

# Battery
BATTERY_LINE=$(adb -s "$SERIAL" shell dumpsys battery 2>/dev/null || echo "")
BATTERY_LEVEL=$(echo "$BATTERY_LINE" | grep "^  level:" | awk '{print $2}')
BATTERY_PLUGGED_LINE=$(echo "$BATTERY_LINE" | grep "AC powered:\|USB powered:\|Wireless powered:" | grep "true" || echo "")
if [ -n "$BATTERY_PLUGGED_LINE" ]; then
    BATTERY_PLUGGED="true"
else
    BATTERY_PLUGGED="false"
fi
[ -z "$BATTERY_LEVEL" ] && BATTERY_LEVEL="null"

# Network
NETWORK_ONLINE="false"
if adb -s "$SERIAL" shell ping -c 1 8.8.8.8 2>/dev/null; then
    NETWORK_ONLINE="true"
fi
NETWORK_TYPE=$(adb -s "$SERIAL" shell getprop gsm.network.type 2>/dev/null || echo "")
if [ -z "$NETWORK_TYPE" ]; then
    NETWORK_TYPE=$(adb -s "$SERIAL" shell dumpsys connectivity 2>/dev/null | grep -oE 'type=\w+' | head -1 | cut -d= -f2 || echo "")
fi

# Display
SCREEN_SIZE=$(adb -s "$SERIAL" shell wm size 2>/dev/null || echo "")
SCREEN_DENSITY=$(adb -s "$SERIAL" shell wm density 2>/dev/null || echo "")
if echo "$SCREEN_SIZE" | grep -qE '[0-9]+x[0-9]+'; then
    SCREEN_WIDTH=$(echo "$SCREEN_SIZE" | grep -oE '[0-9]+x[0-9]+' | head -1 | cut -d'x' -f1)
    SCREEN_HEIGHT=$(echo "$SCREEN_SIZE" | grep -oE '[0-9]+x[0-9]+' | head -1 | cut -d'x' -f2)
else
    SCREEN_WIDTH=""
    SCREEN_HEIGHT=""
fi

# Storage
STORAGE_LINE=$(adb -s "$SERIAL" shell df /data 2>/dev/null || echo "")
STORAGE_TOTAL_KB=$(echo "$STORAGE_LINE" | tail -1 | awk '{print $2}')
STORAGE_FREE_KB=$(echo "$STORAGE_LINE" | tail -1 | awk '{print $3}')
if [ -n "$STORAGE_TOTAL_KB" ]; then
    STORAGE_TOTAL=$((STORAGE_TOTAL_KB * 1024))
else
    STORAGE_TOTAL=""
fi
if [ -n "$STORAGE_FREE_KB" ]; then
    STORAGE_FREE=$((STORAGE_FREE_KB * 1024))
else
    STORAGE_FREE=""
fi

# Permissions via ADB
check_perm() {
    local perm="$1"
    local result=$(adb -s "$SERIAL" shell pm check-permission "$perm" 2>/dev/null || echo "unknown")
    if echo "$result" | grep -q "granted"; then
        echo "granted"
    elif echo "$result" | grep -q "denied"; then
        echo "denied"
    else
        echo "unknown"
    fi
}

CAMERA_PERM=$(check_perm "android.permission.CAMERA")
MICROPHONE_PERM=$(check_perm "android.permission.RECORD_AUDIO")
NOTIFICATIONS_PERM=$(check_perm "android.permission.POST_NOTIFICATIONS")

SAFE_SERIAL=$(echo "$SERIAL" | sed 's/[^a-zA-Z0-9_-]/_/g')
REPORT_FILE="${REPORT_DIR}/device_${SAFE_SERIAL}_${TIMESTAMP}.json"

cat > "$REPORT_FILE" <<JSONEOF
{
  "generatedAt": "${TIMESTAMP}",
  "device": {
    "manufacturer": "${MANUFACTURER:-}",
    "model": "${MODEL:-}",
    "serial": "${SERIAL}",
    "uuid": "${UUID:-}"
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
    "online": ${NETWORK_ONLINE},
    "type": "${NETWORK_TYPE:-null}"
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
    "camera": "${CAMERA_PERM}",
    "microphone": "${MICROPHONE_PERM}",
    "notifications": "${NOTIFICATIONS_PERM}"
  },
  "adb": {
    "serial": "${SERIAL}",
    "commandsExecuted": [
      "adb -s ${SERIAL} shell getprop ro.product.manufacturer",
      "adb -s ${SERIAL} shell getprop ro.product.model",
      "adb -s ${SERIAL} shell getprop ro.build.version.release",
      "adb -s ${SERIAL} shell dumpsys battery",
      "adb -s ${SERIAL} shell wm size",
      "adb -s ${SERIAL} shell wm density",
      "adb -s ${SERIAL} shell df /data",
      "adb -s ${SERIAL} pm check-permission android.permission.CAMERA",
      "adb -s ${SERIAL} pm check-permission android.permission.RECORD_AUDIO",
      "adb -s ${SERIAL} pm check-permission android.permission.POST_NOTIFICATIONS"
    ]
  }
}
JSONEOF

echo "Report saved to: $REPORT_FILE"
cat "$REPORT_FILE"