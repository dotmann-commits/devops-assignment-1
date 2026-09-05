#!/usr/bin/env bash
#
# system-info.sh - Display key Linux system information at runtime.
#
set -euo pipefail

LOG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/logs"
LOG_FILE="${LOG_DIR}/system-info.log"

log() {
    mkdir -p "${LOG_DIR}"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "${LOG_FILE}"
}

section() {
    printf '\n== %s ==\n' "$1"
}

log "system-info.sh started"

section "Hostname"
hostname

section "Current User"
whoami

section "Date/Time"
date '+%Y-%m-%d %H:%M:%S %Z'

section "Operating System"
if [ -f /etc/os-release ]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    echo "${PRETTY_NAME:-$NAME}"
elif command -v sw_vers >/dev/null 2>&1; then
    sw_vers
else
    uname -s
fi

section "Kernel Version"
uname -r

section "Uptime"
uptime

section "CPU Information"
if [ -f /proc/cpuinfo ]; then
    grep -m1 'model name' /proc/cpuinfo | sed 's/model name[[:space:]]*: //'
    cores=$(grep -c ^processor /proc/cpuinfo)
    echo "Cores: ${cores}"
elif command -v sysctl >/dev/null 2>&1; then
    sysctl -n machdep.cpu.brand_string 2>/dev/null || echo "Unknown CPU"
    echo "Cores: $(sysctl -n hw.ncpu 2>/dev/null || echo unknown)"
else
    echo "Unknown"
fi

section "Memory Information"
if command -v free >/dev/null 2>&1; then
    free -h
elif command -v vm_stat >/dev/null 2>&1; then
    total_bytes=$(sysctl -n hw.memsize)
    total_gb=$(( total_bytes / 1024 / 1024 / 1024 ))
    echo "Total Memory: ${total_gb} GB"
    vm_stat
else
    echo "Memory information unavailable"
fi

section "Current Working Directory"
pwd

log "system-info.sh completed successfully"
