# Assignment 1: Linux, Bash and Networking

Three small Bash scripts for checking a Linux machine: system info, disk usage and network connectivity.

## Files

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

- Linux or macOS with bash
- Basic commands like df, uname, date, hostname, whoami and uptime
- For network-check.sh: ping, nc, and one of getent, host or dig. If one of these is missing the script skips that check or uses another tool.

## Setup

```bash
git clone <repo-url>
cd assignment-1
chmod +x *.sh
```

## Usage

### system-info.sh

Shows hostname, user, date and time, OS, kernel, uptime, CPU, memory and the current directory.

```bash
./system-info.sh
```

### disk-check.sh

```bash
./disk-check.sh <threshold> [path]
```

The threshold is a number from 1 to 100. The path is optional and defaults to `/`.

Exit codes:

- 0: usage is below the threshold
- 1: usage is at or above the threshold
- 2: bad input (missing or invalid threshold, or the path does not exist)

```bash
./disk-check.sh 80
./disk-check.sh 90 /home
```

### network-check.sh

```bash
./network-check.sh <host> [port]
```

It checks the host is valid, resolves it, pings it once and lists the network interfaces. If you give a port (1 to 65535) it also tries a TCP connection with nc, or with bash's /dev/tcp if nc is not installed. Bad input exits with code 2 and an error message.

```bash
./network-check.sh example.com
./network-check.sh example.com 443
./network-check.sh 8.8.8.8 53
```

## Logs

Each script writes a timestamped line to its own file in `logs/` every time it runs, for example:

```
[2026-09-05 12:00:00] OK - ...
```

The .log files are in .gitignore. `logs/.gitkeep` is there so the folder still exists after cloning.

## Testing

```bash
./grade.sh
```

This checks the files exist, syntax with `bash -n`, permissions, the output of each script, exit codes for bad input, that logs get written, and the git history (at least 5 commits and a merged branch).

## Notes

- Some networks block ping. In that case the ping check shows a failure even if the host is up.
- On macOS a few Linux commands are missing (free, getent), so the scripts use vm_stat and dscacheutil instead.
- Nothing is hardcoded. All values come from the machine when the script runs.

## Git

`network-check.sh` was written on the `feature/network-check` branch and then merged into main. Run `git log --graph --oneline --all` to see it.
