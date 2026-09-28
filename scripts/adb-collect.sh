#!/usr/bin/env bash
# Collect diagnostic information for ONE Android device via adb and print a
# JSON report conforming to benchmark/report.schema.json on stdout.
#
# Usage: adb-collect.sh <serial>
#
# Only one device is targeted per invocation (explicit -s <serial>); the
# caller is responsible for iterating over `adb-list-devices.sh` output.
set -euo pipefail

if [ "$#" -ne 1 ]; then
    echo "usage: $0 <serial>" >&2
    exit 2
fi

SERIAL="$1"
PKG="com.diagnostic.app"

if ! adb -s "$SERIAL" get-state >/dev/null 2>&1; then
    echo "error: device '$SERIAL' is not online" >&2
    exit 1
fi

adbsh() { adb -s "$SERIAL" shell "$@"; }

json_str() {
    # Escape backslash and double quote for a JSON string value.
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    printf '"%s"' "$s"
}

json_or_null() {
    local v="$1"
    if [ -z "$v" ]; then
        printf 'null'
    else
        json_str "$v"
    fi
}

prop() { adbsh getprop "$1" | tr -d '\r\n'; }

MANUFACTURER="$(prop ro.product.manufacturer)"
MODEL="$(prop ro.product.model)"
ANDROID_VERSION="$(prop ro.build.version.release)"
SDK="$(prop ro.build.version.sdk)"

BATTERY_RAW="$(adbsh dumpsys battery)"
BATTERY_LEVEL="$(printf '%s\n' "$BATTERY_RAW" | awk '/^  level:/ {print $2; exit}')"
if printf '%s\n' "$BATTERY_RAW" | grep -Eq '^  (AC|USB|Wireless) powered: true'; then
    BATTERY_PLUGGED=true
else
    BATTERY_PLUGGED=false
fi

NETWORK_RAW="$(adbsh dumpsys connectivity)"
if printf '%s\n' "$NETWORK_RAW" | grep -qE '^Active default network: .+'; then
    NETWORK_ONLINE=true
else
    NETWORK_ONLINE=false
fi
NETWORK_TYPE="$(printf '%s\n' "$NETWORK_RAW" | grep -oE 'Transports: [A-Z_]+' | head -1 | awk '{print $2}')"

SIZE_LINE="$(adbsh wm size | tr -d '\r\n')"
if printf '%s' "$SIZE_LINE" | grep -q 'Override size:'; then
    SCREEN_SIZE="$(printf '%s' "$SIZE_LINE" | grep -oE 'Override size: [0-9]+x[0-9]+' | grep -oE '[0-9]+x[0-9]+')"
else
    SCREEN_SIZE="$(printf '%s' "$SIZE_LINE" | grep -oE 'Physical size: [0-9]+x[0-9]+' | grep -oE '[0-9]+x[0-9]+')"
fi
SCREEN_W="${SCREEN_SIZE%x*}"
SCREEN_H="${SCREEN_SIZE#*x}"
if [ "$SCREEN_W" -gt "$SCREEN_H" ] 2>/dev/null; then
    ORIENTATION="landscape"
else
    ORIENTATION="portrait"
fi

DENSITY="$(adbsh wm density | tr -d '\r\n' | grep -oE 'Physical density: [0-9]+' | grep -oE '[0-9]+$')"
if [ -n "$DENSITY" ] && [ "$DENSITY" -gt 0 ] 2>/dev/null; then
    PIXEL_RATIO="$(awk "BEGIN {printf \"%.4f\", $DENSITY / 160}")"
else
    PIXEL_RATIO=""
fi

DF_LINE="$(adbsh df /data | tr -d '\r\n' | tail -1)"
DF_TOTAL_KB="$(printf '%s' "$DF_LINE" | awk '{print $2}')"
DF_FREE_KB="$(printf '%s' "$DF_LINE" | awk '{print $4}')"
if [ -n "$DF_TOTAL_KB" ] && [ "$DF_TOTAL_KB" -gt 0 ] 2>/dev/null; then
    TOTAL_BYTES=$((DF_TOTAL_KB * 1024))
else
    TOTAL_BYTES=""
