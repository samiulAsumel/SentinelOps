#!/bin/bash

# SentinelOps Global Uninstaller
# Removes globally installed SentinelOps scripts
# Version: 2.0

set -euo pipefail

# Color codes
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

# Configuration (must match install.sh)
readonly INSTALL_DIR="/usr/local/bin"
readonly CONFIG_DIR="/etc/sentinelops"
readonly LIB_DIR="/var/lib/sentinelops"
readonly LOG_DIR="/var/log/sentinelops"

print_status() {
	echo -e "${GREEN}[✓]${NC} $1"
}

print_info() {
	echo -e "${CYAN}[i]${NC} $1"
}

print_warning() {
	echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
	echo -e "${RED}[✗]${NC} $1"
}

# Check if running as root
check_root() {
	if [[ $EUID -ne 0 ]]; then
		print_error "This uninstaller must be run as root or with sudo"
		echo -e "${YELLOW}Usage: sudo ./uninstall.sh${NC}"
		exit 1
	fi
}

# Ask for confirmation
ask_confirm() {
	local msg="$1"
	read -p "$msg [y/N]: " -n 1 -r
	echo
	[[ $REPLY =~ ^[Yy]$ ]]
}

# Remove scripts
remove_scripts() {
	local removed=false

	if [[ -f "$INSTALL_DIR/sentinel-scan" ]]; then
		rm -f "$INSTALL_DIR/sentinel-scan"
		print_status "Removed sentinel-scan from $INSTALL_DIR"
		removed=true
	fi

	if [[ -f "$INSTALL_DIR/sentinel-fix" ]]; then
		rm -f "$INSTALL_DIR/sentinel-fix"
		print_status "Removed sentinel-fix from $INSTALL_DIR"
		removed=true
	fi

	if [[ "$removed" == false ]]; then
		print_warning "No SentinelOps scripts found in $INSTALL_DIR"
	fi
}

# Remove configuration
remove_config() {
	if [[ -d "$CONFIG_DIR" ]]; then
		if ask_confirm "Remove configuration directory ($CONFIG_DIR)?"; then
			rm -rf "$CONFIG_DIR"
			print_status "Removed configuration directory"
		else
			print_warning "Configuration directory preserved"
		fi
	else
		print_info "No configuration directory found"
	fi
}

# Remove data and logs
remove_data() {
	if [[ -d "$LIB_DIR" ]] || [[ -d "$LOG_DIR" ]]; then
		if ask_confirm "Remove all data and logs ($LIB_DIR, $LOG_DIR)?"; then
			rm -rf "$LIB_DIR" "$LOG_DIR"
			print_status "Removed data and log directories"
		else
			print_warning "Data and log directories preserved"
		fi
	else
		print_info "No data directories found"
	fi
}

# Main uninstallation
main() {
	echo -e "${BLUE}"
	echo "=================================================="
	echo "  SENTINELOPS GLOBAL UNINSTALLER"
	echo "=================================================="
	echo -e "${NC}"
	echo ""

	check_root

	echo -e "${YELLOW}This will remove SentinelOps from your system.${NC}"
	echo ""

	remove_scripts
	remove_config
	remove_data

	echo ""
	echo -e "${GREEN}=== UNINSTALLATION COMPLETED ===${NC}"
	echo ""
	echo "SentinelOps has been removed from this system."
	echo ""
}

main "$@"
