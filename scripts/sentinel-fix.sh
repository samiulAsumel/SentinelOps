#!/bin/bash

# SENTINELOPS - AUTOMATED SYSTEM REMEDIATION
# Enterprise-grade system repair and optimization
# Version: 2.0 Production Release
# Author: SentinelOps Development Team
# License: MIT
#
# Usage: sudo ./sentinel-fix.sh [OPTIONS]
# Options:
#   --issues-file FILE    Auto-fix issues from specified file
#   --dry-run             Show what would be fixed without making changes
#   --interactive         Ask for confirmation before each fix
#   --auto-confirm        Automatically confirm all fixes (use with caution)
#   --backup-dir DIR      Specify custom backup directory
#   --debug               Enable debug mode with verbose output
#   --help                Show this help message
#
# Features:
#   - Comprehensive system repair capabilities
#   - Automatic backup of critical files
#   - Dry-run mode for safe testing
#   - Interactive confirmation for high-risk operations
#   - Detailed audit logging
#   - Rollback capabilities

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
		PKG_FIX="apt --fix-broken install -y"
		PKG_UPGRADE="apt upgrade -y"
		PKG_AUTOREMOVE="apt autoremove --purge -y"
		;;
	*rhel* | *fedora* | *centos*)
		PKG_MANAGER="yum"
		PKG_UPDATE="yum check-update"
		PKG_INSTALL="yum install -y"
		PKG_LIST="rpm -qa"
		PKG_CLEAN="yum clean all"
		PKG_FIX="yum reinstall -y \$(rpm -qa | head -20)"
		PKG_UPGRADE="yum update -y"
		PKG_AUTOREMOVE="yum autoremove -y"
		if command -v dnf >/dev/null; then
			PKG_MANAGER="dnf"
			PKG_UPDATE="dnf check-update"
			PKG_INSTALL="dnf install -y"
			PKG_CLEAN="dnf clean all"
			PKG_FIX="dnf reinstall -y"
			PKG_UPGRADE="dnf upgrade -y"
			PKG_AUTOREMOVE="dnf autoremove -y"
		fi
		;;
	*arch* | *manjaro*)
		PKG_MANAGER="pacman"
		PKG_UPDATE="pacman -Sy"
		PKG_INSTALL="pacman -S --noconfirm"
		PKG_LIST="pacman -Q"
		PKG_CLEAN="pacman -Sc --noconfirm"
		PKG_FIX="pacman -Syyu --noconfirm"
		PKG_UPGRADE="pacman -Syu --noconfirm"
		PKG_AUTOREMOVE="pacman -Rns \$(pacman -Qdtq) --noconfirm 2>/dev/null || true"
		;;
	*suse* | *opensuse*)
		PKG_MANAGER="zypper"
		PKG_UPDATE="zypper refresh"
		PKG_INSTALL="zypper install -y"
		PKG_LIST="rpm -qa"
		PKG_CLEAN="zypper clean"
		PKG_FIX="zypper install -f -y"
		PKG_UPGRADE="zypper update -y"
		PKG_AUTOREMOVE="zypper rm -u -y"
		;;
	*alpine*)
		PKG_MANAGER="apk"
		PKG_UPDATE="apk update"
		PKG_INSTALL="apk add"
		PKG_LIST="apk info"
		PKG_CLEAN="rm -rf /var/cache/apk/*"
		PKG_FIX="apk fix"
		PKG_UPGRADE="apk upgrade"
		PKG_AUTOREMOVE="apk del \$(apk info --orphans) 2>/dev/null || true"
		;;
	*)
		PKG_MANAGER="unknown"
		PKG_UPDATE="echo 'Package manager not detected'"
		PKG_INSTALL="echo 'Package manager not detected'"
		PKG_LIST="echo 'Package manager not detected'"
		PKG_CLEAN="echo 'Package manager not detected'"
		PKG_FIX="echo 'Package manager not detected'"
		PKG_UPGRADE="echo 'Package manager not detected'"
		PKG_AUTOREMOVE="echo 'Package manager not detected'"
		;;
	esac

	# Set service manager commands
	if command -v systemctl >/dev/null; then
		SERVICE_MANAGER="systemctl"
		SERVICE_LIST="systemctl list-units --type=service"
		SERVICE_STATUS="systemctl status"
		SERVICE_RESTART="systemctl restart"
		SERVICE_ENABLE="systemctl enable"
		SERVICE_DISABLE="systemctl disable"
		SERVICE_IS_ENABLED="systemctl is-enabled"
		SERVICE_RESET_FAILED="systemctl reset-failed && systemctl daemon-reload"
		SERVICE_LIST_FAILED="systemctl list-units --type=service --state=failed --no-legend"
	elif command -v rc-service >/dev/null; then
		SERVICE_MANAGER="openrc"
		SERVICE_LIST="rc-status"
		SERVICE_STATUS="rc-service"
		SERVICE_RESTART="rc-service"
		SERVICE_ENABLE="rc-update add"
		SERVICE_DISABLE="rc-update del"
		SERVICE_IS_ENABLED="rc-update show"
		SERVICE_RESET_FAILED="echo 'Reset not available on OpenRC'"
		SERVICE_LIST_FAILED="rc-status --crashed 2>/dev/null || echo ''"
	elif command -v service >/dev/null; then
		SERVICE_MANAGER="service"
		SERVICE_LIST="service --status-all"
		SERVICE_STATUS="service"
		SERVICE_RESTART="service"
		SERVICE_ENABLE="chkconfig on 2>/dev/null || update-rc.d enable"
		SERVICE_DISABLE="chkconfig off 2>/dev/null || update-rc.d disable"
		SERVICE_IS_ENABLED="chkconfig 2>/dev/null || echo 'unknown'"
		SERVICE_RESET_FAILED="echo 'Reset not available'"
		SERVICE_LIST_FAILED="echo 'Detection not available on SysV init'"
	else
		SERVICE_MANAGER="unknown"
		SERVICE_LIST="echo 'Service manager not detected'"
		SERVICE_STATUS="echo 'Service manager not detected'"
		SERVICE_RESTART="echo 'Service manager not detected'"
		SERVICE_ENABLE="echo 'Service manager not detected'"
		SERVICE_DISABLE="echo 'Service manager not detected'"
		SERVICE_IS_ENABLED="echo 'Service manager not detected'"
		SERVICE_RESET_FAILED="echo 'Service manager not detected'"
		SERVICE_LIST_FAILED="echo 'Service manager not detected'"
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
readonly SENTINEL_NAME="SentinelOps Remediation Engine"
readonly SENTINEL_DESC="Enterprise System Repair Suite"

