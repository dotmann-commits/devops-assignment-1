# Assignment 1 — Linux, Bash & Networking

A small Linux diagnostic toolkit built in Bash. It collects system
information, checks disk usage against a threshold, and performs basic
network connectivity checks.

## Structure

```
assignment-1/
├── README.md
├── system-info.sh
├── disk-check.sh
├── network-check.sh
├── grade.sh
└── logs/
    └── .gitkeep
```

## Requirements

- A Linux (or macOS/BSD) environment with `bash`.
- Standard coreutils (`df`, `uname`, `date`, `hostname`, `whoami`, `uptime`).
- Optional but recommended for full network-check functionality: `ping`,
  `getent`/`dscacheutil`/`host`/`dig` (host resolution), `nc` (port check),
  `ip`/`ifconfig` (interface listing). The scripts fall back gracefully if a
  given tool isn't present.

## Installation / Setup

```bash
git clone <your-repository-url>
cd assignment-1
chmod +x *.sh
```

No other setup or dependencies are required — everything is plain Bash and
standard system utilities.

## Usage

### system-info.sh

Prints hostname, current user, date/time, OS, kernel version, uptime, CPU
info, memory info, and current working directory — all read live from the
system.

```bash
./system-info.sh
```

### disk-check.sh

```bash
./disk-check.sh <threshold> [path]
```

- `threshold` — required integer from 1–100 (percentage).
- `path` — optional, defaults to `/`.
- Prints the current disk usage percentage for `path`.
- Exit codes:
  - `0` — usage is below the threshold.
  - `1` — usage has reached or exceeded the threshold.
  - `2` — invalid input (missing/non-integer/out-of-range threshold, or a
    path that doesn't exist).

Examples:

```bash
./disk-check.sh 80          # checks / against an 80% threshold
./disk-check.sh 90 /home    # checks /home against a 90% threshold
```

### network-check.sh

```bash
./network-check.sh <hostname-or-ip> [port]
```

- Validates the host argument (rejects empty/flag-like/invalid input).
- Resolves the host and prints the resolved address.
- Performs a basic `ping` connectivity check.
- Displays local network interface information.
- If a `port` is supplied (must be 1–65535), performs a TCP connectivity
  check against `host:port` using `nc` if available, falling back to Bash's
  `/dev/tcp` pseudo-device.
- Invalid input (missing host, malformed host, out-of-range port) returns a
  non-zero exit code and prints a clear error — it never crashes.

Examples:

```bash
./network-check.sh example.com
./network-check.sh example.com 443
./network-check.sh 8.8.8.8 53
```

## Logging

Every run of every script appends a timestamped entry (e.g.
`[2026-09-05 12:00:00] OK - ...`) to a log file under `logs/`:

- `logs/system-info.log`
- `logs/disk-check.log`
- `logs/network-check.log`

`logs/.gitkeep` keeps the (otherwise-empty, generated-content) directory
tracked in Git; the generated `*.log` files themselves are ignored via
`.gitignore` so the repository doesn't accumulate machine-specific run
history.

## Testing

Run the grading script, which exercises all three tools and validates
required behaviour:

```bash
chmod +x grade.sh *.sh
./grade.sh
```

`grade.sh` checks: required files exist, scripts pass `bash -n` syntax
checking, scripts are executable, `system-info.sh` produces all required
fields, `disk-check.sh` validates its arguments and returns the documented
exit codes, `network-check.sh` validates its arguments and does not crash
on bad input, logs are being written with timestamps, and the Git history
meets the assignment's minimum requirements (5+ commits, a merged feature
branch).

## Assumptions

- "Basic connectivity check" is implemented with `ping -c 1`; environments
  that block ICMP will see a `WARNING`/non-zero result for that specific
  check even though the host may otherwise be reachable — this is noted in
  the script output rather than treated as a hard failure of the whole run.
- Where a platform-specific tool isn't available (e.g. `free` vs `vm_stat`
  on macOS, `getent` vs `dscacheutil` for resolution), the script falls back
  to an equivalent so the toolkit works on both Linux and macOS.
- No secrets, credentials, or machine-specific hardcoded values are used;
  all information is gathered live via standard system commands.

## Git Workflow

This repository was built with a `feature/network-check` branch used to
develop `network-check.sh` in isolation, later merged into `main` — see
`git log --graph --oneline --all` for the full history.
