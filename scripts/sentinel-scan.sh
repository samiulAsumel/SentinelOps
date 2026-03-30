#!/bin/bash

# SENTINELOPS - COMPREHENSIVE SYSTEM SCAN
# Enterprise-grade system analysis and vulnerability detection
# Version: 2.0 Production Release
# Author: SentinelOps Development Team
# License: MIT
#
# Usage: sudo ./sentinel-scan.sh [OPTIONS]
# Options:
#   --output-dir DIR      Specify custom output directory
#   --quick-scan          Perform abbreviated scan (faster)
#   --security-only       Focus only on security analysis
#   --performance-only    Focus only on performance analysis
#   --debug               Enable debug mode with verbose output
#   --help                Show this help message
#
# Output files:
#   - System scan report with timestamp
#   - Issues file for automated remediation
#   - Security audit log
#   - Performance metrics log

set -euo pipefail # Strict error handling

# ============================================
# LINUX DISTRIBUTION COMPATIBILITY LAYER
# ============================================

# Detect Linux distribution and set appropriate commands
detect_linux_distro() {
	if [[ -f /etc/os-release ]]; then
		. /etc/os-release
		DISTRO_ID=$ID
		DISTRO_LIKE=${ID_LIKE:-$ID}
	elif type lsb_release >/dev/null 2>&1; then
		DISTRO_ID=$(lsb_release -si | tr '[:upper:]' '[:lower:]')
		DISTRO_LIKE=$DISTRO_ID
	elif [[ -f /etc/debian_version ]]; then
		DISTRO_ID="debian"
		DISTRO_LIKE="debian"
	elif [[ -f /etc/redhat-release ]]; then
		DISTRO_ID="rhel"
		DISTRO_LIKE="rhel"
	elif [[ -f /etc/arch-release ]]; then
		DISTRO_ID="arch"
		DISTRO_LIKE="arch"
	else
		DISTRO_ID="unknown"
		DISTRO_LIKE="unknown"
	fi

	# Set package manager commands
	case $DISTRO_LIKE in
	*deb* | *debiana* | *ubuntu*)
		PKG_MANAGER="apt-get"
		PKG_UPDATE="apt-get update"
		PKG_INSTALL="apt-get install -y"
		PKG_LIST="dpkg -l"
		PKG_CLEAN="apt-get clean && apt-get autoclean"
		;;
	*rhel* | *fedora* | *centos*)
		PKG_MANAGER="yum"
		PKG_UPDATE="yum check-update"
		PKG_INSTALL="yum install -y"
		PKG_LIST="rpm -qa"
		PKG_CLEAN="yum clean all"
		if command -v dnf >/dev/null; then
			PKG_MANAGER="dnf"
			PKG_UPDATE="dnf check-update"
			PKG_INSTALL="dnf install -y"
		fi
		;;
	*arch* | *manjaro*)
		PKG_MANAGER="pacman"
		PKG_UPDATE="pacman -Sy"
		PKG_INSTALL="pacman -S --noconfirm"
		PKG_LIST="pacman -Q"
		PKG_CLEAN="pacman -Sc"
		;;
	*suse* | *opensuse*)
		PKG_MANAGER="zypper"
		PKG_UPDATE="zypper refresh"
		PKG_INSTALL="zypper install -y"
		PKG_LIST="rpm -qa"
		PKG_CLEAN="zypper clean"
		;;
	*alpine*)
		PKG_MANAGER="apk"
		PKG_UPDATE="apk update"
		PKG_INSTALL="apk add"
		PKG_LIST="apk info"
		PKG_CLEAN="rm -rf /var/cache/apk/*"
		;;
	*)
		PKG_MANAGER="unknown"
		PKG_UPDATE="echo 'Package manager not detected'"
		PKG_INSTALL="echo 'Package manager not detected'"
		PKG_LIST="echo 'Package manager not detected'"
		PKG_CLEAN="echo 'Package manager not detected'"
		;;
	esac

	# Set service manager commands
	if command -v systemctl >/dev/null; then
		SERVICE_MANAGER="systemctl"
		SERVICE_LIST="systemctl list-units --type=service"
		SERVICE_STATUS="systemctl status"
		SERVICE_RESTART="systemctl restart"
	elif command -v service >/dev/null; then
		SERVICE_MANAGER="service"
		SERVICE_LIST="service --status-all"
		SERVICE_STATUS="service"
		SERVICE_RESTART="service"
	else
		SERVICE_MANAGER="unknown"
		SERVICE_LIST="echo 'Service manager not detected'"
		SERVICE_STATUS="echo 'Service manager not detected'"
		SERVICE_RESTART="echo 'Service manager not detected'"
	fi

	# Set firewall commands
	if command -v ufw >/dev/null; then
		FIREWALL_MANAGER="ufw"
	elif command -v firewall-cmd >/dev/null; then
		FIREWALL_MANAGER="firewall-cmd"
	elif command -v iptables >/dev/null; then
		FIREWALL_MANAGER="iptables"
	else
		FIREWALL_MANAGER="none"
	fi
}

