# SentinelOps

**Enterprise System Monitoring & Remediation Suite**

SentinelOps is a production-grade system analysis, security auditing, and automated remediation tool built for DevOps engineers, system administrators, and security professionals. Works on all major Linux distributions out of the box.

---

## Supported Distributions

| Family | Distributions | Package Manager |
|--------|--------------|-----------------|
| Debian | Ubuntu, Debian, Linux Mint, Pop!_OS | `apt` |
| RHEL | RHEL, CentOS, Fedora, AlmaLinux, Rocky | `dnf` / `yum` |
| Arch | Arch, Manjaro, EndeavourOS | `pacman` |
| SUSE | openSUSE, SLES | `zypper` |
| Alpine | Alpine Linux | `apk` |

Service manager support: `systemd`, `OpenRC`, `SysV init`
Firewall support: `ufw`, `firewalld`, `iptables`

---

## Features

### sentinel-scan.sh — System Scanner
- System information collection (hardware, kernel, OS)
- Disk health and storage analysis with threshold warnings
- Process and service analysis (zombies, failed services)
- Network analysis (interfaces, connections, listening ports)
- Security audit (SSH config, firewall, SUID/SGID files, failed logins, pending updates)
- Performance analysis (CPU, memory, disk I/O, load average)
- Software and package inventory
- System log analysis (kernel errors, journal, auth logs)
- Cron and scheduled task analysis

### sentinel-fix.sh — Remediation Engine
- Package repair and updates (distro-aware)
- Security hardening (SSH, firewall, file permissions)
- System optimization (swappiness, temp cleanup, journal limits)
- Service management (disable unnecessary services)
- Process cleanup (zombie processes, failed services)
- File permission repair
- Automatic backup before every change
- Dry-run mode for safe testing
- Interactive confirmation for high-risk operations
- Auto-fix from scanner-generated issues file

---

## Installation

### Global Install (Recommended)

```bash
git clone https://github.com/yourusername/SentinelOps.git
cd SentinelOps
sudo ./install.sh
```

This installs `sentinel-scan` and `sentinel-fix` to `/usr/local/bin/` so they can be run from anywhere.

### Uninstall

```bash
sudo ./uninstall.sh
```

### Run Without Installing

```bash
cd SentinelOps
sudo ./scripts/sentinel-scan.sh
sudo ./scripts/sentinel-fix.sh
```

---

## Usage

### Scan Commands

```bash
# Full system scan
sudo sentinel-scan

# Quick scan (essential checks only)
sudo sentinel-scan --quick-scan

# Security audit only
sudo sentinel-scan --security-only

# Performance analysis only
sudo sentinel-scan --performance-only

# Custom output directory
sudo sentinel-scan --output-dir /tmp/my-scan

# Debug mode
sudo sentinel-scan --debug
```

### Fix Commands

```bash
# Dry run (no changes, just show what would be fixed)
sudo sentinel-fix --dry-run

# Interactive mode (confirm each fix)
sudo sentinel-fix --interactive

# Auto-confirm all fixes
sudo sentinel-fix --auto-confirm

# Fix issues from scan report
sudo sentinel-fix --issues-file /var/log/sentinelops/sentinel_issues_*.txt

# Custom backup directory
sudo sentinel-fix --backup-dir /my/backups
```

### Typical Workflow

```bash
# 1. Run a scan
sudo sentinel-scan

# 2. Review the issues file
cat /var/log/sentinelops/sentinel_issues_*.txt

# 3. Preview fixes (dry run)
sudo sentinel-fix --dry-run --issues-file /var/log/sentinelops/sentinel_issues_*.txt

# 4. Apply fixes
sudo sentinel-fix --issues-file /var/log/sentinelops/sentinel_issues_*.txt
```

---

## Output Files

All output is organized by date and type:

| File | Description |
|------|-------------|
| `sentinel_scan_YYYYMMDD_HHMMSS.txt` | Full system scan report |
| `sentinel_issues_YYYYMMDD_HHMMSS.txt` | Detected issues with fix commands |
| `sentinel_security_YYYYMMDD_HHMMSS.log` | Security audit log |
| `sentinel_performance_YYYYMMDD_HHMMSS.log` | Performance metrics |
| `sentinel_fix_report_YYYYMMDD_HHMMSS.txt` | Remediation action log |

Default output directories:
- Scan logs: `./logs/` (or `/var/log/sentinelops/` after install)
- Fix backups: `./backups/` (or `/var/lib/sentinelops/backups/` after install)
- Config: `./config/sentinel.config` (or `/etc/sentinelops/sentinel.config` after install)

---

## Issue Severity Levels

| Level | Meaning | Action |
|-------|---------|--------|
| HIGH | Critical security or stability risk | Fix immediately |
| MEDIUM | Notable issue that should be addressed | Fix soon |
| LOW | Minor issue or best-practice recommendation | Fix when convenient |
| INFO | Informational finding | Review at your discretion |

---

## Configuration

Edit the config file to customize behavior:

```bash
# After global install
sudo nano /etc/sentinelops/sentinel.config

# Without install
nano config/sentinel.config
```

Configurable settings include scan thresholds, default modes, firewall rules, SSH hardening options, memory optimization, and notification settings.

---

## Project Structure

```
SentinelOps/
├── scripts/
│   ├── sentinel-scan.sh      # System scanner
│   └── sentinel-fix.sh       # Remediation engine
├── config/
│   └── sentinel.config       # Configuration file
├── tests/
│   └── test_suite.sh         # Test suite
├── docs/                     # Documentation
├── logs/                     # Scan output (auto-generated)
├── backups/                  # Fix backups (auto-generated)
├── install.sh                # Global installer
├── uninstall.sh              # Uninstaller
├── README.md                 # This file
├── QUICK_START.md            # Quick reference
└── PORTFOLIO_SUMMARY.md      # Portfolio overview
```

---

## Requirements

- Linux kernel 3.10+
- Bash 4.0+
- Root/sudo privileges
- No external dependencies — uses only standard Linux utilities

---

## License

MIT License
