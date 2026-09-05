#!/usr/bin/env bash
#
# network-check.sh - Basic network diagnostics for a host, with optional
# TCP port connectivity check.
#
# Usage: ./network-check.sh <hostname-or-ip> [port]
#
# Exit codes:
#   0 - host validated and reachable (and port open, if supplied)
#   1 - host unreachable or port check failed
#   2 - invalid input
#
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${SCRIPT_DIR}/logs"
LOG_FILE="${LOG_DIR}/network-check.log"

log() {
    mkdir -p "${LOG_DIR}"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "${LOG_FILE}"
}

usage() {
    echo "Usage: $0 <hostname-or-ip> [port]" >&2
}

HOST="${1:-}"
PORT="${2:-}"

if [ -z "${HOST}" ]; then
    echo "Error: host argument is required." >&2
    usage
    log "FAILED - missing host argument"
    exit 2
fi

# Basic validation: reject arguments that look like flags or contain
# characters that are not valid in a hostname/IP.
if [[ "${HOST}" == -* ]] || ! [[ "${HOST}" =~ ^[A-Za-z0-9.-]+$ ]]; then
    echo "Error: '${HOST}' is not a valid hostname or IP address." >&2
    log "FAILED - invalid host: ${HOST}"
    exit 2
fi

if [ -n "${PORT}" ]; then
    if ! [[ "${PORT}" =~ ^[0-9]+$ ]] || [ "${PORT}" -lt 1 ] || [ "${PORT}" -gt 65535 ]; then
        echo "Error: port must be an integer between 1 and 65535." >&2
        usage
        log "FAILED - invalid port: ${PORT}"
        exit 2
    fi
fi

EXIT_CODE=0

echo "== Host Resolution =="
RESOLVED=""
if command -v getent >/dev/null 2>&1; then
    RESOLVED=$(getent hosts "${HOST}" 2>/dev/null | awk '{print $1}' | head -n1)
elif command -v dscacheutil >/dev/null 2>&1; then
    RESOLVED=$(dscacheutil -q host -a name "${HOST}" 2>/dev/null | awk '/^ip_address:/ {print $2; exit}')
fi
if [ -z "${RESOLVED}" ] && command -v host >/dev/null 2>&1; then
    RESOLVED=$(host "${HOST}" 2>/dev/null | awk '/has address/ {print $4; exit}')
fi
if [ -z "${RESOLVED}" ] && command -v dig >/dev/null 2>&1; then
    RESOLVED=$(dig +short "${HOST}" 2>/dev/null | head -n1)
fi

if [ -n "${RESOLVED}" ]; then
    echo "Resolved address: ${RESOLVED}"
    log "OK - resolved ${HOST} to ${RESOLVED}"
else
    echo "Resolved address: unable to resolve '${HOST}'"
    log "WARNING - could not resolve ${HOST}"
    EXIT_CODE=1
fi

echo
echo "== Connectivity Check (ping) =="
if command -v ping >/dev/null 2>&1; then
    if ping -c 1 -W 2 "${HOST}" >/dev/null 2>&1 || ping -c 1 -t 2 "${HOST}" >/dev/null 2>&1; then
        echo "Ping: SUCCESS - ${HOST} is reachable"
        log "OK - ping succeeded for ${HOST}"
    else
        echo "Ping: FAILED - ${HOST} did not respond"
        log "WARNING - ping failed for ${HOST}"
        EXIT_CODE=1
    fi
else
    echo "Ping: SKIPPED - ping command not available"
    log "SKIPPED - ping unavailable"
fi

echo
echo "== Network Interfaces =="
if command -v ip >/dev/null 2>&1; then
    ip -brief addr show 2>/dev/null || ip addr show
elif command -v ifconfig >/dev/null 2>&1; then
    ifconfig
else
    echo "No interface inspection tool available"
fi

if [ -n "${PORT}" ]; then
    echo
    echo "== TCP Port Check (${PORT}) =="
    PORT_OPEN=1
    if command -v nc >/dev/null 2>&1; then
        if nc -z -w 2 "${HOST}" "${PORT}" >/dev/null 2>&1; then
            PORT_OPEN=0
        fi
    else
        if (exec 3<>"/dev/tcp/${HOST}/${PORT}") 2>/dev/null; then
            PORT_OPEN=0
            exec 3>&- 2>/dev/null
            exec 3<&- 2>/dev/null
        fi
    fi

    if [ "${PORT_OPEN}" -eq 0 ]; then
        echo "Port ${PORT}: OPEN on ${HOST}"
        log "OK - port ${PORT} open on ${HOST}"
    else
        echo "Port ${PORT}: CLOSED or unreachable on ${HOST}"
        log "WARNING - port ${PORT} closed/unreachable on ${HOST}"
        EXIT_CODE=1
    fi
fi

log "network-check.sh finished for host=${HOST} port=${PORT:-none} exit=${EXIT_CODE}"
exit "${EXIT_CODE}"