# ============================================
# GLOBAL CONFIGURATION
# ============================================

# Version and metadata
readonly SENTINEL_VERSION="2.0.0"
readonly SENTINEL_NAME="SentinelOps Scanner"
readonly SENTINEL_DESC="Enterprise System Analysis Suite"

# Configuration
readonly REPORT_FILE="sentinel_scan_$(date +%Y%m%d_%H%M%S).txt"
readonly ISSUES_FILE="sentinel_issues_$(date +%Y%m%d_%H%M%S).txt"
readonly SECURITY_LOG="sentinel_security_$(date +%Y%m%d_%H%M%S).log"
readonly PERFORMANCE_LOG="sentinel_performance_$(date +%Y%m%d_%H%M%S).log"
readonly TEMP_DIR="/tmp/sentinel_scan_$$"

# Default paths
OUTPUT_DIR="./logs"
QUICK_SCAN=false
SECURITY_ONLY=false
PERFORMANCE_ONLY=false
DEBUG_MODE=false

# Color codes for professional output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly MAGENTA='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Issue severity levels
readonly SEVERITY_HIGH="HIGH"
readonly SEVERITY_MEDIUM="MEDIUM"
readonly SEVERITY_LOW="LOW"
readonly SEVERITY_INFO="INFO"

# ============================================
# CORE FUNCTIONS
# ============================================

# Display professional header
print_header() {
	local title="$1"
	local length=${#title}
	local padding=$(((60 - length) / 2))

	echo -e "${BLUE}"
	printf '%*s
' 60 '' | tr ' ' '='
	printf '%*s%s%*s
' $padding '' "$title" $padding ''
	printf '%*s
' 60 '' | tr ' ' '='
	echo -e "${NC}"
	echo "$(date '+%Y-%m-%d %H:%M:%S') - $title" >>"$OUTPUT_DIR/$REPORT_FILE"
	echo "" >>"$OUTPUT_DIR/$REPORT_FILE"
}

# Professional status messages
print_success() {
	echo -e "${GREEN}✓ $1${NC}"
	echo "✓ $1" >>"$OUTPUT_DIR/$REPORT_FILE"
}

print_warning() {
	echo -e "${YELLOW}⚠ $1${NC}"
	echo "⚠ $1" >>"$OUTPUT_DIR/$REPORT_FILE"
}

print_error() {
	echo -e "${RED}✗ $1${NC}"
	echo "✗ $1" >>"$OUTPUT_DIR/$REPORT_FILE"
}

print_info() {
	echo -e "${CYAN}ℹ $1${NC}"
	echo "ℹ $1" >>"$OUTPUT_DIR/$REPORT_FILE"
}

# Debug output
debug_log() {
	if [[ "$DEBUG_MODE" == true ]]; then
		echo -e "${MAGENTA}[DEBUG] $1${NC}"
		echo "[DEBUG] $1" >>"$OUTPUT_DIR/$REPORT_FILE"
	fi
}

# Command execution with error handling
run_command() {
	local description="$1"
	local command="$2"
	local log_file="$3"

	print_info "Running: $description"
	debug_log "Executing: $command"

	if eval "$command" 2>&1 | tee -a "$log_file" 2>/dev/null; then
		print_success "$description completed"
		return 0
	else
		print_error "$description failed"
		return 1
	fi
}

# Issue detection and logging
detect_issue() {
	local issue_type="$1"
	local severity="$2"
	local description="$3"
	local fix_command="$4"

	echo "$issue_type:$severity:$description:$fix_command" >>"$OUTPUT_DIR/$ISSUES_FILE"

	case "$severity" in
	"$SEVERITY_HIGH")
		echo -e "${RED}[HIGH] $description${NC}"
		echo "[HIGH] $description" >>"$OUTPUT_DIR/$SECURITY_LOG"
		;;
	"$SEVERITY_MEDIUM")
		echo -e "${YELLOW}[MEDIUM] $description${NC}"
		echo "[MEDIUM] $description" >>"$OUTPUT_DIR/$SECURITY_LOG"
		;;
	"$SEVERITY_LOW")
		echo -e "${YELLOW}[LOW] $description${NC}"
		echo "[LOW] $description" >>"$OUTPUT_DIR/$SECURITY_LOG"
		;;
	*)
		echo -e "${CYAN}[INFO] $description${NC}"
		echo "[INFO] $description" >>"$OUTPUT_DIR/$SECURITY_LOG"
		;;
	esac
}

