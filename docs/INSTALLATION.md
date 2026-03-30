# SentinelOps Installation Guide

## 📋 Table of Contents

- [System Requirements](#-system-requirements)
- [Installation Methods](#-installation-methods)
  - [Quick Installation](#quick-installation)
  - [Manual Installation](#manual-installation)
  - [Docker Installation](#docker-installation)
- [Post-Installation Setup](#-post-installation-setup)
- [Configuration](#-configuration)
- [Uninstallation](#-uninstallation)
- [Troubleshooting](#-troubleshooting)

## 📋 System Requirements

### Minimum Requirements
- **Operating System**: Linux (Ubuntu 20.04+, Debian 10+, CentOS 7+)
- **Bash Version**: 4.0 or higher
- **Disk Space**: 50 MB for installation, additional space for logs and backups
- **Memory**: 512 MB minimum (1 GB recommended for full scans)
- **Privileges**: Root/sudo access required for full functionality

### Recommended Requirements
- **Operating System**: Ubuntu 22.04 LTS
- **Bash Version**: 5.0 or higher
- **Disk Space**: 500 MB+ for comprehensive scanning and backups
- **Memory**: 2 GB+ for optimal performance
- **CPU**: Multi-core processor for parallel operations

### Required Packages
Most standard Linux distributions include the required packages. If any are missing, they will be installed automatically during the first run.

```bash
# Core utilities (usually pre-installed)
coreutils findutils grep sed awk

# System analysis tools
procps lsof net-tools iproute2

# Disk and filesystem tools
df du lsblk blkid

# Network tools
netstat ss ip iptables

# Package management
apt dpkg

# Security tools
ufw fail2ban
```

## 🚀 Installation Methods

### Quick Installation

The quickest way to get SentinelOps up and running:

```bash
# Clone the repository
git clone https://github.com/yourusername/SentinelOps.git
cd SentinelOps

# Make scripts executable
chmod +x scripts/*.sh

# Run your first scan
sudo ./scripts/sentinel-scan.sh
```

### Manual Installation

For more control over the installation process:

```bash
# 1. Download the latest release
git clone https://github.com/yourusername/SentinelOps.git
cd SentinelOps

# 2. Install required dependencies
sudo apt update
sudo apt install -y coreutils findutils grep sed awk procps lsof net-tools 
                    iproute2 lsblk blkid ufw fail2ban

# 3. Set up directory structure
mkdir -p logs backups config

# 4. Make scripts executable
chmod +x scripts/sentinel-scan.sh scripts/sentinel-fix.sh

# 5. Create configuration file
cp config/sentinel.config.example config/sentinel.config

# 6. Verify installation
./tests/test_suite.sh
```

### Docker Installation

For containerized deployment:

```bash
# Build Docker image
docker build -t sentinelops:latest .

# Run container with host system access
docker run -it --rm \
  --name sentinelops \
  --pid=host \
  --privileged \
  -v /:/host \
  -v $(pwd)/logs:/app/logs \
  -v $(pwd)/backups:/app/backups \
  sentinelops:latest

# Run scan inside container
docker exec -it sentinelops ./scripts/sentinel-scan.sh
```

## 🛠️ Post-Installation Setup

### System Integration

To integrate SentinelOps with your system:

```bash
# 1. Create symbolic links for easy access
sudo ln -s $(pwd)/scripts/sentinel-scan.sh /usr/local/bin/sentinel-scan
sudo ln -s $(pwd)/scripts/sentinel-fix.sh /usr/local/bin/sentinel-fix

# 2. Set up cron jobs for regular scanning
sudo crontab -e

# Add the following lines for daily scans and weekly fixes
# 0 2 * * * /usr/local/bin/sentinel-scan --quick-scan > /var/log/sentinel-daily.log 2>&1
# 0 3 * * 0 /usr/local/bin/sentinel-fix --auto-confirm > /var/log/sentinel-weekly.log 2>&1

# 3. Configure log rotation
sudo cp config/sentinel-logrotate /etc/logrotate.d/sentinelops
```

### First Run

```bash
# Perform initial system scan
sudo sentinel-scan

# Review the report
cat logs/sentinel_scan_*.txt

# Fix detected issues (interactive mode)
sudo sentinel-fix

# Or fix automatically (use with caution)
sudo sentinel-fix --auto-confirm
```

## ⚙️ Configuration

### Configuration File

SentinelOps uses a configuration file located at `config/sentinel.config`. You can customize various aspects of the system:

```bash
# Edit the configuration file
nano config/sentinel.config

# Apply configuration changes
# (Configuration is loaded automatically on each run)
```

### Common Configuration Options

```ini
# Change output directory
OUTPUT_DIR="/var/log/sentinelops"

# Change backup directory
BACKUP_DIR="/var/backups/sentinelops"

# Enable auto-confirm for fixes
DEFAULT_MODE="auto-confirm"

# Adjust warning thresholds
DISK_USAGE_WARNING=80
MEMORY_USAGE_WARNING=75
```

### Environment Variables

You can also configure SentinelOps using environment variables:

```bash
# Set environment variables
export SENTINEL_OUTPUT_DIR="/custom/logs"
export SENTINEL_BACKUP_DIR="/custom/backups"
export SENTINEL_MODE="interactive"

# Run with custom configuration
sudo -E ./scripts/sentinel-scan.sh
```

## 🗑️ Uninstallation

### Standard Uninstallation

```bash
# Remove symbolic links
sudo rm -f /usr/local/bin/sentinel-scan
sudo rm -f /usr/local/bin/sentinel-fix

# Remove cron jobs
sudo crontab -e  # Remove SentinelOps entries

# Remove log rotation configuration
sudo rm -f /etc/logrotate.d/sentinelops

# Remove the installation directory
rm -rf SentinelOps

# Clean up logs and backups (optional)
rm -rf logs backups
```

### Complete Uninstallation

```bash
# Remove all SentinelOps files and configuration
sudo rm -rf SentinelOps /usr/local/bin/sentinel-* /etc/logrotate.d/sentinelops
sudo crontab -e  # Remove SentinelOps cron entries

# Remove temporary files
rm -rf /tmp/sentinel_*
```

## 🐛 Troubleshooting

### Common Issues and Solutions

#### Permission Denied Errors

**Error:** `Permission denied` when running scripts

**Solution:**
```bash
# Make scripts executable
chmod +x scripts/*.sh

# Run with sudo
sudo ./scripts/sentinel-scan.sh
```

#### Command Not Found

**Error:** `command not found` for required utilities

**Solution:**
```bash
# Install missing packages
sudo apt update
sudo apt install -y <missing-package>
```

#### Script Fails to Run

**Error:** Script exits immediately or shows syntax errors

**Solution:**
```bash
# Check bash version
bash --version

# Ensure you're using bash 4.0+
# Upgrade if necessary
```

#### Issues with Docker Installation

**Error:** Permission issues in Docker container

**Solution:**
```bash
# Run with proper privileges
docker run --privileged -v /:/host ...

# Or adjust container permissions
```

### Debugging

Enable debug mode for detailed output:

```bash
# Run with debug mode
sudo ./scripts/sentinel-scan.sh --debug
sudo ./scripts/sentinel-fix.sh --debug

# Check debug logs
cat logs/sentinel_scan_*.txt
```

### Getting Help

If you encounter issues not covered here:

1. **Check the logs**: Review the detailed log files in the `logs/` directory
2. **Run tests**: Execute the test suite to identify issues
3. **Consult documentation**: Review other documentation files
4. **Open an issue**: Report bugs on the GitHub repository
5. **Contact support**: Reach out to the maintainers

## 📚 Next Steps

After installation, explore these resources:

- **User Guide**: Learn how to use SentinelOps effectively
- **Administrator Guide**: Advanced configuration and management
- **Developer Guide**: Extend and customize SentinelOps
- **API Reference**: Integration with other systems

## 🎉 Congratulations!

You've successfully installed SentinelOps. Your system is now protected by enterprise-grade monitoring and remediation capabilities.

**Next recommended steps:**
1. Run your first comprehensive scan
2. Review the generated reports
3. Address any detected issues
4. Set up regular scanning schedules
5. Configure notifications for critical events

Enjoy your enhanced system management experience with SentinelOps! 🚀