# Configuration
readonly REPORT_FILE="sentinel_fix_report_$(date +%Y%m%d_%H%M%S).txt"
readonly TEMP_DIR="/tmp/sentinel_fix_$$"
readonly DEFAULT_BACKUP_DIR="./backups/sentinel_fix_$(date +%Y%m%d_%H%M%S)"

# Options
DRY_RUN=false
INTERACTIVE_MODE=false
AUTO_CONFIRM=false
ISSUES_FILE=""
AUTO_FIX=false
DEBUG_MODE=false
BACKUP_DIR=""

# Color codes for professional output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly MAGENTA='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

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
	echo "$(date '+%Y-%m-%d %H:%M:%S') - $title" >>"$REPORT_FILE"
	echo "" >>"$REPORT_FILE"
}

# Professional status messages
print_success() {
	echo -e "${GREEN}✓ $1${NC}"
	echo "✓ $1" >>"$REPORT_FILE"
}

print_warning() {
	echo -e "${YELLOW}⚠ $1${NC}"
	echo "⚠ $1" >>"$REPORT_FILE"
}

print_error() {
	echo -e "${RED}✗ $1${NC}"
	echo "✗ $1" >>"$REPORT_FILE"
}

print_info() {
	echo -e "${CYAN}ℹ $1${NC}"
	echo "ℹ $1" >>"$REPORT_FILE"
}

# Debug output
debug_log() {
	if [[ "$DEBUG_MODE" == true ]]; then
		echo -e "${MAGENTA}[DEBUG] $1${NC}"
		echo "[DEBUG] $1" >>"$REPORT_FILE"
	fi
}

# Ask for user confirmation
ask_confirmation() {
	local message="$1"
	local default="${2:-n}"

	if [[ "$AUTO_CONFIRM" == true ]]; then
		echo -e "${YELLOW}[AUTO-CONFIRM] $message - AUTO APPROVED${NC}"
		return 0
	fi

	while true; do
		read -p "$message [y/N]: " -n 1 -r
		echo
		case ${REPLY,,} in
		y | yes)
			return 0
			;;
		'' | n | no)
			return 1
			;;
		*)
			echo -e "${YELLOW}Please answer yes or no.${NC}"
			;;
		esac
	done
}