# Check if command exists
command_exists() {
	command -v "$1" &>/dev/null
}

# ============================================
# SYSTEM ANALYSIS MODULES
# ============================================

# 1. SYSTEM INFORMATION COLLECTION
scan_system_info() {
	print_header "SYSTEM INFORMATION COLLECTION"

	run_command "System Overview" \
		"echo '=== SYSTEM OVERVIEW ===' && uname -a && echo '' && lsb_release -a 2>/dev/null || cat /etc/os-release 2>/dev/null || cat /etc/redhat-release 2>/dev/null || cat /etc/debian_version 2>/dev/null || echo 'OS info not available'" \
		"$OUTPUT_DIR/$REPORT_FILE"

	run_command "Hardware Information" \
		"echo '=== HARDWARE INFORMATION ===' && lshw -short 2>/dev/null || lscpu" \
		"$OUTPUT_DIR/$REPORT_FILE"

	run_command "Memory Information" \
		"echo '=== MEMORY INFORMATION ===' && free -h && vmstat 1 5" \
		"$OUTPUT_DIR/$REPORT_FILE"
}

# 2. DISK AND STORAGE ANALYSIS
scan_disk_health() {
	print_header "DISK AND STORAGE ANALYSIS"

	run_command "Disk Usage Analysis" \
		"echo '=== DISK USAGE ===' && df -h && df -i" \
		"$OUTPUT_DIR/$REPORT_FILE"

	run_command "Filesystem Analysis" \
		"echo '=== FILESYSTEM ANALYSIS ===' && mount | column -t && blkid" \
		"$OUTPUT_DIR/$REPORT_FILE"

	# Disk space warning detection
	local root_usage=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
	if [[ $root_usage -gt 85 ]]; then
		detect_issue "DISK_SPACE" "$SEVERITY_HIGH" \
			"Root partition usage is ${root_usage}%" \
			"find / -type f -size +100M -exec ls -lh {} \; | sort -k5 -h | head -20"
	elif [[ $root_usage -gt 75 ]]; then
		detect_issue "DISK_SPACE" "$SEVERITY_MEDIUM" \
			"Root partition usage is ${root_usage}%" \
			"$PKG_CLEAN"
	fi

	# Check for large files
	if command_exists ncdu; then
		run_command "Large Files Analysis" \
			"ncdu --exclude /proc --exclude /sys --exclude /dev --exclude /run 2>/dev/null | head -50" \
			"$OUTPUT_DIR/$REPORT_FILE"
	fi
}

# 3. PROCESS AND SERVICE ANALYSIS
scan_processes() {
	print_header "PROCESS AND SERVICE ANALYSIS"

	run_command "Top CPU Consumers" \
		"ps aux --sort=-%cpu | head -20" \
		"$OUTPUT_DIR/$REPORT_FILE"

	run_command "Top Memory Consumers" \
		"ps aux --sort=-%mem | head -20" \
		"$OUTPUT_DIR/$REPORT_FILE"

	# Zombie process detection
	local zombies=$(ps aux | awk '$8 ~ /^Z/ {print $2}' | wc -l)
	if [[ $zombies -gt 0 ]]; then
		detect_issue "ZOMBIE_PROCESSES" "$SEVERITY_MEDIUM" \
			"Found $zombies zombie processes" \
			"ps aux | awk '\$8 ~ /^Z/ {print \$2}' | xargs -r kill -9 2>/dev/null || true"
	fi

	run_command "Service Status" \
		"systemctl list-units --type=service --state=running,failed" \
		"$OUTPUT_DIR/$REPORT_FILE"

	# Failed service detection
	local failed=$(systemctl list-units --type=service --state=failed --no-legend | wc -l)
	if [[ $failed -gt 0 ]]; then
		detect_issue "FAILED_SERVICES" "$SEVERITY_HIGH" \
			"Found $failed failed services" \
			"systemctl reset-failed && systemctl daemon-reload"
	fi
}

