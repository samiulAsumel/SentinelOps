#!/bin/bash

# SentinelOps Global Installer
# Installs sentinel-scan and sentinel-fix globally for use on any Linux distro
# Version: 2.0

set -euo pipefail

# Color codes
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

# Configuration
readonly INSTALL_DIR="/usr/local/bin"
readonly CONFIG_DIR="/etc/sentinelops"
readonly LIB_DIR="/var/lib/sentinelops"
readonly LOG_DIR="/var/log/sentinelops"

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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
		print_error "This installer must be run as root or with sudo"
		echo -e "${YELLOW}Usage: sudo ./install.sh${NC}"
		exit 1
	fi
}

# Verify source files exist
verify_source() {
	local missing=false

	if [[ ! -f "$SCRIPT_DIR/scripts/sentinel-scan.sh" ]]; then
		print_error "Source file not found: $SCRIPT_DIR/scripts/sentinel-scan.sh"
		missing=true
	fi

	if [[ ! -f "$SCRIPT_DIR/scripts/sentinel-fix.sh" ]]; then
		print_error "Source file not found: $SCRIPT_DIR/scripts/sentinel-fix.sh"
		missing=true
	fi

	if [[ "$missing" == true ]]; then
		print_error "Installation aborted: missing source files"
		exit 1
	fi
}

# Install the scripts globally
install_scripts() {
	print_info "Installing SentinelOps scripts to $INSTALL_DIR..."

	# Copy scripts
	cp "$SCRIPT_DIR/scripts/sentinel-scan.sh" "$INSTALL_DIR/sentinel-scan"
	cp "$SCRIPT_DIR/scripts/sentinel-fix.sh" "$INSTALL_DIR/sentinel-fix"

	# Set executable permissions
	chmod 755 "$INSTALL_DIR/sentinel-scan"
	chmod 755 "$INSTALL_DIR/sentinel-fix"

	print_status "Scripts installed to $INSTALL_DIR"
}

# Create configuration and data directories
create_directories() {
	print_info "Creating configuration and data directories..."

	mkdir -p "$CONFIG_DIR"
	mkdir -p "$LIB_DIR"
	mkdir -p "$LOG_DIR"
	mkdir -p "$LIB_DIR/backups"

	# Install config file if available
	if [[ -f "$SCRIPT_DIR/config/sentinel.config" ]]; then
		if [[ ! -f "$CONFIG_DIR/sentinel.config" ]]; then
			cp "$SCRIPT_DIR/config/sentinel.config" "$CONFIG_DIR/sentinel.config"
			print_status "Configuration installed to $CONFIG_DIR"
		else
			print_warning "Config file already exists, skipping (backed up existing)"
			cp "$CONFIG_DIR/sentinel.config" "$CONFIG_DIR/sentinel.config.bak.$(date +%Y%m%d_%H%M%S)"
		fi
	fi

	print_status "Directories created"
}

# Verify installation
verify_installation() {
	local success=true

	if [[ ! -x "$INSTALL_DIR/sentinel-scan" ]]; then
		print_error "sentinel-scan not found or not executable in $INSTALL_DIR"
		success=false
	fi

	if [[ ! -x "$INSTALL_DIR/sentinel-fix" ]]; then
		print_error "sentinel-fix not found or not executable in $INSTALL_DIR"
		success=false
	fi

	if [[ "$success" == true ]]; then
		print_status "Installation verified successfully"
		return 0
	else
		print_error "Installation verification failed"
		return 1
	fi
}

# Main installation
main() {
	echo -e "${BLUE}"
	echo "=================================================="
	echo "  SENTINELOPS GLOBAL INSTALLER"
	echo "  Enterprise System Analysis Suite"
	echo "=================================================="
	echo -e "${NC}"
	echo ""

	check_root
	verify_source
	install_scripts
	create_directories

	echo ""
	if verify_installation; then
		echo -e "${GREEN}=== INSTALLATION COMPLETED SUCCESSFULLY ===${NC}"
		echo ""
		echo "SentinelOps is now available globally:"
		echo ""
		echo "  sentinel-scan --help     # Show scan options"
		echo "  sentinel-fix --help      # Show fix options"
		echo ""
		echo "Usage examples:"
		echo "  sudo sentinel-scan                       # Full system scan"
		echo "  sudo sentinel-scan --quick-scan          # Quick analysis"
		echo "  sudo sentinel-scan --security-only       # Security audit only"
		echo "  sudo sentinel-fix --dry-run              # Preview fixes"
		echo "  sudo sentinel-fix --interactive          # Interactive fix mode"
		echo ""
		echo "Configuration: $CONFIG_DIR/sentinel.config"
		echo "Logs:          $LOG_DIR/"
		echo "Backups:       $LIB_DIR/backups/"
		echo ""
	else
		echo -e "${RED}=== INSTALLATION FAILED ===${NC}"
		echo "Please check the errors above and try again."
		exit 1
	fi
}

main "$@"
