#!/bin/bash

# получение аргументов командной строки
PREFIX="$1"        # первые два октета IPv4-адреса
INTERFACE="$2"     # сетевой интерфейс
SUBNET="$3"        # третий октет (0–255)
HOST="$4"          # четвертый октет (0-255)

# проверка запуска скрипта с повышенными привилегиями
# команда arping требует прав суперпользователя поэтому проверяем идентификатор текущего пользователя
if [[ "$EUID" -ne 0 ]]; then
    echo "Error: script must be run with root privileges"
    exit 1
fi

# проверка наличия обязательных аргументов
# Если PREFIX или INTERFACE не переданы то exit 1
if [[ -z "$PREFIX" || -z "$INTERFACE" ]]; then
    echo "Usage: $0 PREFIX INTERFACE [SUBNET] [HOST]"
    exit 1
fi

# регулярные выражения для проверки IP-адресов + проверка одного октета IPv4 (0–255)
OCTET_REGEX='([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])'
# проверка PREFIX вида xxx.xxx
PREFIX_REGEX="^$OCTET_REGEX\.$OCTET_REGEX$"
# проверка корректности PREFIX

# PREFIX должен состоять из двух октетов IPv4
if [[ ! "$PREFIX" =~ $PREFIX_REGEX ]]; then
    echo "Error: invalid PREFIX format. Expected xxx.xxx"
    exit 1
fi

# проверка корректности SUBNET
# проверяем значение только в том случае если пользователь действительно передал этот аргумент
if [[ -n "$SUBNET" && ! "$SUBNET" =~ $OCTET_REGEX ]]; then
    echo "Error: invalid SUBNET value. Must be in range 0–255"
    exit 1
fi

# проверка корректности HOST
# проверяем четвертый октет IP-адреса
if [[ -n "$HOST" && ! "$HOST" =~ $OCTET_REGEX ]]; then
    echo "Error: invalid HOST value. Must be in range 0–255"
    exit 1
fi

# функция сканирования одного IP-адреса
# функция принимает IP-адрес в качестве аргумента и выполняет ARP-запрос к этому адресу
scan_ip() {
    local ip="$1"
    echo "[*] Scanning IP: $ip"
    arping -c 3 -i "$INTERFACE" "$ip" 2> /dev/null
}

# определение диапазонов сканирования
# если SUBNET не передан сканируем все подсети 1–255
# если HOST не передан сканируем все хосты 1–255
SUBNET_START=${SUBNET:-1}
SUBNET_END=${SUBNET:-255}
HOST_START=${HOST:-1}
HOST_END=${HOST:-255}
# основной цикл сканирования
# внешний цикл перебирает подсети а внутренний цикл перебирает хосты внутри подсети
for subnet in $(seq "$SUBNET_START" "$SUBNET_END"); do
    for host in $(seq "$HOST_START" "$HOST_END"); do
        scan_ip "${PREFIX}.${subnet}.${host}"
    done
done
