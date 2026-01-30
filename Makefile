# SkinLab iOS Project Makefile
# Convenient make targets for common operations

.PHONY: all setup lint format test build clean quality report help

# Configuration
PROJECT_NAME = SkinLab
SCHEME = SkinLab
DESTINATION = 'platform=iOS Simulator,name=iPhone 15'
CONFIGURATION = Debug

# Colors
CYAN = \033[0;36m
GREEN = \033[0;32m
YELLOW = \033[1;33m
RED = \033[0;31m
NC = \033[0m

# Default target
all: help

#------------------------------------------------------------------------------
# Setup
#------------------------------------------------------------------------------

## Install all required development tools
setup: setup-homebrew setup-swiftlint setup-swiftformat setup-periphery setup-pmd
	@echo "$(GREEN)✓ All tools installed successfully!$(NC)"

setup-homebrew:
	@echo "$(CYAN)Checking Homebrew...$(NC)"
	@which brew > /dev/null || (echo "Please install Homebrew first: https://brew.sh" && exit 1)
	@echo "$(GREEN)✓ Homebrew available$(NC)"

setup-swiftlint:
	@echo "$(CYAN)Installing SwiftLint...$(NC)"
	@which swiftlint > /dev/null || brew install swiftlint
	@echo "$(GREEN)✓ SwiftLint installed: $$(swiftlint version)$(NC)"

setup-swiftformat:
	@echo "$(CYAN)Installing SwiftFormat...$(NC)"
	@which swiftformat > /dev/null || brew install swiftformat
	@echo "$(GREEN)✓ SwiftFormat installed: $$(swiftformat --version)$(NC)"

setup-periphery:
	@echo "$(CYAN)Installing Periphery...$(NC)"
	@which periphery > /dev/null || brew install peripheryapp/periphery/periphery
	@echo "$(GREEN)✓ Periphery installed$(NC)"

setup-pmd:
	@echo "$(CYAN)Installing PMD...$(NC)"
	@which pmd > /dev/null || brew install pmd
	@echo "$(GREEN)✓ PMD installed$(NC)"

#------------------------------------------------------------------------------
# Linting
#------------------------------------------------------------------------------

## Run SwiftLint to check code style
lint:
	@echo "$(CYAN)Running SwiftLint...$(NC)"
	@swiftlint lint --strict 2>/dev/null || swiftlint
	@echo "$(GREEN)✓ Linting complete$(NC)"

## Run SwiftLint with auto-fix
lint-fix:
	@echo "$(CYAN)Running SwiftLint with auto-fix...$(NC)"
	@swiftlint --fix
	@echo "$(GREEN)✓ Auto-fix complete$(NC)"

#------------------------------------------------------------------------------
# Formatting
#------------------------------------------------------------------------------

## Run SwiftFormat to format code
format:
	@echo "$(CYAN)Running SwiftFormat...$(NC)"
	@swiftformat $(PROJECT_NAME) --swiftversion 5.9
	@echo "$(GREEN)✓ Formatting complete$(NC)"

## Check formatting without making changes
format-check:
	@echo "$(CYAN)Checking code formatting...$(NC)"
	@swiftformat $(PROJECT_NAME) --lint --swiftversion 5.9
	@echo "$(GREEN)✓ Format check complete$(NC)"

#------------------------------------------------------------------------------
# Testing
#------------------------------------------------------------------------------

## Run all unit tests
test:
	@echo "$(CYAN)Running unit tests...$(NC)"
	@xcodebuild test \
		-project $(PROJECT_NAME).xcodeproj \
		-scheme $(SCHEME) \
		-destination $(DESTINATION) \
		-configuration $(CONFIGURATION) \
		-resultBundlePath TestResults.xcresult \
		-enableCodeCoverage YES \
		| xcbeautify 2>/dev/null || xcodebuild test \
			-project $(PROJECT_NAME).xcodeproj \
			-scheme $(SCHEME) \
			-destination $(DESTINATION) \
			-enableCodeCoverage YES
	@echo "$(GREEN)✓ Tests complete$(NC)"

## Run UI tests
test-ui:
	@echo "$(CYAN)Running UI tests...$(NC)"
	@xcodebuild test \
		-project $(PROJECT_NAME).xcodeproj \
		-scheme $(PROJECT_NAME)UITests \
		-destination $(DESTINATION) \
		| xcbeautify 2>/dev/null || xcodebuild test \
			-project $(PROJECT_NAME).xcodeproj \
			-scheme $(PROJECT_NAME)UITests \
			-destination $(DESTINATION)
	@echo "$(GREEN)✓ UI tests complete$(NC)"

## Run all tests (unit + UI)
test-all: test test-ui

## Show code coverage report
coverage:
	@echo "$(CYAN)Generating coverage report...$(NC)"
	@if [ -d "TestResults.xcresult" ]; then \
		xcrun xccov view --report TestResults.xcresult; \
	else \
		echo "$(YELLOW)Run 'make test' first to generate coverage data$(NC)"; \
	fi

#------------------------------------------------------------------------------
# Building
#------------------------------------------------------------------------------

## Build the project (Debug)
build:
	@echo "$(CYAN)Building project (Debug)...$(NC)"
	@xcodebuild build \
		-project $(PROJECT_NAME).xcodeproj \
		-scheme $(SCHEME) \
		-destination $(DESTINATION) \
		-configuration Debug \
		CODE_SIGNING_ALLOWED=NO \
		| xcbeautify 2>/dev/null || xcodebuild build \
			-project $(PROJECT_NAME).xcodeproj \
			-scheme $(SCHEME) \
			-destination $(DESTINATION) \
			CODE_SIGNING_ALLOWED=NO
	@echo "$(GREEN)✓ Build complete$(NC)"

## Build the project (Release)
build-release:
	@echo "$(CYAN)Building project (Release)...$(NC)"
	@xcodebuild build \
		-project $(PROJECT_NAME).xcodeproj \
		-scheme $(SCHEME) \
		-destination $(DESTINATION) \
		-configuration Release \
		CODE_SIGNING_ALLOWED=NO \
		| xcbeautify 2>/dev/null || xcodebuild build \
			-project $(PROJECT_NAME).xcodeproj \
			-scheme $(SCHEME) \
			-destination $(DESTINATION) \
			-configuration Release \
			CODE_SIGNING_ALLOWED=NO
	@echo "$(GREEN)✓ Release build complete$(NC)"

## Clean build artifacts
clean:
	@echo "$(CYAN)Cleaning build artifacts...$(NC)"
	@xcodebuild clean \
		-project $(PROJECT_NAME).xcodeproj \
		-scheme $(SCHEME) \
		-configuration $(CONFIGURATION)
	@rm -rf DerivedData
	@rm -rf build
	@rm -rf TestResults.xcresult
	@echo "$(GREEN)✓ Clean complete$(NC)"

#------------------------------------------------------------------------------
# Quality Checks
#------------------------------------------------------------------------------

## Run all quality checks (lint, format-check, test, build)
quality: lint format-check build test
	@echo "$(GREEN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo "$(GREEN)✓ All quality checks passed!$(NC)"
	@echo "$(GREEN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"

## Run quick quality checks (lint, build)
quality-quick: lint build
	@echo "$(GREEN)✓ Quick quality checks passed!$(NC)"

## Run dead code detection
dead-code:
	@echo "$(CYAN)Running dead code detection...$(NC)"
	@./scripts/dead-code.sh

## Run duplicate code detection
duplicates:
	@echo "$(CYAN)Running duplicate code detection...$(NC)"
	@./scripts/duplicate-code.sh

## Check for stale feature flags
stale-flags:
	@echo "$(CYAN)Checking for stale feature flags...$(NC)"
	@./scripts/stale-flags.sh

#------------------------------------------------------------------------------
# Reports
#------------------------------------------------------------------------------

## Generate all tech debt and quality reports
report: tech-debt stale-flags dead-code duplicates
	@echo "$(GREEN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo "$(GREEN)✓ All reports generated in docs/$(NC)"
	@echo "$(GREEN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@ls -la docs/*.md 2>/dev/null || true

## Generate tech debt report (TODOs, FIXMEs, HACKs)
tech-debt:
	@echo "$(CYAN)Generating tech debt report...$(NC)"
	@./scripts/tech-debt-report.sh

#------------------------------------------------------------------------------
# Development
#------------------------------------------------------------------------------

## Open project in Xcode
open:
	@open $(PROJECT_NAME).xcodeproj

## Generate Xcode project (if using Swift Package Manager)
generate:
	@echo "$(CYAN)Generating Xcode project...$(NC)"
	@swift package generate-xcodeproj || echo "Not a Swift Package"

## Update Swift packages
update-packages:
	@echo "$(CYAN)Updating Swift packages...$(NC)"
	@xcodebuild -resolvePackageDependencies \
		-project $(PROJECT_NAME).xcodeproj \
		-scheme $(SCHEME)
	@echo "$(GREEN)✓ Packages updated$(NC)"

## Show outdated dependencies (requires swift-outdated)
outdated:
	@echo "$(CYAN)Checking for outdated packages...$(NC)"
	@which swift-outdated > /dev/null || (echo "Install with: brew install swift-outdated" && exit 1)
	@swift-outdated

#------------------------------------------------------------------------------
# CI/CD
#------------------------------------------------------------------------------

## Run CI pipeline locally (quality + coverage)
ci: clean quality coverage
	@echo "$(GREEN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo "$(GREEN)✓ CI pipeline passed!$(NC)"
	@echo "$(GREEN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"

## Archive for distribution
archive:
	@echo "$(CYAN)Creating archive...$(NC)"
	@xcodebuild archive \
		-project $(PROJECT_NAME).xcodeproj \
		-scheme $(SCHEME) \
		-archivePath build/$(PROJECT_NAME).xcarchive \
		-configuration Release \
		CODE_SIGNING_ALLOWED=NO
	@echo "$(GREEN)✓ Archive created at build/$(PROJECT_NAME).xcarchive$(NC)"

#------------------------------------------------------------------------------
# Help
#------------------------------------------------------------------------------

## Show this help message
help:
	@echo ""
	@echo "$(CYAN)SkinLab iOS Project$(NC)"
	@echo "$(CYAN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo ""
	@echo "$(YELLOW)Usage:$(NC) make [target]"
	@echo ""
	@echo "$(YELLOW)Setup:$(NC)"
	@echo "  setup           Install all required development tools"
	@echo ""
	@echo "$(YELLOW)Code Quality:$(NC)"
	@echo "  lint            Run SwiftLint to check code style"
	@echo "  lint-fix        Run SwiftLint with auto-fix"
	@echo "  format          Run SwiftFormat to format code"
	@echo "  format-check    Check formatting without changes"
	@echo ""
	@echo "$(YELLOW)Testing:$(NC)"
	@echo "  test            Run unit tests"
	@echo "  test-ui         Run UI tests"
	@echo "  test-all        Run all tests"
	@echo "  coverage        Show code coverage report"
	@echo ""
	@echo "$(YELLOW)Building:$(NC)"
	@echo "  build           Build project (Debug)"
	@echo "  build-release   Build project (Release)"
	@echo "  clean           Clean build artifacts"
	@echo "  archive         Create archive for distribution"
	@echo ""
	@echo "$(YELLOW)Quality:$(NC)"
	@echo "  quality         Run all quality checks"
	@echo "  quality-quick   Run quick quality checks"
	@echo "  dead-code       Detect unused code"
	@echo "  duplicates      Detect duplicate code"
	@echo "  stale-flags     Check for stale feature flags"
	@echo ""
	@echo "$(YELLOW)Reports:$(NC)"
	@echo "  report          Generate all quality reports"
	@echo "  tech-debt       Generate tech debt report"
	@echo ""
	@echo "$(YELLOW)Development:$(NC)"
	@echo "  open            Open project in Xcode"
	@echo "  update-packages Update Swift packages"
	@echo "  outdated        Check for outdated packages"
	@echo ""
	@echo "$(YELLOW)CI/CD:$(NC)"
	@echo "  ci              Run CI pipeline locally"
	@echo ""