# 4. NETWORK ANALYSIS
scan_network() {
	print_header "NETWORK ANALYSIS"

	run_command "Network Interfaces" \
		"ip addr show && ip route show" \
		"$OUTPUT_DIR/$REPORT_FILE"

	run_command "Active Connections" \
		"ss -tulnp && netstat -tulnp 2>/dev/null || echo 'netstat not available'" \
		"$OUTPUT_DIR/$REPORT_FILE"

	run_command "Listening Services" \
		"lsof -i -P -n | grep LISTEN" \
		"$OUTPUT_DIR/$REPORT_FILE"

	run_command "Network Statistics" \
		"netstat -s 2>/dev/null || ss -s" \
		"$OUTPUT_DIR/$REPORT_FILE"
}

# 5. SECURITY ANALYSIS
scan_security() {
	print_header "COMPREHENSIVE SECURITY ANALYSIS"

	# SSH Security Check
	if [[ -f /etc/ssh/sshd_config ]]; then
		if grep -q "^PermitRootLogin yes" /etc/ssh/sshd_config; then
			detect_issue "SSH_SECURITY" "$SEVERITY_HIGH" \
				"Root login via SSH is enabled" \
				"sed -i 's/^PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config && systemctl restart sshd"
		fi

		if grep -q "^PasswordAuthentication yes" /etc/ssh/sshd_config; then
			detect_issue "SSH_SECURITY" "$SEVERITY_MEDIUM" \
				"Password authentication via SSH is enabled" \
				"sed -i 's/^PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config && systemctl restart sshd"
		fi

		if grep -q "^Port 22" /etc/ssh/sshd_config; then
			detect_issue "SSH_SECURITY" "$SEVERITY_LOW" \
				"SSH running on default port 22" \
				"sed -i 's/^Port 22/Port 2222/' /etc/ssh/sshd_config && systemctl restart sshd"
		fi
	fi

	# Firewall Check
	if command_exists ufw; then
		if ! ufw status | grep -q "Status: active"; then
			detect_issue "FIREWALL" "$SEVERITY_HIGH" \
				"Firewall is not active" \
				"ufw --force enable && ufw default deny incoming && ufw default allow outgoing"
		fi
	elif command_exists iptables; then
		local active_rules=$(iptables -L -n | grep -c "^Chain")
		if [[ $active_rules -lt 5 ]]; then
			detect_issue "FIREWALL" "$SEVERITY_MEDIUM" \
				"iptables firewall rules appear minimal or not configured" \
				"iptables -A INPUT -p tcp --dport 22 -j ACCEPT && iptables -P INPUT DROP && iptables -P FORWARD DROP && iptables -P OUTPUT ACCEPT"
		fi
	else
		detect_issue "FIREWALL" "$SEVERITY_MEDIUM" \
			"No firewall management tool detected" \
			"apt install ufw -y && ufw --force enable"
	fi

	# SUID/SGID Files
	run_command "SUID Files Analysis" \
		"find / -type f -perm -4000 -exec ls -la {} \; 2>/dev/null | head -50" \
		"$OUTPUT_DIR/$SECURITY_LOG"

	run_command "SGID Files Analysis" \
		"find / -type f -perm -2000 -exec ls -la {} \; 2>/dev/null | head -50" \
		"$OUTPUT_DIR/$SECURITY_LOG"

	# World-writable files
	run_command "World-Writable Files" \
		"find / -type f -perm -002 -exec ls -la {} \; 2>/dev/null | head -20" \
		"$OUTPUT_DIR/$SECURITY_LOG"

	# User analysis
	run_command "Users with UID 0" \
		"awk -F: '$3 == 0 {print $1}' /etc/passwd" \
		"$OUTPUT_DIR/$SECURITY_LOG"

	# Failed login attempts (check distro-specific auth log paths)
	local auth_log=""
	if [[ -f /var/log/auth.log ]]; then
		auth_log="/var/log/auth.log"
	elif [[ -f /var/log/secure ]]; then
		auth_log="/var/log/secure"
	elif [[ -f /var/log/faillog ]]; then
		auth_log="/var/log/faillog"
	fi

	if [[ -n "$auth_log" ]]; then
		local failed_attempts=$(grep -c "Failed password\|authentication failure\|Failed" "$auth_log" 2>/dev/null || echo "0")
		if [[ $failed_attempts -gt 10 ]]; then
			detect_issue "SECURITY" "$SEVERITY_MEDIUM" \
				"$failed_attempts failed login attempts detected" \
				"grep 'Failed password\|authentication failure' $auth_log | awk '{print \$(NF-3)}' | sort | uniq -c | sort -nr"
		fi
	fi

	# Check for security updates (distro-agnostic)
	if [[ "$PKG_MANAGER" != "unknown" ]]; then
		$PKG_UPDATE &>/dev/null || true
		local updates="0"
		case $DISTRO_LIKE in
		*deb*)
			updates=$($PKG_INSTALL --dry-run dummy_package 2>&1 | grep -c '^Inst ' || echo "0")
			;;
		*rhel* | *fedora* | *centos*)
			if command_exists dnf; then
				updates=$(dnf check-update --security 2>/dev/null | grep -c '\.' || echo "0")
			elif command_exists yum; then
				updates=$(yum check-update --security 2>/dev/null | grep -c '\.' || echo "0")
			fi
			;;
		*arch*)
			updates=$(pacman -Qu 2>/dev/null | wc -l || echo "0")
			;;
		*suse*)
			updates=$(zypper list-patches 2>/dev/null | grep -c '|' || echo "0")
			;;
		*alpine*)
			updates=$(apk upgrade --simulate 2>/dev/null | grep -c 'Upgrading' || echo "0")
			;;
		esac

		if [[ "$updates" -gt 0 ]] 2>/dev/null; then
			detect_issue "SECURITY_UPDATES" "$SEVERITY_HIGH" \
				"$updates security updates available" \
				"$PKG_UPDATE && $PKG_INSTALL"
		fi
	fi
}

