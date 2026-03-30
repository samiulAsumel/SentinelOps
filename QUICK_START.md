# SentinelOps Quick Start Guide

## 🚀 Get Started in 5 Minutes

### 1. Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/SentinelOps.git
cd SentinelOps

# Make scripts executable
chmod +x scripts/*.sh
```

### 2. Run Your First Scan

```bash
# Basic system scan
sudo ./scripts/sentinel-scan.sh

# Quick scan (faster)
sudo ./scripts/sentinel-scan.sh --quick-scan

# Security audit only
sudo ./scripts/sentinel-scan.sh --security-only
```

### 3. Review Results

```bash
# Check generated reports
ls -la logs/

# View the main report
cat logs/sentinel_scan_*.txt

# View detected issues
cat logs/sentinel_issues_*.txt
```

### 4. Fix Detected Issues

```bash
# Interactive mode (recommended)
sudo ./scripts/sentinel-fix.sh --interactive

# Automatic mode (use with caution)
sudo ./scripts/sentinel-fix.sh --auto-confirm

# Dry-run mode (test without changes)
sudo ./scripts/sentinel-fix.sh --dry-run

# Fix specific issues from file
sudo ./scripts/sentinel-fix.sh --issues-file logs/sentinel_issues_*.txt
```

### 5. Common Commands

```bash
# Quick security audit
sudo ./scripts/sentinel-scan.sh --security-only

# Performance analysis only
sudo ./scripts/sentinel-scan.sh --performance-only

# Fix with custom backup directory
sudo ./scripts/sentinel-fix.sh --backup-dir /custom/backups

# Debug mode for troubleshooting
sudo ./scripts/sentinel-scan.sh --debug
```

## 📋 Command Reference

### Scanner Options

```bash
sudo ./scripts/sentinel-scan.sh [OPTIONS]

Options:
  --output-dir DIR      Custom output directory
  --quick-scan          Faster, abbreviated scan
  --security-only       Security analysis only
  --performance-only    Performance analysis only
  --debug               Verbose debug output
  --help                Show help message
```

### Fixer Options

```bash
sudo ./scripts/sentinel-fix.sh [OPTIONS]

Options:
  --issues-file FILE    Fix issues from file
  --dry-run             Show changes without applying
  --interactive         Confirm each fix
  --auto-confirm        Apply all fixes automatically
  --backup-dir DIR      Custom backup directory
  --debug               Verbose debug output
  --help                Show help message
```

## 🎯 Common Workflows

### Routine System Maintenance

```bash
# Weekly maintenance
sudo ./scripts/sentinel-scan.sh
sudo ./scripts/sentinel-fix.sh --interactive
```

### Security Audit

```bash
# Monthly security check
sudo ./scripts/sentinel-scan.sh --security-only
sudo ./scripts/sentinel-fix.sh --auto-confirm --issues-file logs/sentinel_issues_*.txt
```

### Performance Optimization

```bash
# Performance tuning
sudo ./scripts/sentinel-scan.sh --performance-only
sudo ./scripts/sentinel-fix.sh --interactive
```

### Emergency Troubleshooting

```bash
# Quick diagnostics
sudo ./scripts/sentinel-scan.sh --quick-scan

# Review issues
cat logs/sentinel_issues_*.txt

# Apply critical fixes
sudo ./scripts/sentinel-fix.sh --auto-confirm
```

## 📊 Understanding the Output

### Report Files

- `sentinel_scan_*.txt` - Main system analysis report
- `sentinel_issues_*.txt` - Detected issues for remediation
- `sentinel_security_*.log` - Security-specific findings
- `sentinel_performance_*.log` - Performance metrics

### Issue Severity Levels

- **HIGH** - Critical issues requiring immediate attention
- **MEDIUM** - Important issues that should be addressed
- **LOW** - Minor issues that can be fixed later
- **INFO** - Informational items

### Color Coding

- **Green (✓)** - Success messages
- **Yellow (⚠)** - Warnings and medium issues
- **Red (✗)** - Errors and high-severity issues
- **Blue (ℹ)** - Informational messages

## 🛡️ Best Practices

### Safety First

```bash
# Always use dry-run first
sudo ./scripts/sentinel-fix.sh --dry-run

# Review what will be changed
cat logs/sentinel_fix_report_*.txt

# Then apply fixes
sudo ./scripts/sentinel-fix.sh --interactive
```

### Regular Maintenance

```bash
# Set up weekly scans
0 2 * * 1 sudo /path/to/sentinel-scan.sh --quick-scan

# Set up monthly comprehensive scans
0 3 1 * * sudo /path/to/sentinel-scan.sh
```

### Backup Management

```bash
# Regularly clean up old backups
find backups/ -type d -mtime +30 -exec rm -rf {} \;

# Archive important backups
zip -r backup_archive_$(date +%Y%m%d).zip backups/
```

## 🐛 Troubleshooting

### Common Issues

**Problem:** Script won't run  
**Solution:** Make sure scripts are executable: `chmod +x scripts/*.sh`

**Problem:** Permission denied  
**Solution:** Use sudo: `sudo ./scripts/sentinel-scan.sh`

**Problem:** Command not found  
**Solution:** Install missing packages: `sudo apt install <package>`

**Problem:** Script exits unexpectedly  
**Solution:** Run with debug mode: `sudo ./scripts/sentinel-scan.sh --debug`

### Getting Help

```bash
# View help for scanner
./scripts/sentinel-scan.sh --help

# View help for fixer
./scripts/sentinel-fix.sh --help

# Run tests to verify installation
./tests/test_suite.sh

# Check documentation
cat docs/INSTALLATION.md
```

## 📚 Next Steps

1. **Read full documentation**: `docs/INSTALLATION.md`
2. **Explore configuration**: `config/sentinel.config`
3. **Run comprehensive tests**: `./tests/test_suite.sh`
4. **Set up regular scans**: Configure cron jobs
5. **Customize for your environment**: Modify configuration files

## 🎉 You're Ready!

You now have a **production-grade system monitoring and remediation suite** at your fingertips. SentinelOps provides **enterprise-level capabilities** for system analysis, security auditing, and automated fixing.

**Remember:**
- Start with `--dry-run` to see what will be changed
- Use `--interactive` mode for safety
- Review reports before applying fixes
- Set up regular scans for ongoing maintenance

Enjoy your enhanced system management experience! 🚀