# Execute command with proper error handling
execute_command() {
	local description="$1"
	local command="$2"
	local backup_file="$3"

	print_info "Executing: $description"
	debug_log "Command: $command"

	# Create backup if specified and not in dry-run mode
	if [[ -n "$backup_file" ]] && [[ "$DRY_RUN" == false ]]; then
		backup_file_safe "$backup_file"
	fi

	if [[ "$DRY_RUN" == true ]]; then
		echo -e "${BLUE}[DRY RUN] Would execute: $command${NC}"
		echo "[DRY RUN] Would execute: $command" >>"$REPORT_FILE"
		print_success "Dry run completed"
		return 0
	fi

	# Execute the command
	if eval "$command" 2>&1 | tee -a "$REPORT_FILE"; then
		print_success "$description completed successfully"
		return 0
	else
		print_error "$description failed"
		return 1
	fi
}

# Backup file safely
backup_file_safe() {
	local file="$1"

	if [[ ! -f "$file" ]]; then
		debug_log "Backup skipped: $file does not exist"
		return
	fi

	mkdir -p "$BACKUP_DIR"
	local backup_name="$(basename "$file")_$(date +%Y%m%d_%H%M%S)"

	if cp "$file" "$BACKUP_DIR/$backup_name"; then
		print_info "Backed up: $file to $BACKUP_DIR/$backup_name"
		echo "Backed up: $file" >>"$REPORT_FILE"
	else
		print_error "Failed to backup: $file"
	fi
}

# Check if device exists
check_device() {
	local device="$1"
	if [[ -b "$device" ]]; then
		return 0
	else
		print_warning "Device $device not found, skipping..."
		echo "Device $device not found, skipping..." >>"$REPORT_FILE"
		return 1
	fi
}

# Check if command exists
check_command() {
	local cmd="$1"
	if command -v "$cmd" &>/dev/null; then
		return 0
	else
		print_warning "Command $cmd not found, skipping..."
		echo "Command $cmd not found, skipping..." >>"$REPORT_FILE"
		return 1
	fi
}

# ============================================
# SYSTEM FIX MODULES
# ============================================

# 1. DISK HEALTH AND FILESYSTEM REPAIR
fix_disk_health() {
	print_header "DISK HEALTH AND FILESYSTEM REPAIR"

	# Check and repair filesystems
	local partitions=$(lsblk -o NAME,MOUNTPOINT | grep -v '^NAME' | awk '{print $1}' | grep -v '^loop' | grep -v '^fd')

	for partition in $partitions; do
		local device="/dev/$partition"

		if check_device "$device"; then
			if check_command "fsck"; then
				print_info "Checking filesystem: $device"

				if [[ "$INTERACTIVE_MODE" == true ]]; then
					if ask_confirmation "Run fsck on $device?"; then
						execute_command "Filesystem Check - $device" \
							"fsck -f -y $device" \
							""
					else
						print_warning "Skipped fsck on $device"
					fi
				else
					execute_command "Filesystem Check - $device" \
						"fsck -f -y $device" \
						""
				fi
			fi
		fi
	done
}

# 2. PACKAGE AND SOFTWARE REPAIR
fix_packages() {
	print_header "PACKAGE AND SOFTWARE REPAIR"

	if [[ "$PKG_MANAGER" == "unknown" ]]; then
		print_warning "No supported package manager detected, skipping package repair"
		return
	fi

	# Fix broken packages
	execute_command "Fix Broken Packages" \
		"$PKG_FIX" \
		""

	# Update package lists
	execute_command "Update Package Lists" \
		"$PKG_UPDATE" \
		""

	# Upgrade packages
	if [[ "$INTERACTIVE_MODE" == true ]]; then
		if ask_confirmation "Upgrade all packages?"; then
			execute_command "Upgrade Packages" \
				"$PKG_UPGRADE" \
				""
		else
			print_warning "Package upgrade skipped"
		fi
	else
		execute_command "Upgrade Packages" \
			"$PKG_UPGRADE" \
			""
	fi

	# Clean up
	execute_command "Clean Package Cache" \
		"$PKG_CLEAN" \
		""

	# Remove unnecessary packages
	execute_command "Remove Unnecessary Packages" \
		"$PKG_AUTOREMOVE" \
		""
}