# 6. PERFORMANCE ANALYSIS
scan_performance() {
	print_header "PERFORMANCE ANALYSIS"

	run_command "CPU Performance" \
		"mpstat -P ALL 1 5 2>/dev/null || cat /proc/cpuinfo | grep -E 'processor|model name|cpu MHz' | head -20" \
		"$OUTPUT_DIR/$PERFORMANCE_LOG"

	run_command "Memory Performance" \
		"vmstat 1 5 && sar -r 1 5 2>/dev/null || free -h" \
		"$OUTPUT_DIR/$PERFORMANCE_LOG"

	run_command "Disk I/O Performance" \
		"iostat -x 1 1 2>/dev/null || echo 'iostat not available'" \
		"$OUTPUT_DIR/$PERFORMANCE_LOG"

	run_command "Network Performance" \
		"sar -n DEV 1 5 2>/dev/null || cat /proc/net/dev" \
		"$OUTPUT_DIR/$PERFORMANCE_LOG"

	# Load average check
	local load_avg=$(cat /proc/loadavg | awk '{print $1}')
	local cpu_count=$(nproc)
	local load_threshold=$(echo "$cpu_count * 0.8" | bc)

	if (($(echo "$load_avg > $load_threshold" | bc -l))); then
		detect_issue "PERFORMANCE" "$SEVERITY_MEDIUM" \
			"High system load detected: $load_avg (threshold: $load_threshold)" \
			"top -b -n 1 | head -20"
	fi

	# Memory usage check
	local mem_usage=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
	if [[ $mem_usage -gt 90 ]]; then
		detect_issue "PERFORMANCE" "$SEVERITY_HIGH" \
			"Memory usage is ${mem_usage}%" \
			"echo 3 > /proc/sys/vm/drop_caches && sync"
	elif [[ $mem_usage -gt 80 ]]; then
		detect_issue "PERFORMANCE" "$SEVERITY_MEDIUM" \
			"Memory usage is ${mem_usage}%" \
			"free -h && ps aux --sort=-%mem | head -10"
	fi
}

