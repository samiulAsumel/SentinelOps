#!/bin/bash

# SENTINELOPS TEST SUITE
# Comprehensive testing framework for SentinelOps
# Version: 1.0
# Author: SentinelOps Development Team

set -euo pipefail

# Color codes
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Test counters
PASSED=0
FAILED=0
SKIPPED=0

# Test directory
TEST_DIR="./test_results_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$TEST_DIR"

# ============================================
# TEST UTILITIES
# ============================================

# Print test header
print_test_header() {
	echo -e "${BLUE}========================================"
	echo "TEST: $1"
	echo "========================================${NC}"
}

# Print test result
print_test_result() {
	local test_name="$1"
	local status="$2"
	local message="$3"

	case "$status" in
	"PASS")
		echo -e "${GREEN}✓ PASS: $test_name${NC}"
		((PASSED++))
		;;
	"FAIL")
		echo -e "${RED}✗ FAIL: $test_name${NC}"
		echo -e "${YELLOW}  $message${NC}"
		((FAILED++))
		;;
	"SKIP")
		echo -e "${YELLOW}⊘ SKIP: $test_name${NC}"
		echo -e "${YELLOW}  $message${NC}"
		((SKIPPED++))
		;;
	esac
}

# Check if command exists
command_exists() {
	command -v "$1" &>/dev/null
}

# ============================================
# SCANNER TESTS
# ============================================

test_scanner_help() {
	print_test_header "Scanner Help Function"

	local result
	result=$(../scripts/sentinel-scan.sh --help 2>&1)

	if echo "$result" | grep -q "SentinelOps Scanner"; then
		print_test_result "Scanner Help" "PASS" "Help message displayed correctly"
	else
		print_test_result "Scanner Help" "FAIL" "Help message not found"
	fi
}

test_scanner_version() {
	print_test_header "Scanner Version Check"

	local result
	result=$(../scripts/sentinel-scan.sh --help 2>&1)

	if echo "$result" | grep -q "Version:"; then
		print_test_result "Scanner Version" "PASS" "Version information present"
	else
		print_test_result "Scanner Version" "FAIL" "Version information missing"
	fi
}

test_scanner_dry_run() {
	print_test_header "Scanner Dry Run Mode"

	# This test just checks if the script accepts the option
	# Actual functionality would require more complex testing
	local result
	if ../scripts/sentinel-scan.sh --help 2>&1 | grep -q "dry-run"; then
		print_test_result "Scanner Dry Run" "PASS" "Dry run option available"
	else
		print_test_result "Scanner Dry Run" "FAIL" "Dry run option missing"
	fi
}

test_scanner_quick_mode() {
	print_test_header "Scanner Quick Mode"

	if ../scripts/sentinel-scan.sh --help 2>&1 | grep -q "quick-scan"; then
		print_test_result "Scanner Quick Mode" "PASS" "Quick scan option available"
	else
		print_test_result "Scanner Quick Mode" "FAIL" "Quick scan option missing"
	fi
}

# ============================================
# FIXER TESTS
# ============================================

test_fixer_help() {
	print_test_header "Fixer Help Function"

	local result
	result=$(../scripts/sentinel-fix.sh --help 2>&1)

	if echo "$result" | grep -q "SentinelOps Remediation Engine"; then
		print_test_result "Fixer Help" "PASS" "Help message displayed correctly"
	else
		print_test_result "Fixer Help" "FAIL" "Help message not found"
	fi
}

test_fixer_version() {
	print_test_header "Fixer Version Check"

	local result
	result=$(../scripts/sentinel-fix.sh --help 2>&1)

	if echo "$result" | grep -q "Version:"; then
		print_test_result "Fixer Version" "PASS" "Version information present"
	else
		print_test_result "Fixer Version" "FAIL" "Version information missing"
	fi
}

test_fixer_dry_run() {
	print_test_header "Fixer Dry Run Mode"

	if ../scripts/sentinel-fix.sh --help 2>&1 | grep -q "dry-run"; then
		print_test_result "Fixer Dry Run" "PASS" "Dry run option available"
	else
		print_test_result "Fixer Dry Run" "FAIL" "Dry run option missing"
	fi
}

