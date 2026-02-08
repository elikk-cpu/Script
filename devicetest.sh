#!/bin/bash

INPUT_FILE="/proc/bus/input/devices"
LOG_FILE="/var/log/input_devices.log"
KNOWN_DEVICES="/tmp/known_devices.db"

touch "$KNOWN_DEVICES"

echo "===== Запуск: $(date '+%Y-%m-%d %H:%M:%S') =====" >> "$LOG_FILE"

DEVICE_NAME=""

while IFS= read -r line; do
    case "$line" in
        N:*)
            DEVICE_NAME=$(echo "$line" | cut -d'"' -f2)
            ;;
        "")
            if [[ -n "$DEVICE_NAME" ]]; then
                if ! grep -Fxq "$DEVICE_NAME" "$KNOWN_DEVICES"; then
                    echo "$DEVICE_NAME" >> "$KNOWN_DEVICES"
                    echo "$(date '+%Y-%m-%d %H:%M:%S') Новое устройство: $DEVICE_NAME" >> "$LOG_FILE"
                fi
            fi
            DEVICE_NAME=""
            ;;
    esac
done < "$INPUT_FILE"