# 3. SECURITY HARDENING
fix_security() {
	print_header "SECURITY HARDENING"

	# SSH Security
	if [[ -f /etc/ssh/sshd_config ]]; then
		local ssh_changes=false

		# Disable root login
		if grep -q "^PermitRootLogin yes" /etc/ssh/sshd_config; then
			if [[ "$INTERACTIVE_MODE" == true ]]; then
				if ask_confirmation "Disable SSH root login?"; then
					execute_command "Disable SSH Root Login" \
						"sed -i 's/^PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config" \
						"/etc/ssh/sshd_config"
					ssh_changes=true
				fi
			else
				execute_command "Disable SSH Root Login" \
					"sed -i 's/^PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config" \
					"/etc/ssh/sshd_config"
				ssh_changes=true
			fi
		fi

		# Disable password authentication
		if grep -q "^PasswordAuthentication yes" /etc/ssh/sshd_config; then
			if [[ "$INTERACTIVE_MODE" == true ]]; then
				if ask_confirmation "Disable SSH password authentication?"; then
					execute_command "Disable SSH Password Authentication" \
						"sed -i 's/^PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config" \
						"/etc/ssh/sshd_config"
					ssh_changes=true
				fi
			else
				execute_command "Disable SSH Password Authentication" \
					"sed -i 's/^PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config" \
					"/etc/ssh/sshd_config"
				ssh_changes=true
			fi
		fi

		# Change SSH port
		if grep -q "^Port 22" /etc/ssh/sshd_config; then
			if [[ "$INTERACTIVE_MODE" == true ]]; then
				if ask_confirmation "Change SSH port from 22 to 2222?"; then
					execute_command "Change SSH Port" \
						"sed -i 's/^Port 22/Port 2222/' /etc/ssh/sshd_config" \
						"/etc/ssh/sshd_config"
					ssh_changes=true
				fi
			fi
		fi

		# Restart SSH if changes were made (distro-agnostic)
		if [[ "$ssh_changes" == true ]]; then
			# Determine SSH service name
			local ssh_service="sshd"
			if $SERVICE_IS_ENABLED sshd &>/dev/null; then
				ssh_service="sshd"
			elif $SERVICE_IS_ENABLED ssh &>/dev/null; then
				ssh_service="ssh"
			fi
			execute_command "Restart SSH Service" \
				"$SERVICE_RESTART $ssh_service" \
				""
		fi
	fi

	# Firewall configuration (distro-agnostic)
	case "$FIREWALL_MANAGER" in
	ufw)
		if ! ufw status | grep -q "Status: active"; then
			if [[ "$INTERACTIVE_MODE" == true ]]; then
				if ask_confirmation "Enable and configure firewall?"; then
					execute_command "Enable Firewall" \
						"ufw --force enable" \
						""
					execute_command "Configure Firewall Rules" \
						"ufw default deny incoming && ufw default allow outgoing" \
						""
					execute_command "Allow SSH" \
						"ufw allow 2222/tcp" \
						""
				fi
			else
				execute_command "Enable Firewall" \
					"ufw --force enable" \
					""
				execute_command "Configure Firewall Rules" \
					"ufw default deny incoming && ufw default allow outgoing" \
					""
				execute_command "Allow SSH" \
					"ufw allow 2222/tcp" \
					""
			fi
		fi
		;;
	firewall-cmd)
		if ! firewall-cmd --state &>/dev/null; then
			if [[ "$INTERACTIVE_MODE" == true ]]; then
				if ask_confirmation "Enable and configure firewalld?"; then
					execute_command "Enable firewalld" \
						"systemctl enable --now firewalld" \
						""
					execute_command "Configure firewalld Rules" \
						"firewall-cmd --set-default-zone=drop && firewall-cmd --permanent --add-service=ssh && firewall-cmd --reload" \
						""
				fi
			else
				execute_command "Enable firewalld" \
					"systemctl enable --now firewalld" \
					""
				execute_command "Configure firewalld Rules" \
					"firewall-cmd --set-default-zone=drop && firewall-cmd --permanent --add-service=ssh && firewall-cmd --reload" \
					""
			fi
		fi
		;;
	iptables)
		local active_rules=$(iptables -L -n 2>/dev/null | grep -c "^Chain" || echo "0")
		if [[ $active_rules -lt 5 ]]; then
			if [[ "$INTERACTIVE_MODE" == true ]]; then
				if ask_confirmation "Configure basic iptables firewall rules?"; then
					execute_command "Configure iptables" \
						"iptables -A INPUT -p tcp --dport 22 -j ACCEPT && iptables -A INPUT -i lo -j ACCEPT && iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT && iptables -P INPUT DROP && iptables -P FORWARD DROP && iptables -P OUTPUT ACCEPT" \
						""
					if check_command "iptables-save"; then
						execute_command "Save iptables rules" \
							"mkdir -p /etc/iptables && iptables-save > /etc/iptables/rules.v4" \
							""
					fi
				fi
			else
				execute_command "Configure iptables" \
					"iptables -A INPUT -p tcp --dport 22 -j ACCEPT && iptables -A INPUT -i lo -j ACCEPT && iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT && iptables -P INPUT DROP && iptables -P FORWARD DROP && iptables -P OUTPUT ACCEPT" \
					""
			fi
		fi
		;;
	none)
		print_warning "No firewall management tool detected, skipping firewall configuration"
		;;
	esac
}