test_fixer_interactive() {
	print_test_header "Fixer Interactive Mode"

	if ../scripts/sentinel-fix.sh --help 2>&1 | grep -q "interactive"; then
		print_test_result "Fixer Interactive" "PASS" "Interactive option available"
	else
		print_test_result "Fixer Interactive" "FAIL" "Interactive option missing"
	fi
}

# ============================================
# SYNTAX TESTS
# ============================================

test_scanner_syntax() {
	print_test_header "Scanner Syntax Check"

	if bash -n ../scripts/sentinel-scan.sh 2>&1; then
		print_test_result "Scanner Syntax" "PASS" "No syntax errors"
	else
		print_test_result "Scanner Syntax" "FAIL" "Syntax errors found"
	fi
}

test_fixer_syntax() {
	print_test_header "Fixer Syntax Check"

	if bash -n ../scripts/sentinel-fix.sh 2>&1; then
		print_test_result "Fixer Syntax" "PASS" "No syntax errors"
	else
		print_test_result "Fixer Syntax" "FAIL" "Syntax errors found"
	fi
}

# ============================================
# FILE STRUCTURE TESTS
# ============================================

test_directory_structure() {
	print_test_header "Directory Structure"

	local missing=0
	local required_dirs=("docs" "scripts" "config" "logs" "backups" "modules" "tests")

	for dir in "${required_dirs[@]}"; do
		if [[ ! -d "../$dir" ]]; then
			echo "Missing directory: $dir"
			((missing++))
		fi
	done

	if [[ $missing -eq 0 ]]; then
		print_test_result "Directory Structure" "PASS" "All required directories present"
	else
		print_test_result "Directory Structure" "FAIL" "Missing $missing required directories"
	fi
}

test_required_files() {
	print_test_header "Required Files"

	local missing=0
	local required_files=("../README.md" "../scripts/sentinel-scan.sh" "../scripts/sentinel-fix.sh")

	for file in "${required_files[@]}"; do
		if [[ ! -f "$file" ]]; then
			echo "Missing file: $file"
			((missing++))
		fi
	done

	if [[ $missing -eq 0 ]]; then
		print_test_result "Required Files" "PASS" "All required files present"
	else
		print_test_result "Required Files" "FAIL" "Missing $missing required files"
	fi
}

# ============================================
# EXECUTABLE PERMISSIONS TESTS
# ============================================

test_script_permissions() {
	print_test_header "Script Permissions"

	local non_executable=0
	local scripts=("../scripts/sentinel-scan.sh" "../scripts/sentinel-fix.sh")

	for script in "${scripts[@]}"; do
		if [[ ! -x "$script" ]]; then
			echo "Not executable: $script"
			((non_executable++))
		fi
	done

	if [[ $non_executable -eq 0 ]]; then
		print_test_result "Script Permissions" "PASS" "All scripts are executable"
	else
		print_test_result "Script Permissions" "FAIL" "$non_executable scripts not executable"
	fi
}

# ============================================
# MAIN TEST EXECUTION
# ============================================

main() {
	echo -e "${BLUE}"
	echo "=================================================="
	echo "  SENTINELOPS TEST SUITE"
	echo "  Comprehensive Testing Framework"
	echo "=================================================="
	echo -e "${NC}"
	echo ""
	echo "Starting test execution..."
	echo ""

	# Run all tests
	test_scanner_help
	test_scanner_version
	test_scanner_dry_run
	test_scanner_quick_mode

	test_fixer_help
	test_fixer_version
	test_fixer_dry_run
	test_fixer_interactive

	test_scanner_syntax
	test_fixer_syntax

	test_directory_structure
	test_required_files
	test_script_permissions

	# Generate test report
	echo ""
	echo -e "${BLUE}=================================================="
	echo "  TEST SUMMARY"
	echo "==================================================${NC}"
	echo "Total Tests: $((PASSED + FAILED + SKIPPED))"
	echo -e "${GREEN}Passed: $PASSED${NC}"
	echo -e "${RED}Failed: $FAILED${NC}"
	echo -e "${YELLOW}Skipped: $SKIPPED${NC}"
	echo ""

	if [[ $FAILED -gt 0 ]]; then
		echo -e "${RED}✗ Some tests failed. Please review.${NC}"
		exit 1
	else
		echo -e "${GREEN}✓ All tests passed successfully!${NC}"
		exit 0
	fi
}

# Execute main function
main "$@"
