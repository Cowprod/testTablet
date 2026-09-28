#!/usr/bin/env bash
# List serials of all Android devices currently visible to adb.
# Prints one serial per line; prints nothing (exit 0) when no device is online.
# Never assumes a single device: 0, 1 or N devices are all valid outputs.
set -euo pipefail

adb devices | awk 'NR>1 && $2=="device" {print $1}'