fi
if [ -n "$DF_FREE_KB" ] && [ "$DF_FREE_KB" -ge 0 ] 2>/dev/null; then
    FREE_BYTES=$((DF_FREE_KB * 1024))
else
    FREE_BYTES=""
fi

APP_VERSION=""
if adbsh pm list packages | grep -q "package:$PKG$"; then
    APP_VERSION="$(adbsh dumpsys package "$PKG" | grep -m1 'versionName=' | sed 's/.*versionName=//' | tr -d '\r\n')"
fi

perm_state() {
    local perm="$1"
    if ! adbsh pm list packages | grep -q "package:$PKG$"; then
        printf 'unknown'
        return
    fi
    local line
    line="$(adbsh dumpsys package "$PKG" | grep -E "android.permission.$perm:" | head -1 | tr -d '\r\n')"
    if [ -z "$line" ]; then
        printf 'unknown'
    elif printf '%s' "$line" | grep -q 'granted=true'; then
        printf 'granted'
    else
        printf 'denied'
    fi
}

PERM_CAMERA="$(perm_state CAMERA)"
PERM_MICROPHONE="$(perm_state RECORD_AUDIO)"
if [ -n "$SDK" ] && [ "$SDK" -lt 33 ] 2>/dev/null; then
    PERM_NOTIFICATIONS="not-applicable"
else
    PERM_NOTIFICATIONS="$(perm_state POST_NOTIFICATIONS)"
fi

GENERATED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

printf '{\n'
printf '  "generatedAt": %s,\n' "$(json_str "$GENERATED_AT")"
printf '  "device": {\n'
printf '    "manufacturer": %s,\n' "$(json_or_null "$MANUFACTURER")"
printf '    "model": %s,\n' "$(json_or_null "$MODEL")"
printf '    "serial": %s,\n' "$(json_str "$SERIAL")"
printf '    "uuid": null\n'
printf '  },\n'
printf '  "android": {\n'
printf '    "version": %s,\n' "$(json_or_null "$ANDROID_VERSION")"
printf '    "sdk": %s,\n' "${SDK:-null}"
printf '    "cordovaVersion": null,\n'
printf '    "appVersion": %s\n' "$(json_or_null "$APP_VERSION")"
printf '  },\n'
printf '  "battery": {\n'
printf '    "level": %s,\n' "${BATTERY_LEVEL:-null}"
printf '    "plugged": %s\n' "$BATTERY_PLUGGED"
printf '  },\n'
printf '  "network": {\n'
printf '    "online": %s,\n' "$NETWORK_ONLINE"
printf '    "type": %s\n' "$(json_or_null "$NETWORK_TYPE")"
printf '  },\n'
printf '  "display": {\n'
printf '    "width": %s,\n' "${SCREEN_W:-null}"
printf '    "height": %s,\n' "${SCREEN_H:-null}"
printf '    "pixelRatio": %s,\n' "${PIXEL_RATIO:-null}"
printf '    "orientation": %s\n' "$(json_str "$ORIENTATION")"
printf '  },\n'
printf '  "storage": {\n'
printf '    "totalBytes": %s,\n' "${TOTAL_BYTES:-null}"
printf '    "freeBytes": %s\n' "${FREE_BYTES:-null}"
printf '  },\n'
printf '  "permissions": {\n'
printf '    "camera": %s,\n' "$(json_str "$PERM_CAMERA")"
printf '    "microphone": %s,\n' "$(json_str "$PERM_MICROPHONE")"
printf '    "notifications": %s\n' "$(json_str "$PERM_NOTIFICATIONS")"
printf '  },\n'
printf '  "adb": {\n'
printf '    "collector": %s,\n' "$(json_str "adb-collect.sh")"
printf '    "screenSizeRaw": %s,\n' "$(json_str "$SIZE_LINE")"
printf '    "density": %s,\n' "${DENSITY:-null}"
printf '    "dfLine": %s,\n' "$(json_str "$DF_LINE")"
printf '    "packageInstalled": %s\n' "$(adbsh pm list packages | grep -q "package:$PKG$" && printf true || printf false)"
printf '  }\n'
printf '}\n'