# 7. SOFTWARE AND PACKAGE ANALYSIS
scan_software() {
	print_header "SOFTWARE AND PACKAGE ANALYSIS"

	# Distro-agnostic package listing
	case $DISTRO_LIKE in
	*deb*)
		run_command "Installed Packages" \
			"dpkg -l | wc -l && dpkg -l | head -50" \
			"$OUTPUT_DIR/$REPORT_FILE"
		run_command "Package Updates" \
			"$PKG_UPDATE && apt-get upgrade --dry-run 2>/dev/null | head -50" \
			"$OUTPUT_DIR/$REPORT_FILE"
		;;
	*rhel* | *fedora* | *centos*)
		run_command "Installed Packages" \
			"rpm -qa | wc -l && rpm -qa --qf '%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}\n' | sort | head -50" \
			"$OUTPUT_DIR/$REPORT_FILE"
		run_command "Package Updates" \
			"$PKG_UPDATE 2>/dev/null | head -50 || $PKG_MANAGER check-update 2>/dev/null | head -50" \
			"$OUTPUT_DIR/$REPORT_FILE"
		;;
	*arch*)
		run_command "Installed Packages" \
			"pacman -Q | wc -l && pacman -Q | head -50" \
			"$OUTPUT_DIR/$REPORT_FILE"
		run_command "Package Updates" \
			"pacman -Qu 2>/dev/null | head -50 || echo 'All packages up to date'" \
			"$OUTPUT_DIR/$REPORT_FILE"
		;;
	*suse*)
		run_command "Installed Packages" \
			"rpm -qa | wc -l && rpm -qa --qf '%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}\n' | sort | head -50" \
			"$OUTPUT_DIR/$REPORT_FILE"
		run_command "Package Updates" \
			"zypper list-updates 2>/dev/null | head -50" \
			"$OUTPUT_DIR/$REPORT_FILE"
		;;
	*alpine*)
		run_command "Installed Packages" \
			"apk info | wc -l && apk info | head -50" \
			"$OUTPUT_DIR/$REPORT_FILE"
		run_command "Package Updates" \
			"apk version -l '<' 2>/dev/null | head -50 || echo 'All packages up to date'" \
			"$OUTPUT_DIR/$REPORT_FILE"
		;;
	*)
		run_command "Installed Packages" \
			"$PKG_LIST 2>/dev/null | head -50 || echo 'Package manager not detected'" \
			"$OUTPUT_DIR/$REPORT_FILE"
		;;
	esac

	# Check for broken packages (distro-agnostic)
	case $DISTRO_LIKE in
	*deb*)
		if command_exists dpkg; then
			local broken=$(dpkg -l | grep "^iU" | wc -l)
			if [[ $broken -gt 0 ]]; then
				detect_issue "PACKAGES" "$SEVERITY_MEDIUM" \
					"$broken broken packages detected" \
					"dpkg --configure -a && apt --fix-broken install"
			fi
		fi
		;;
	*rhel* | *fedora* | *centos*)
		if command_exists rpm; then
			local broken=$(rpm -Va 2>/dev/null | grep -c "^..5.*\|missing" || echo "0")
			if [[ $broken -gt 5 ]]; then
				detect_issue "PACKAGES" "$SEVERITY_MEDIUM" \
					"$broken package verification issues detected" \
					"$PKG_MANAGER reinstall -y \$($PKG_LIST 2>/dev/null | head -20)"
			fi
		fi
		;;
	esac
}

# 8. LOG ANALYSIS
scan_logs() {
	print_header "SYSTEM LOG ANALYSIS"

	run_command "Recent System Errors" \
		"journalctl -p 3 -xb --no-pager | head -30" \
		"$OUTPUT_DIR/$REPORT_FILE"

	run_command "Kernel Errors" \
		"dmesg | grep -i 'error\|warn\|fail' | tail -20" \
		"$OUTPUT_DIR/$REPORT_FILE"

	# Distro-agnostic auth log check
	local auth_log=""
	if [[ -f /var/log/auth.log ]]; then
		auth_log="/var/log/auth.log"
	elif [[ -f /var/log/secure ]]; then
		auth_log="/var/log/secure"
	fi

	run_command "Authentication Logs" \
		"grep 'Failed password\|authentication failure' '$auth_log' 2>/dev/null | tail -10 || echo 'No failed login attempts found or auth log not available'" \
		"$OUTPUT_DIR/$REPORT_FILE"
}

# 9. CRON AND SCHEDULED TASKS
scan_cron() {
	print_header "CRON AND SCHEDULED TASKS ANALYSIS"

	run_command "Root Crontab" \
		"crontab -l 2>/dev/null || echo 'No root crontab found'" \
		"$OUTPUT_DIR/$REPORT_FILE"

	run_command "System Cron Jobs" \
		"ls -la /etc/cron* /var/spool/cron/crontabs/ 2>/dev/null || echo 'No system cron directories found'" \
		"$OUTPUT_DIR/$REPORT_FILE"

	run_command "User Cron Jobs" \
		"for user in $(cut -d: -f1 /etc/passwd); do crontab -u \$user -l 2>/dev/null && echo \"--- User: \$user ---\"; done" \
		"$OUTPUT_DIR/$REPORT_FILE"
}

# ============================================
# MAIN EXECUTION
# ============================================

parse_arguments() {
	while [[ $# -gt 0 ]]; do
		case $1 in
		--output-dir)
			OUTPUT_DIR="$2"
			shift 2
			;;
		--quick-scan)
			QUICK_SCAN=true
			shift
			;;
		--security-only)
			SECURITY_ONLY=true
			shift
			;;
		--performance-only)
			PERFORMANCE_ONLY=true
			shift
			;;
		--debug)
			DEBUG_MODE=true
			shift
			;;
		--help | -h)
			show_help
			exit 0
			;;
		*)
			echo -e "${RED}Unknown option: $1${NC}"
			show_help
			exit 1
			;;
		esac
	done
}