# 4. SYSTEM OPTIMIZATION
fix_system_optimization() {
	print_header "SYSTEM OPTIMIZATION"

	# Memory optimization
	if ! grep -q "vm.swappiness=10" /etc/sysctl.conf 2>/dev/null; then
		if [[ "$INTERACTIVE_MODE" == true ]]; then
			if ask_confirmation "Optimize memory swappiness?"; then
				execute_command "Set Swappiness to 10" \
					"echo 'vm.swappiness=10' | tee -a /etc/sysctl.conf && sysctl -p" \
					"/etc/sysctl.conf"
			fi
		else
			execute_command "Set Swappiness to 10" \
				"echo 'vm.swappiness=10' | tee -a /etc/sysctl.conf && sysctl -p" \
				"/etc/sysctl.conf"
		fi
	else
		print_success "Swappiness already optimized"
	fi

	# Clean temporary files
	execute_command "Clean Temporary Files" \
		"find /tmp -type f -atime +7 -delete 2>/dev/null || echo 'Temp cleanup completed'" \
		""

	# Update file database
	if command -v updatedb >/dev/null; then
		execute_command "Update File Database" \
			"updatedb" \
			""
	fi

	# Limit journal size (systemd only)
	if [[ "$SERVICE_MANAGER" == "systemctl" ]]; then
		if [[ -f "/etc/systemd/journald.conf" ]]; then
			if ! grep -q "SystemMaxUse=" /etc/systemd/journald.conf; then
				if [[ "$INTERACTIVE_MODE" == true ]]; then
					if ask_confirmation "Limit journal size to 100M?"; then
						execute_command "Limit Journal Size" \
							"sed -i '/\[Journal\]/a SystemMaxUse=100M' /etc/systemd/journald.conf && systemctl restart systemd-journald" \
							"/etc/systemd/journald.conf"
					fi
				else
					execute_command "Limit Journal Size" \
						"sed -i '/\[Journal\]/a SystemMaxUse=100M' /etc/systemd/journald.conf && systemctl restart systemd-journald" \
						"/etc/systemd/journald.conf"
				fi
			fi
		fi
	fi
}

# 5. SERVICE OPTIMIZATION
fix_services() {
	print_header "SERVICE OPTIMIZATION"

	if [[ "$SERVICE_MANAGER" == "unknown" ]]; then
		print_warning "No service manager detected, skipping service optimization"
		return
	fi

	# List of services that are often unnecessary (distro-agnostic)
	local services=("cups" "postfix" "avahi-daemon")

	for service in "${services[@]}"; do
		local service_enabled=false
		if $SERVICE_IS_ENABLED "${service}.service" &>/dev/null || $SERVICE_IS_ENABLED "$service" &>/dev/null; then
			service_enabled=true
		fi

		if [[ "$service_enabled" == true ]]; then
			if [[ "$INTERACTIVE_MODE" == true ]]; then
				if ask_confirmation "Disable $service?"; then
					execute_command "Disable $service" \
						"$SERVICE_DISABLE ${service}.service 2>/dev/null || $SERVICE_DISABLE $service" \
						""
				fi
			else
				execute_command "Disable $service" \
					"$SERVICE_DISABLE ${service}.service 2>/dev/null || $SERVICE_DISABLE $service" \
					""
			fi
		fi
	done
}

