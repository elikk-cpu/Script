#!/bin/bash
PREFIX="$1"        # первые два октета: xxx.xxx
INTERFACE="$2"     # сетевой интерфейс
SUBNET="$3"        # третий октет (0–255)
HOST="$4"          # четвертый октет (0–255)
if [[ "$EUID" -ne 0 ]]; then
    echo "Error: script must be run with root privileges"
    exit 1
fi


if [[ -z "$PREFIX" || -z "$INTERFACE" ]]; then
    echo "Usage: $0 PREFIX INTERFACE [SUBNET] [HOST]"
    exit 1
fi

OCTET_REGEX='^([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$'
PREFIX_REGEX="^([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$"

validate_octet() {
    local value="$1"
    local name="$2"

    if [[ -n "$value" && ! "$value" =~ $OCTET_REGEX ]]; then
        echo "Error: invalid $name value. Must be in range 0–255"
        exit 1
    fi
}

scan_ip() {
    local ip="$1"
    echo "[*] Scanning IP: $ip"
    arping -c 3 -i "$INTERFACE" "$ip" 2> /dev/null
}

if [[ ! "$PREFIX" =~ $PREFIX_REGEX ]]; then
    echo "Error: invalid PREFIX format. Expected xxx.xxx"
    exit 1
fi

if [[ -n "$HOST" && -z "$SUBNET" ]]; then
    echo "Error: HOST cannot be specified without SUBNET"
    exit 1
fi

validate_octet "$SUBNET" "SUBNET"
validate_octet "$HOST" "HOST"

if [[ -z "$SUBNET" ]]; then
    SUBNET_START=1
    SUBNET_END=255
else
    SUBNET_START="$SUBNET"
    SUBNET_END="$SUBNET"
fi

if [[ -z "$HOST" ]]; then
    HOST_START=1
    HOST_END=255
else
    HOST_START="$HOST"
    HOST_END="$HOST"
fi

for subnet in $(seq "$SUBNET_START" "$SUBNET_END"); do
    for host in $(seq "$HOST_START" "$HOST_END"); do
        scan_ip "${PREFIX}.${subnet}.${host}"
    done
done
