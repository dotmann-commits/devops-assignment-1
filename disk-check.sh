#!/usr/bin/env bash
#
# disk-check.sh - Check disk usage against a threshold.
#
# Usage: ./disk-check.sh <threshold> [path]
#   threshold : integer 1-100, percentage usage to trigger a warning
#   path      : filesystem path to check (default: /)
#
# Exit codes:
#   0 - usage is below threshold
#   1 - usage has reached or exceeded threshold
#   2 - invalid input
#
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${SCRIPT_DIR}/logs"
LOG_FILE="${LOG_DIR}/disk-check.log"

log() {
    mkdir -p "${LOG_DIR}"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "${LOG_FILE}"
}

usage() {
    echo "Usage: $0 <threshold 1-100> [path]" >&2
}

THRESHOLD="${1:-}"
CHECK_PATH="${2:-/}"

if [ -z "${THRESHOLD}" ]; then
    echo "Error: threshold argument is required." >&2
    usage
    log "FAILED - missing threshold argument"
    exit 2
fi

if ! [[ "${THRESHOLD}" =~ ^[0-9]+$ ]] || [ "${THRESHOLD}" -lt 1 ] || [ "${THRESHOLD}" -gt 100 ]; then
    echo "Error: threshold must be an integer between 1 and 100." >&2
    usage
    log "FAILED - invalid threshold: ${THRESHOLD}"
    exit 2
fi

if [ ! -e "${CHECK_PATH}" ]; then
    echo "Error: path '${CHECK_PATH}' does not exist." >&2
    log "FAILED - invalid path: ${CHECK_PATH}"
    exit 2
fi

USAGE_PCT=$(df -P "${CHECK_PATH}" | awk 'NR==2 {gsub("%","",$5); print $5}')

if ! [[ "${USAGE_PCT}" =~ ^[0-9]+$ ]]; then
    echo "Error: unable to determine disk usage for '${CHECK_PATH}'." >&2
    log "FAILED - could not parse df output for ${CHECK_PATH}"
    exit 2
fi

echo "Path: ${CHECK_PATH}"
echo "Disk usage: ${USAGE_PCT}%"
echo "Threshold: ${THRESHOLD}%"

if [ "${USAGE_PCT}" -ge "${THRESHOLD}" ]; then
    echo "Status: WARNING - usage has reached or exceeded the threshold."
    log "WARNING - ${CHECK_PATH} usage ${USAGE_PCT}% >= threshold ${THRESHOLD}%"
    exit 1
else
    echo "Status: OK - usage is below the threshold."
    log "OK - ${CHECK_PATH} usage ${USAGE_PCT}% < threshold ${THRESHOLD}%"
    exit 0
fi