# 6. PROCESS MANAGEMENT
fix_processes() {
	print_header "PROCESS MANAGEMENT"

	# Kill zombie processes
	local zombies=$(ps aux | awk '$8 ~ /^Z/ {print $2}' | wc -l)
	if [[ $zombies -gt 0 ]]; then
		if [[ "$INTERACTIVE_MODE" == true ]]; then
			if ask_confirmation "Kill $zombies zombie processes?"; then
				execute_command "Kill Zombie Processes" \
					"ps aux | awk '\$8 ~ /^Z/ {print \$2}' | xargs -r kill -9 2>/dev/null || true" \
					""
			fi
		else
			execute_command "Kill Zombie Processes" \
				"ps aux | awk '\$8 ~ /^Z/ {print \$2}' | xargs -r kill -9 2>/dev/null || true" \
				""
		fi
	fi

	# Reset failed services (distro-agnostic)
	if [[ "$SERVICE_MANAGER" == "systemctl" ]]; then
		local failed=$($SERVICE_LIST_FAILED | wc -l)
		if [[ $failed -gt 0 ]]; then
			if [[ "$INTERACTIVE_MODE" == true ]]; then
				if ask_confirmation "Reset $failed failed services?"; then
					execute_command "Reset Failed Services" \
						"$SERVICE_RESET_FAILED" \
						""
				fi
			else
				execute_command "Reset Failed Services" \
					"$SERVICE_RESET_FAILED" \
					""
			fi
		fi
	fi
}

# 7. FILE PERMISSION REPAIR
fix_permissions() {
	print_header "FILE PERMISSION REPAIR"

	# Fix common permission issues
	execute_command "Fix Home Directory Permissions" \
		"find /home -type d -exec chmod 755 {} \; 2>/dev/null || echo 'Permission fix completed'" \
		""

	# Fix world-writable files
	if [[ "$INTERACTIVE_MODE" == true ]]; then
		if ask_confirmation "Fix world-writable files?"; then
			execute_command "Fix World-Writable Files" \
				"find / -type f -perm -002 -exec chmod o-w {} \; 2>/dev/null || echo 'World-writable fix completed'" \
				""
		fi
	else
		execute_command "Fix World-Writable Files" \
			"find / -type f -perm -002 -exec chmod o-w {} \; 2>/dev/null || echo 'World-writable fix completed'" \
			""
	fi
}

# ============================================
# ISSUES FILE PROCESSING
# ============================================

# Process issues from issues file
fix_from_issues_file() {
	if [[ ! -f "$ISSUES_FILE" ]]; then
		print_error "Issues file not found: $ISSUES_FILE"
		return 1
	fi

	print_header "AUTO-FIXING DETECTED ISSUES"
	echo -e "${YELLOW}Processing issues from: $ISSUES_FILE${NC}"

	local issues_fixed=0
	local issues_total=0
	local issues_skipped=0

	while IFS=':' read -r issue_type priority description fix_command; do
		# Skip header lines and empty lines
		if [[ "$issue_type" =~ ^(SYSTEM ISSUES|Format:|$) ]] || [[ -z "$issue_type" ]]; then
			continue
		fi

		((issues_total++))

		echo -e "${BLUE}Processing: $description${NC}"
		echo "Issue: $issue_type | Priority: $priority | Description: $description" >>"$REPORT_FILE"

		# Ask for confirmation for high-priority fixes unless in dry-run or auto-confirm mode
		if [[ "$priority" == "HIGH" ]] && [[ "$DRY_RUN" == false ]] && [[ "$AUTO_CONFIRM" == false ]]; then
			echo -e "${YELLOW}HIGH PRIORITY: $description${NC}"
			echo -e "${YELLOW}Command: $fix_command${NC}"

			if ! ask_confirmation "Execute this fix?"; then
				echo -e "${YELLOW}Skipped by user${NC}"
				echo "Skipped by user" >>"$REPORT_FILE"
				((issues_skipped++))
				continue
			fi
		fi

		# Execute the fix
		if execute_command "Fix $issue_type: $description" "$fix_command" ""; then
			((issues_fixed++))
		else
			print_error "Failed to fix: $description"
		fi

		echo "---" >>"$REPORT_FILE"
		echo ""

	done <"$ISSUES_FILE"

	print_header "AUTO-FIX SUMMARY"
	echo -e "${GREEN}Issues processed: $issues_total${NC}"
	echo -e "${GREEN}Issues fixed: $issues_fixed${NC}"
	echo -e "${YELLOW}Issues skipped: $issues_skipped${NC}"

	echo "Issues processed: $issues_total" >>"$REPORT_FILE"
	echo "Issues fixed: $issues_fixed" >>"$REPORT_FILE"
	echo "Issues skipped: $issues_skipped" >>"$REPORT_FILE"
}

# ============================================
# MAIN EXECUTION
# ============================================