show_help() {
	echo "SentinelOps Scanner - Enterprise System Analysis Suite"
	echo "Version: $SENTINEL_VERSION"
	echo ""
	echo "Usage: sudo ./sentinel-scan.sh [OPTIONS]"
	echo ""
	echo "Options:"
	echo "  --output-dir DIR      Specify custom output directory (default: ./logs)"
	echo "  --quick-scan          Perform abbreviated scan (faster execution)"
	echo "  --security-only       Focus only on security analysis"
	echo "  --performance-only    Focus only on performance analysis"
	echo "  --debug               Enable debug mode with verbose output"
	echo "  --help, -h            Show this help message"
	echo ""
	echo "Examples:"
	echo "  sudo ./sentinel-scan.sh                          # Full system scan"
	echo "  sudo ./sentinel-scan.sh --quick-scan            # Quick analysis"
	echo "  sudo ./sentinel-scan.sh --security-only        # Security audit only"
	echo "  sudo ./sentinel-scan.sh --output-dir /tmp/scan  # Custom output location"
}

check_requirements() {
	# Check if running as root
	if [[ $EUID -ne 0 ]]; then
		echo -e "${RED}ERROR: This script must be run as root or with sudo${NC}"
		echo -e "${YELLOW}Please run: sudo ./sentinel-scan.sh${NC}"
		exit 1
	fi

	# Detect Linux distribution and set compatibility layer
	detect_linux_distro

	# Add distribution info to report
	DISTRO_INFO="Detected Distribution: $DISTRO_ID (like: $DISTRO_LIKE)"
	DISTRO_INFO+="\nPackage Manager: $PKG_MANAGER"
	DISTRO_INFO+="\nService Manager: $SERVICE_MANAGER"
	DISTRO_INFO+="\nFirewall Manager: $FIREWALL_MANAGER"

	# Create output directory
	mkdir -p "$OUTPUT_DIR"

	# Create temp directory
	mkdir -p "$TEMP_DIR"

	# Initialize report files
	echo "SENTINELOPS SYSTEM SCAN REPORT" >"$OUTPUT_DIR/$REPORT_FILE"
	echo "Generated on: $(date)" >>"$OUTPUT_DIR/$REPORT_FILE"
	echo "Version: $SENTINEL_VERSION" >>"$OUTPUT_DIR/$REPORT_FILE"
	echo "Hostname: $(hostname)" >>"$OUTPUT_DIR/$REPORT_FILE"
	echo "Kernel: $(uname -r)" >>"$OUTPUT_DIR/$REPORT_FILE"
	echo "OS: $(lsb_release -d 2>/dev/null || cat /etc/os-release 2>/dev/null | grep PRETTY_NAME 2>/dev/null || cat /etc/redhat-release 2>/dev/null || echo 'Linux')" >>"$OUTPUT_DIR/$REPORT_FILE"
	echo "$DISTRO_INFO" >>"$OUTPUT_DIR/$REPORT_FILE"
	echo "=================================================" >>"$OUTPUT_DIR/$REPORT_FILE"
	echo "" >>"$OUTPUT_DIR/$REPORT_FILE"

	# Initialize issues file
	echo "SENTINELOPS DETECTED ISSUES" >"$OUTPUT_DIR/$ISSUES_FILE"
	echo "Generated on: $(date)" >>"$OUTPUT_DIR/$ISSUES_FILE"
	echo "Format: ISSUE_TYPE:SEVERITY:DESCRIPTION:FIX_COMMAND" >>"$OUTPUT_DIR/$ISSUES_FILE"
	echo "=================================================" >>"$OUTPUT_DIR/$ISSUES_FILE"
	echo "" >>"$OUTPUT_DIR/$ISSUES_FILE"

	# Initialize security log
	echo "SENTINELOPS SECURITY AUDIT LOG" >"$OUTPUT_DIR/$SECURITY_LOG"
	echo "Generated on: $(date)" >>"$OUTPUT_DIR/$SECURITY_LOG"
	echo "$DISTRO_INFO" >>"$OUTPUT_DIR/$SECURITY_LOG"
	echo "=================================================" >>"$OUTPUT_DIR/$SECURITY_LOG"
	echo "" >>"$OUTPUT_DIR/$SECURITY_LOG"

	# Initialize performance log
	echo "SENTINELOPS PERFORMANCE METRICS" >"$OUTPUT_DIR/$PERFORMANCE_LOG"
	echo "Generated on: $(date)" >>"$OUTPUT_DIR/$PERFORMANCE_LOG"
	echo "$DISTRO_INFO" >>"$OUTPUT_DIR/$PERFORMANCE_LOG"
	echo "=================================================" >>"$OUTPUT_DIR/$PERFORMANCE_LOG"
	echo "" >>"$OUTPUT_DIR/$PERFORMANCE_LOG"
}

