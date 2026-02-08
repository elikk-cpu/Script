#!/bin/bash

for pid in $(ls /proc | grep '^[0-9]\+$'); do
    echo "Найден процесс с PID: $pid"
done

for pid in $(ls /proc | grep '^[0-9]\+$'); do
    if [ -e /proc/$pid/exe ]; then
        name=$(readlink /proc/$pid/exe 2>/dev/null)
        echo "PID: $pid | EXE: $name"
    fi
done

for pid in $(ls /proc | grep '^[0-9]\+$'); do
    echo "PID: $pid"

    echo "CMDLINE:"
    cmdline=$(cat /proc/$pid/cmdline 2>/dev/null | tr '\0' ' ')
    if [ -n "$cmdline" ]; then
        echo "$cmdline"
    else
        echo "Недоступно"
    fi
    echo

    echo "ENVIRON:"
    environ=$(cat /proc/$pid/environ 2>/dev/null | tr '\0' '\n' | head -n 5)
    if [ -n "$environ" ]; then
        echo "$environ"
    else
        echo "Недоступно"
    fi
    echo

    echo "LIMITS:"
    if cat /proc/$pid/limits >/dev/null 2>&1; then
        head -n 5 /proc/$pid/limits
    else
        echo "Недоступно"
    fi
    echo

    echo "STATUS:"
    if cat /proc/$pid/status >/dev/null 2>&1; then
        head -n 5 /proc/$pid/status
    else
        echo "Недоступно"
    fi

    echo "-----------------------------"
done

printf "%-8s | %-20s | %-25s | %-25s | %-20s | %-8s\n" \
PID NAME CMDLINE ENVIRON LIMITS STATE
echo "----------------------------------------------------------------------------------------------------------"

for pid in $(ls /proc | grep '^[0-9]\+$'); do
    name=$(grep '^Name:' /proc/$pid/status 2>/dev/null | awk '{print $2}')
    state=$(grep '^State:' /proc/$pid/status 2>/dev/null | awk '{print $2}')

    cmdline=$(cat /proc/$pid/cmdline 2>/dev/null | tr '\0' ' ' | head -c 25)
    environ=$(cat /proc/$pid/environ 2>/dev/null | tr '\0' ' ' | head -c 25)
    limits=$(head -n 1 /proc/$pid/limits 2>/dev/null | awk '{print $1}')

    [ -z "$cmdline" ] && cmdline="N/A"
    [ -z "$environ" ] && environ="N/A"
    [ -z "$limits" ] && limits="N/A"
    [ -z "$state" ] && state="N/A"
    [ -z "$name" ] && continue

    printf "%-8s | %-20s | %-25s | %-25s | %-20s | %-8s\n" \
    "$pid" "$name" "$cmdline" "$environ" "$limits" "$state"
done
LOGFILE="$HOME/proc_monitor.log"
KNOWNFILE="$HOME/known_pids.txt"

touch "$KNOWNFILE"

echo "----- Запуск скрипта: $(date '+%Y-%m-%d %H:%M:%S') -----" >> "$LOGFILE"

for pid in $(ls /proc | grep '^[0-9]\+$'); do
    if ! grep -qx "$pid" "$KNOWNFILE"; then
        name=$(grep '^Name:' /proc/$pid/status 2>/dev/null | awk '{print $2}')
        [ -z "$name" ] && name="unknown"

        echo "$(date '+%Y-%m-%d %H:%M:%S') NEW PROCESS PID=$pid NAME=$name" >> "$LOGFILE"
        echo "$pid" >> "$KNOWNFILE"
    fi
done