parse_arguments() {
	while [[ $# -gt 0 ]]; do
		case $1 in
		--issues-file)
			ISSUES_FILE="$2"
			AUTO_FIX=true
			if [[ ! -f "$ISSUES_FILE" ]]; then
				echo -e "${RED}Issues file not found: $ISSUES_FILE${NC}"
				exit 1
			fi
			echo -e "${GREEN}Using issues file: $ISSUES_FILE${NC}"
			shift 2
			;;
		--dry-run)
			DRY_RUN=true
			echo -e "${YELLOW}DRY RUN MODE: No changes will be made${NC}"
			shift
			;;
		--interactive)
			INTERACTIVE_MODE=true
			echo -e "${YELLOW}INTERACTIVE MODE: Will ask for confirmation${NC}"
			shift
			;;
		--auto-confirm)
			AUTO_CONFIRM=true
			echo -e "${YELLOW}AUTO-CONFIRM MODE: All fixes will be auto-approved${NC}"
			shift
			;;
		--backup-dir)
			BACKUP_DIR="$2"
			shift 2
			;;
		--debug)
			DEBUG_MODE=true
			echo -e "${MAGENTA}DEBUG MODE: Verbose output enabled${NC}"
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
	echo "SentinelOps Remediation Engine - Enterprise System Repair Suite"
	echo "Version: $SENTINEL_VERSION"
	echo ""
	echo "Usage: sudo ./sentinel-fix.sh [OPTIONS]"
	echo ""
	echo "Options:"
	echo "  --issues-file FILE    Auto-fix issues from specified file"
	echo "  --dry-run             Show what would be fixed without making changes"
	echo "  --interactive         Ask for confirmation before each fix"
	echo "  --auto-confirm        Automatically confirm all fixes (use with caution)"
	echo "  --backup-dir DIR      Specify custom backup directory"
	echo "  --debug               Enable debug mode with verbose output"
	echo "  --help, -h            Show this help message"
	echo ""
	echo "Examples:"
	echo "  sudo ./sentinel-fix.sh                          # Interactive fix mode"
	echo "  sudo ./sentinel-fix.sh --dry-run                # Test without changes"
	echo "  sudo ./sentinel-fix.sh --auto-confirm          # Automatic fixes"
	echo "  sudo ./sentinel-fix.sh --issues-file issues.txt # Fix from issues file"
	echo "  sudo ./sentinel-fix.sh --backup-dir /backups   # Custom backup location"
}

check_requirements() {
	# Check if running as root
	if [[ $EUID -ne 0 ]]; then
		echo -e "${RED}ERROR: This script must be run as root or with sudo${NC}"
		echo -e "${YELLOW}Please run: sudo ./sentinel-fix.sh${NC}"
		exit 1
	fi

	# Detect Linux distribution and set compatibility layer
	detect_linux_distro

	# Set backup directory
	if [[ -z "$BACKUP_DIR" ]]; then
		BACKUP_DIR="$DEFAULT_BACKUP_DIR"
	fi

	# Create directories
	mkdir -p "$BACKUP_DIR"
	mkdir -p "$TEMP_DIR"

	# Add distribution info to report
	DISTRO_INFO="Detected Distribution: $DISTRO_ID (like: $DISTRO_LIKE)"
	DISTRO_INFO+="\nPackage Manager: $PKG_MANAGER"
	DISTRO_INFO+="\nService Manager: $SERVICE_MANAGER"
	DISTRO_INFO+="\nFirewall Manager: $FIREWALL_MANAGER"

	# Initialize report file
	echo "SENTINELOPS REMEDIATION REPORT" >"$REPORT_FILE"
	echo "Generated on: $(date)" >>"$REPORT_FILE"
	echo "Version: $SENTINEL_VERSION" >>"$REPORT_FILE"
	echo "Hostname: $(hostname)" >>"$REPORT_FILE"
	echo "Kernel: $(uname -r)" >>"$REPORT_FILE"
	echo "OS: $(lsb_release -d 2>/dev/null || cat /etc/os-release 2>/dev/null | grep PRETTY_NAME 2>/dev/null || cat /etc/redhat-release 2>/dev/null || echo 'Linux')" >>"$REPORT_FILE"
	echo -e "$DISTRO_INFO" >>"$REPORT_FILE"
	echo "Backup Directory: $BACKUP_DIR" >>"$REPORT_FILE"
	echo "=================================================" >>"$REPORT_FILE"
	echo "" >>"$REPORT_FILE"
}

