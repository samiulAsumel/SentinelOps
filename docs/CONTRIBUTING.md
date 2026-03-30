# Contributing to SentinelOps

Thank you for your interest in contributing to SentinelOps! We welcome contributions from the community to help improve this comprehensive system monitoring and remediation tool.

## 📋 Table of Contents

- [Code of Conduct](#-code-of-conduct)
- [How Can I Contribute?](#-how-can-i-contribute)
- [Development Setup](#-development-setup)
- [Submitting Changes](#-submitting-changes)
- [Code Style Guidelines](#-code-style-guidelines)
- [Testing](#-testing)
- [Documentation](#-documentation)
- [Issue Reporting](#-issue-reporting)
- [Feature Requests](#-feature-requests)

## 🤝 Code of Conduct

By participating in this project, you agree to abide by our [Code of Conduct](CODE_OF_CONDUCT.md). Please read it to understand the expected behavior.

## 🛠️ How Can I Contribute?

### Reporting Bugs

- **Search existing issues** before creating a new one
- Provide **clear, reproducible steps** to demonstrate the issue
- Include **system information** (OS, version, etc.)
- Attach **relevant log files** when possible

### Suggesting Enhancements

- **Search existing feature requests** first
- Explain the **use case** and **benefits**
- Provide **specific examples** of how the feature would work
- Consider **security implications**

### Contributing Code

1. **Fork the repository** and create your branch from `main`
2. **Follow our coding standards** (see below)
3. **Write comprehensive tests** for new functionality
4. **Update documentation** as needed
5. **Submit a pull request** with a clear description

### Improving Documentation

- Fix typos and grammatical errors
- Improve clarity and organization
- Add missing documentation
- Update outdated information

## 🔧 Development Setup

### Prerequisites

- Linux-based system (Ubuntu/Debian recommended)
- Bash shell (v4.0+)
- Git
- Standard Linux utilities (coreutils, findutils, etc.)

### Setup Instructions

```bash
# Clone your fork
git clone https://github.com/yourusername/SentinelOps.git
cd SentinelOps

# Create a feature branch
git checkout -b feature/your-feature-name

# Make your changes
# Test thoroughly

# Commit with a descriptive message
git commit -m "Add feature: brief description of changes"

# Push to your fork
git push origin feature/your-feature-name
```

## 📤 Submitting Changes

### Pull Request Guidelines

1. **One feature per PR** - Keep pull requests focused
2. **Clear title** - Describe the change concisely
3. **Detailed description** - Explain what, why, and how
4. **Reference issues** - Use `Fixes #123` or `Addresses #456`
5. **Include tests** - All new functionality must have tests
6. **Update documentation** - Keep docs in sync with code

### Commit Message Guidelines

- **Type**: feat, fix, docs, style, refactor, perf, test, chore
- **Scope**: Optional module/component affected
- **Subject**: Brief description (50 chars max)
- **Body**: Detailed explanation (72 chars per line)
- **Footer**: Breaking changes, issue references

**Example:**
```
feat(scan): add network latency detection

Adds comprehensive network latency testing to system scan
- Measures ping times to common endpoints
- Detects DNS resolution issues
- Provides latency statistics in report

Fixes #42
```

## 🎨 Code Style Guidelines

### Bash Scripting Standards

```bash
# Shebang
#!/bin/bash

# File header with description
# Function: Description
# Author: Your Name
# Date: YYYY-MM-DD

# Constants in UPPER_CASE
readonly MAX_RETRIES=3
readonly TIMEOUT_SECONDS=30

# Function names in lowercase_with_underscores
function_name() {
    local local_var="value"  # Local variables in lowercase
    
    # Always quote variables
    echo "$local_var"
    
    # Use [[ ]] for conditionals
    if [[ "$local_var" == "value" ]]; then
        return 0
    fi
}

# Error handling
if ! command; then
    echo "Error: command failed" >&2
    exit 1
fi

# Use set -euo pipefail for robustness
set -euo pipefail
```

### General Principles

- **Security First**: Always validate inputs, handle errors gracefully
- **Modular Design**: Keep functions focused and reusable
- **Clear Naming**: Use descriptive names for variables and functions
- **Error Handling**: Provide meaningful error messages
- **Documentation**: Comment complex logic and non-obvious decisions

## 🧪 Testing

### Testing Requirements

- **Unit Tests**: Test individual functions in isolation
- **Integration Tests**: Test module interactions
- **End-to-End Tests**: Test complete workflows
- **Regression Tests**: Ensure fixes don't break existing functionality

### Running Tests

```bash
# Run all tests
./tests/run_tests.sh

# Run specific test suite
./tests/test_scan.sh
./tests/test_fix.sh
```

### Writing Tests

```bash
#!/bin/bash

# Test suite for scan module
test_scan_basic() {
    local result
    result=$(./scripts/sentinel-scan.sh --test-mode)
    
    if [[ $result == *"Scan completed"* ]]; then
        echo "✓ Basic scan test passed"
        return 0
    else
        echo "✗ Basic scan test failed"
        return 1
    fi
}

test_scan_error_handling() {
    # Test error conditions
    # ...
}

# Run all tests
main() {
    local passed=0
    local failed=0
    
    if test_scan_basic; then
        ((passed++))
    else
        ((failed++))
    fi
    
    echo "Tests: $passed passed, $failed failed"
    return $failed
}

main "$@"
```

## 📚 Documentation

### Documentation Standards

- **Clear and concise** language
- **Step-by-step** instructions for procedures
- **Code examples** with expected output
- **Screenshots** for complex workflows
- **Cross-references** to related documentation

### Documentation Structure

```
docs/
├── user-guide/          # End-user documentation
├── admin-guide/         # Administrator documentation
├── developer-guide/     # Development documentation
├── api-reference/       # API documentation (future)
└── architecture/        # System architecture
```

## 🐛 Issue Reporting

### Effective Bug Reports

1. **Clear Title**: Summarize the issue
2. **Detailed Description**: What happened vs. what you expected
3. **Reproduction Steps**: Step-by-step instructions
4. **Environment**: OS, version, relevant configurations
5. **Logs**: Attach relevant log files
6. **Screenshots**: Visual evidence when helpful

### Issue Template

```markdown
## Description

Clear description of the issue

## Steps to Reproduce

1. Step one
2. Step two
3. Step three

## Expected Behavior

What should happen

## Actual Behavior

What actually happens

## Environment

- OS: [e.g., Ubuntu 22.04]
- SentinelOps Version: [e.g., 1.0.0]
- Bash Version: [e.g., 5.1.16]

## Additional Context

Any other relevant information
```

## 💡 Feature Requests

### Effective Feature Requests

1. **Clear Title**: Summarize the feature
2. **Problem Statement**: What problem does this solve?
3. **Proposed Solution**: How should it work?
4. **Use Cases**: Who would use this and why?
5. **Alternatives**: What alternatives exist?
6. **Implementation Notes**: Any technical considerations?

### Feature Request Template

```markdown
## Feature Request

### Problem

Describe the problem this feature would solve

### Proposed Solution

Describe how the feature should work

### Use Cases

- Use case 1
- Use case 2
- Use case 3

### Alternatives

What alternatives exist to solve this problem?

### Additional Information

Any other relevant details
```

## 📜 License

By contributing to SentinelOps, you agree that your contributions will be licensed under the project's [MIT License](LICENSE).

## 🙏 Thank You!

Your contributions help make SentinelOps better for everyone. We appreciate your time, expertise, and passion for open-source software!