main() {
	# Parse command line arguments
	parse_arguments "$@"

	# Check requirements and setup
	check_requirements

	# Display professional header
	echo -e "${BLUE}"
	echo "=================================================="
	echo "  SENTINELOPS SYSTEM SCANNER v$SENTINEL_VERSION"
	echo "  Enterprise System Analysis Suite"
	echo "=================================================="
	echo -e "${NC}"
	echo ""

	if [[ "$DEBUG_MODE" == true ]]; then
		echo -e "${MAGENTA}[DEBUG MODE ENABLED]${NC}"
		echo ""
	fi

	echo -e "${GREEN}Starting comprehensive system analysis...${NC}"
	echo "Report will be saved to: $OUTPUT_DIR/$REPORT_FILE"
	echo "Issues will be saved to: $OUTPUT_DIR/$ISSUES_FILE"
	echo ""

	# Run appropriate scan based on options
	if [[ "$SECURITY_ONLY" == true ]]; then
		scan_system_info
		scan_security
		scan_logs
	elif [[ "$PERFORMANCE_ONLY" == true ]]; then
		scan_system_info
		scan_performance
		scan_disk_health
		scan_processes
	else
		# Full comprehensive scan
		scan_system_info

		if [[ "$QUICK_SCAN" == false ]]; then
			scan_disk_health
			scan_processes
			scan_network
			scan_security
			scan_performance
			scan_software
			scan_logs
			scan_cron
		else
			# Quick scan - essential checks only
			scan_disk_health
			scan_processes
			scan_security
		fi
	fi

	# Generate summary
	print_header "SCAN SUMMARY"

	local total_issues=$(grep -c ':' "$OUTPUT_DIR/$ISSUES_FILE" 2>/dev/null || echo "0")
	local high_issues=$(grep -c ':HIGH:' "$OUTPUT_DIR/$ISSUES_FILE" 2>/dev/null || echo "0")
	local medium_issues=$(grep -c ':MEDIUM:' "$OUTPUT_DIR/$ISSUES_FILE" 2>/dev/null || echo "0")
	local low_issues=$(grep -c ':LOW:' "$OUTPUT_DIR/$ISSUES_FILE" 2>/dev/null || echo "0")

	echo "SCAN COMPLETED"
	echo "===============" >>"$OUTPUT_DIR/$REPORT_FILE"
	echo "Total Issues Detected: $total_issues" >>"$OUTPUT_DIR/$REPORT_FILE"
	echo "  - High Priority: $high_issues" >>"$OUTPUT_DIR/$REPORT_FILE"
	echo "  - Medium Priority: $medium_issues" >>"$OUTPUT_DIR/$REPORT_FILE"
	echo "  - Low Priority: $low_issues" >>"$OUTPUT_DIR/$REPORT_FILE"
	echo "" >>"$OUTPUT_DIR/$REPORT_FILE"

	echo -e "${GREEN}=== SCAN COMPLETED SUCCESSFULLY ===${NC}"
	echo ""
	echo "Results Summary:"
	echo "  Total Issues Detected: $total_issues"
	echo "    - High Priority: $high_issues"
	echo "    - Medium Priority: $medium_issues"
	echo "    - Low Priority: $low_issues"
	echo ""
	echo "Output Files:"
	echo "  Report: $OUTPUT_DIR/$REPORT_FILE"
	echo "  Issues: $OUTPUT_DIR/$ISSUES_FILE"
	echo "  Security Log: $OUTPUT_DIR/$SECURITY_LOG"
	echo "  Performance Log: $OUTPUT_DIR/$PERFORMANCE_LOG"
	echo ""

	if [[ $total_issues -gt 0 ]]; then
		echo -e "${YELLOW}To fix detected issues, run:${NC}"
		echo -e "${BLUE}sudo ./sentinel-fix.sh --issues-file $OUTPUT_DIR/$ISSUES_FILE${NC}"
		echo ""
	else
		echo -e "${GREEN}✓ No critical issues detected. System appears healthy.${NC}"
	fi

	# Cleanup
	rm -rf "$TEMP_DIR"

	echo -e "${BLUE}Scan completed at: $(date)${NC}"
}

# Execute main function
main "$@"