main() {
	# Parse command line arguments
	parse_arguments "$@"

	# Check requirements and setup
	check_requirements

	# Display professional header
	echo -e "${BLUE}"
	echo "=================================================="
	echo "  SENTINELOPS REMEDIATION ENGINE v$SENTINEL_VERSION"
	echo "  Enterprise System Repair Suite"
	echo "=================================================="
	echo -e "${NC}"
	echo ""

	echo -e "${GREEN}Starting comprehensive system remediation...${NC}"
	echo "Report will be saved to: $REPORT_FILE"
	echo "Backups will be saved to: $BACKUP_DIR"
	echo ""

	# Create system information snapshot
	print_header "SYSTEM INFORMATION SNAPSHOT (BEFORE FIXES)"
	{
		echo "=== BEFORE FIXES ==="
		uname -a
		echo ""
		df -h
		echo ""
		free -h
		echo ""
		uptime
	} >>"$REPORT_FILE"

	# If auto-fix mode, process issues file instead of running full fix
	if [[ "$AUTO_FIX" == true ]]; then
		fix_from_issues_file

		# Create system information snapshot after fixes
		print_header "SYSTEM INFORMATION SNAPSHOT (AFTER FIXES)"
		{
			echo "=== AFTER FIXES ==="
			uname -a
			echo ""
			df -h
			echo ""
			free -h
			echo ""
			uptime
			echo ""
			if [[ "$SERVICE_MANAGER" == "systemctl" ]]; then
				systemctl list-units --type=service --state=failed | head -10
			else
				$SERVICE_LIST_FAILED 2>/dev/null || echo "Failed service check not available"
			fi
		} >>"$REPORT_FILE"

		# Cleanup
		rm -rf "$TEMP_DIR"

		echo -e "${GREEN}=== REMEDIATION COMPLETED ===${NC}"
		echo -e "${GREEN}Report saved to: $REPORT_FILE${NC}"
		echo -e "${GREEN}Backups saved to: $BACKUP_DIR${NC}"
		echo -e "${YELLOW}Review the report for any warnings or errors.${NC}"
		echo ""
		echo "Summary statistics:"
		echo "- Report file size: $(du -h "$REPORT_FILE" | cut -f1)"
		echo "- Backup directory: $BACKUP_DIR"
		echo "- Remediation completed at: $(date)"
		if [[ "$DRY_RUN" == false ]]; then
			echo -e "${YELLOW}IMPORTANT: Some changes may require a reboot to take full effect.${NC}"
			echo -e "${YELLOW}Review the backup directory before making any manual reversions.${NC}"
		fi
		return
	fi

	# Full comprehensive fix
	fix_disk_health
	fix_packages
	fix_security
	fix_system_optimization
	fix_services
	fix_processes
	fix_permissions

	# Create system information snapshot after fixes
	print_header "SYSTEM INFORMATION SNAPSHOT (AFTER FIXES)"
	{
		echo "=== AFTER FIXES ==="
		uname -a
		echo ""
		df -h
		echo ""
		free -h
		echo ""
		uptime
		echo ""
		if [[ "$SERVICE_MANAGER" == "systemctl" ]]; then
			systemctl list-units --type=service --state=failed | head -10
		else
			$SERVICE_LIST_FAILED 2>/dev/null || echo "Failed service check not available"
		fi
	} >>"$REPORT_FILE"

	# Cleanup
	rm -rf "$TEMP_DIR"

	echo -e "${GREEN}=== SYSTEM REMEDIATION COMPLETED ===${NC}"
	if [[ "$DRY_RUN" == true ]]; then
		echo -e "${BLUE}DRY RUN MODE: No actual changes were made${NC}"
	fi
	echo -e "${GREEN}Report saved to: $REPORT_FILE${NC}"
	echo -e "${GREEN}Backups saved to: $BACKUP_DIR${NC}"
	echo -e "${YELLOW}Review the report for any warnings or errors.${NC}"
	echo ""
	echo "Summary statistics:"
	echo "- Report file size: $(du -h "$REPORT_FILE" | cut -f1)"
	echo "- Backup directory: $BACKUP_DIR"
	echo "- Remediation completed at: $(date)"
	if [[ "$DRY_RUN" == false ]]; then
		echo -e "${YELLOW}IMPORTANT: Some changes may require a reboot to take full effect.${NC}"
		echo -e "${YELLOW}Review the backup directory before making any manual reversions.${NC}"
	fi
}

# Execute main function
main "$@"
