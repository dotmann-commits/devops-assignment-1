#!/usr/bin/env bash
#
# grade.sh - Local grading/verification script for Assignment 1.
#
# This performs repeatable, automatable checks described in the assignment
# brief: required files, Bash syntax, executable permissions, system-info
# output, disk-check argument validation, network-check validation,
# logging, and basic Git history. It does not replace manual review.
#
set -uo pipefail

PASS=0
FAIL=0

pass() { echo "  [PASS] $1"; PASS=$((PASS+1)); }
fail() { echo "  [FAIL] $1"; FAIL=$((FAIL+1)); }
info() { echo; echo "== $1 =="; }

cd "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

info "Required files"
for f in README.md system-info.sh disk-check.sh network-check.sh grade.sh logs/.gitkeep; do
    if [ -e "${f}" ]; then
        pass "found ${f}"
    else
        fail "missing ${f}"
    fi
done

info "Bash syntax"
for f in system-info.sh disk-check.sh network-check.sh; do
    if [ -f "${f}" ]; then
        if bash -n "${f}" 2>/dev/null; then
            pass "${f} syntax OK"
        else
            fail "${f} has syntax errors"
        fi
    fi
done

info "Executable permissions"
for f in system-info.sh disk-check.sh network-check.sh grade.sh; do
    if [ -f "${f}" ]; then
        if [ -x "${f}" ]; then
            pass "${f} is executable"
        else
            fail "${f} is not executable (run: chmod +x ${f})"
        fi
    fi
done

info "system-info.sh output"
if OUTPUT=$(./system-info.sh 2>&1); then
    for keyword in Hostname "Current User" "Operating System" "Kernel Version" Uptime "CPU Information" "Memory Information" "Current Working Directory"; do
        if grep -qi "${keyword}" <<< "${OUTPUT}"; then
            pass "system-info.sh output contains '${keyword}'"
        else
            fail "system-info.sh output missing '${keyword}'"
        fi
    done
else
    fail "system-info.sh failed to run"
fi

info "disk-check.sh argument validation"
./disk-check.sh >/dev/null 2>&1
RC=$?
if [ "${RC}" -eq 2 ]; then
    pass "disk-check.sh with no args exits 2"
else
    fail "disk-check.sh with no args should exit 2 (got ${RC})"
fi

./disk-check.sh abc >/dev/null 2>&1
RC=$?
if [ "${RC}" -eq 2 ]; then
    pass "disk-check.sh rejects non-integer threshold with exit 2"
else
    fail "disk-check.sh should exit 2 for non-integer threshold (got ${RC})"
fi

./disk-check.sh 150 >/dev/null 2>&1
RC=$?
if [ "${RC}" -eq 2 ]; then
    pass "disk-check.sh rejects out-of-range threshold with exit 2"
else
    fail "disk-check.sh should exit 2 for out-of-range threshold (got ${RC})"
fi

./disk-check.sh 100 / >/dev/null 2>&1
RC=$?
if [ "${RC}" -eq 0 ] || [ "${RC}" -eq 1 ]; then
    pass "disk-check.sh 100 / runs and returns a valid status code (${RC})"
else
    fail "disk-check.sh 100 / returned unexpected code ${RC}"
fi

info "network-check.sh validation"
./network-check.sh >/dev/null 2>&1
RC=$?
if [ "${RC}" -eq 2 ]; then
    pass "network-check.sh with no args exits 2"
else
    fail "network-check.sh with no args should exit 2 (got ${RC})"
fi

./network-check.sh "bad host!" >/dev/null 2>&1
RC=$?
if [ "${RC}" -eq 2 ]; then
    pass "network-check.sh rejects invalid host with exit 2"
else
    fail "network-check.sh should exit 2 for invalid host (got ${RC})"
fi

./network-check.sh 127.0.0.1 99999 >/dev/null 2>&1
RC=$?
if [ "${RC}" -eq 2 ]; then
    pass "network-check.sh rejects out-of-range port with exit 2"
else
    fail "network-check.sh should exit 2 for out-of-range port (got ${RC})"
fi

./network-check.sh 127.0.0.1 >/dev/null 2>&1
RC=$?
if [ "${RC}" -ne 127 ] 2>/dev/null; then
    pass "network-check.sh does not crash on a valid host (exit ${RC})"
else
    fail "network-check.sh crashed unexpectedly"
fi

info "Logging"
if [ -d logs ]; then
    LOG_COUNT=$(find logs -type f -name '*.log' 2>/dev/null | wc -l | tr -d ' ')
    if [ "${LOG_COUNT}" -gt 0 ]; then
        pass "logs/ contains ${LOG_COUNT} log file(s)"
        SAMPLE_LOG=$(find logs -type f -name '*.log' | head -n1)
        if grep -qE '^\[[0-9]{4}-[0-9]{2}-[0-9]{2} ' "${SAMPLE_LOG}"; then
            pass "log entries appear timestamped (${SAMPLE_LOG})"
        else
            fail "log entries do not appear timestamped (${SAMPLE_LOG})"
        fi
    else
        fail "logs/ contains no .log files (run the scripts first)"
    fi
else
    fail "logs/ directory missing"
fi

info "Git history"
if [ -d .git ]; then
    COMMIT_COUNT=$(git log --oneline 2>/dev/null | wc -l | tr -d ' ')
    if [ "${COMMIT_COUNT}" -ge 5 ]; then
        pass "at least 5 commits found (${COMMIT_COUNT})"
    else
        fail "fewer than 5 commits found (${COMMIT_COUNT})"
    fi

    BRANCH_COUNT=$(git branch -a 2>/dev/null | grep -vc '\->' )
    if [ "${BRANCH_COUNT}" -ge 2 ]; then
        pass "at least one non-main branch reference found"
    else
        fail "no additional branches found (need a merged feature branch)"
    fi

    MERGE_COUNT=$(git log --merges --oneline 2>/dev/null | wc -l | tr -d ' ')
    if [ "${MERGE_COUNT}" -gt 0 ]; then
        pass "merge commit found in history"
    else
        fail "no merge commit found (feature branch should be merged into main)"
    fi
else
    fail ".git directory not found - is this a git repository?"
fi

echo
echo "=============================="
echo "  Results: ${PASS} passed, ${FAIL} failed"
echo "=============================="

if [ "${FAIL}" -gt 0 ]; then
    exit 1
fi
exit 0
