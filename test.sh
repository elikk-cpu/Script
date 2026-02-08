#!/bin/bash
LOGFILE="$HOME/proc_monitor.log"      # Файл логов новых процессов
KNOWNFILE="$HOME/known_pids.txt"     # Файл для хранения уже известных PID

# Создаем файлы, если их нет
touch "$LOGFILE"
touch "$KNOWNFILE"

# Заголовок в лог-файл при запуске
echo "----- Запуск скрипта: $(date '+%Y-%m-%d %H:%M:%S') -----" >> "$LOGFILE"

# Заголовок таблицы
printf "%-8s | %-20s | %-25s | %-25s | %-20s | %-8s\n" \
"PID" "NAME" "CMDLINE" "ENVIRON" "LIMITS" "STATE"
echo "----------------------------------------------------------------------------------------------------------"

# Основной цикл по всем процессам
# 1.1.- 1.3. Основной цикл по всем процессам
# 1.1. Просмотр директории /proc и запись номерных директорий
# 1.2. Получение имени процесса через /proc/N/exe
# 1.3. Получение группы параметров процесса (cmdline, environ, limits, status)

for pid in $(ls /proc | grep '^[0-9]\+$'); do

    # Проверяем, что процесс доступен
    if [ ! -d /proc/$pid ]; then
        continue
    fi

    # 1.2. Получаем имя процесса
    name=$(grep '^Name:' /proc/$pid/status 2>/dev/null | awk '{print $2}')
    [ -z "$name" ] && name="unknown"

    # 1.3. Состояние процесса
    state=$(grep '^State:' /proc/$pid/status 2>/dev/null | awk '{print $2}')
    [ -z "$state" ] && state="N/A"

    # 1.3. Параметры процесса
    # cmdline - аргументы запуска
    # environ - переменные окружения
    # limits - системные лимиты
    # status - состояние процесса (используем выше)


    # cmdline - аргументы запуска
    cmdline=$(cat /proc/$pid/cmdline 2>/dev/null | tr '\0' ' ' | head -c 25)
    [ -z "$cmdline" ] && cmdline="N/A"

    # environ - переменные окружения
    environ=$(cat /proc/$pid/environ 2>/dev/null | tr '\0' ' ' | head -c 25)
    [ -z "$environ" ] && environ="N/A"

    # limits - системные лимиты
    limits=$(head -n 1 /proc/$pid/limits 2>/dev/null | awk '{print $1}')
    [ -z "$limits" ] && limits="N/A"

    # 1.4. Выводим таблицу
    printf "%-8s | %-20s | %-25s | %-25s | %-20s | %-8s\n" \
    "$pid" "$name" "$cmdline" "$environ" "$limits" "$state"

    # 1.5. Логирование новых процессов
    if ! grep -qx "$pid" "$KNOWNFILE"; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') NEW PROCESS PID=$pid NAME=$name" >> "$LOGFILE"
        echo "$pid" >> "$KNOWNFILE"
    fi

done
# 1.6. Скрипт готов к запуску через cron
# Cron -e:
# */5 * * * * /home/aa/1211221/itog.sh
# Скрипт будет опрашивать директорию /proc каждые 5 минут
