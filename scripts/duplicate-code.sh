#!/bin/bash

# Duplicate Code Detection Script
# Uses PMD's CPD (Copy-Paste Detector) to find duplicate code

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SOURCE_DIR="${PROJECT_ROOT}/SkinLab"
REPORT_FILE="${PROJECT_ROOT}/docs/DUPLICATE_CODE_REPORT.md"
MIN_TOKENS=50  # Minimum tokens for duplicate detection

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "              📋 Duplicate Code Detection"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if PMD/CPD is installed
check_cpd() {
    if command -v pmd &> /dev/null; then
        echo -e "${GREEN}✓ PMD is installed${NC}"
        pmd --version
        return 0
    elif [ -f "${PROJECT_ROOT}/tools/pmd/bin/pmd" ]; then
        echo -e "${GREEN}✓ PMD found in tools directory${NC}"
        PMD_CMD="${PROJECT_ROOT}/tools/pmd/bin/pmd"
        return 0
    else
        echo -e "${RED}✗ PMD is not installed${NC}"
        return 1
    fi
}

# Install PMD
install_pmd() {
    echo ""
    echo "📦 Installing PMD..."
    echo ""

    if command -v brew &> /dev/null; then
        echo "Using Homebrew..."
        brew install pmd
    else
        echo "Downloading PMD manually..."

        mkdir -p "${PROJECT_ROOT}/tools"
        cd "${PROJECT_ROOT}/tools"

        # Download latest PMD release
        PMD_VERSION="7.0.0"
        curl -LO "https://github.com/pmd/pmd/releases/download/pmd_releases%2F${PMD_VERSION}/pmd-dist-${PMD_VERSION}-bin.zip"
        unzip -q "pmd-dist-${PMD_VERSION}-bin.zip"
        mv "pmd-bin-${PMD_VERSION}" pmd
        rm "pmd-dist-${PMD_VERSION}-bin.zip"

        PMD_CMD="${PROJECT_ROOT}/tools/pmd/bin/pmd"
        echo -e "${GREEN}✓ PMD installed to tools/pmd${NC}"
    fi
}

# Run CPD analysis
run_cpd() {
    echo ""
    echo "🔍 Analyzing code for duplicates..."
    echo "   Minimum token threshold: $MIN_TOKENS"
    echo ""

    local pmd_cmd=${PMD_CMD:-pmd}
    local temp_report="${PROJECT_ROOT}/cpd_output.txt"

    # Run CPD (Copy-Paste Detector)
    # Note: PMD 7.x uses 'pmd cpd' syntax
    if $pmd_cmd cpd --help &> /dev/null; then
        # PMD 7.x syntax
        $pmd_cmd cpd \
            --minimum-tokens "$MIN_TOKENS" \
            --language swift \
            --dir "$SOURCE_DIR" \
            --format text \
            --no-fail-on-violation \
            > "$temp_report" 2>&1 || true
    else
        # Older PMD syntax or try with run.sh
        $pmd_cmd cpd \
            --minimum-tokens "$MIN_TOKENS" \
            --language swift \
            --files "$SOURCE_DIR" \
            --format text \
            > "$temp_report" 2>&1 || true
    fi

    # Parse results
    if [ -f "$temp_report" ]; then
        duplicate_count=$(grep -c "Found a" "$temp_report" 2>/dev/null || echo "0")
        total_lines=$(grep "Found a" "$temp_report" | grep -oE "[0-9]+ line" | awk '{sum+=$1} END {print sum}' || echo "0")

        generate_report "$temp_report" "$duplicate_count" "$total_lines"
        rm -f "$temp_report"
    else
        echo "No output generated. Check PMD installation."
        exit 1
    fi
}

# Alternative: Simple duplicate detection without PMD
run_simple_detection() {
    echo ""
    echo "🔍 Running simple duplicate detection..."
    echo "   (Using basic pattern matching since PMD is not available)"
    echo ""

    # Find similar function signatures
    echo "Looking for similar function patterns..."

    local temp_report="${PROJECT_ROOT}/simple_cpd_output.txt"

    {
        echo "# Simple Duplicate Detection Results"
        echo ""
        echo "## Similar Function Signatures"
        echo ""

        # Find functions and group by similar names
        grep -rnh "func " "$SOURCE_DIR" --include="*.swift" 2>/dev/null | \
            sed 's/.*func /func /' | \
            sort | uniq -c | sort -rn | head -30

        echo ""
        echo "## Repeated Code Patterns"
        echo ""

        # Find repeated multi-line patterns (3+ lines)
        # This is a simple heuristic approach

        echo "### Similar Guard Statements"
        grep -rnh "guard let" "$SOURCE_DIR" --include="*.swift" 2>/dev/null | \
            sed 's/^[^:]*:[0-9]*://' | \
            sort | uniq -c | sort -rn | head -10

        echo ""
        echo "### Similar If Conditions"
        grep -rnh "if let\|if.*==" "$SOURCE_DIR" --include="*.swift" 2>/dev/null | \
            sed 's/^[^:]*:[0-9]*://' | \
            sort | uniq -c | sort -rn | head -10

    } > "$temp_report"

    generate_simple_report "$temp_report"
    rm -f "$temp_report"
}

# Generate markdown report from CPD output
generate_report() {
    local output_file=$1
    local dup_count=$2
    local total_lines=$3

    cat > "$REPORT_FILE" << EOF
# Duplicate Code Report

Generated: $(date '+%Y-%m-%d %H:%M:%S')
Tool: PMD CPD (Copy-Paste Detector)
Minimum Token Threshold: $MIN_TOKENS

## Summary

| Metric | Value |
|--------|-------|
| Duplicate Blocks Found | $dup_count |
| Total Duplicated Lines | ${total_lines:-0} |

## Duplicate Code Blocks

EOF

    echo '```' >> "$REPORT_FILE"
    cat "$output_file" >> "$REPORT_FILE"
    echo '```' >> "$REPORT_FILE"

    cat >> "$REPORT_FILE" << 'EOF'

## Understanding the Results

Each block shows:
- **Location**: File path and line numbers
- **Duplicate Count**: Number of times the code appears
- **Token Count**: Size of the duplicated code

## Recommendations

### When to Refactor
1. **Large duplicates (50+ tokens)**: Strong candidates for extraction
2. **Repeated in 3+ places**: Create a shared function
3. **Business logic duplication**: High priority for refactoring
4. **Similar but not identical**: Consider making parameterized

### Refactoring Strategies

#### Extract Method
```swift
// Before: Duplicate validation in multiple places
func createUser() {
    guard !name.isEmpty, name.count >= 2 else { return }
    // ...
}

func updateUser() {
    guard !name.isEmpty, name.count >= 2 else { return }
    // ...
}

// After: Extracted validation
func createUser() {
    guard isValidName(name) else { return }
    // ...
}

private func isValidName(_ name: String) -> Bool {
    return !name.isEmpty && name.count >= 2
}
```

#### Extract to Extension
```swift
// Create shared extensions for common patterns
extension String {
    var isValidName: Bool {
        !isEmpty && count >= 2
    }
}
```

#### Protocol Default Implementation
```swift
protocol Validatable {
    func validate() -> Bool
}

extension Validatable {
    func validate() -> Bool {
        // Shared validation logic
    }
}
```

### Acceptable Duplicates
- Test setup/teardown code
- Simple property getters
- Generated code (Codable, etc.)
- Boilerplate required by frameworks

## Running Manually

```bash
# Basic duplicate detection
pmd cpd --minimum-tokens 50 --language swift --dir SkinLab

# Stricter threshold
pmd cpd --minimum-tokens 30 --language swift --dir SkinLab

# Output as XML for CI
pmd cpd --minimum-tokens 50 --language swift --dir SkinLab --format xml > cpd.xml
```

EOF

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "              📊 Analysis Results"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo -e "  ${CYAN}Duplicate blocks found:${NC}  $dup_count"
    echo -e "  ${YELLOW}Total duplicated lines:${NC}  ${total_lines:-0}"
    echo ""
    echo "📄 Full report saved to: $REPORT_FILE"
}

# Generate simple report without PMD
generate_simple_report() {
    local output_file=$1

    cat > "$REPORT_FILE" << EOF
# Duplicate Code Report (Simple Detection)

Generated: $(date '+%Y-%m-%d %H:%M:%S')
Tool: Basic pattern matching (PMD not installed)

> ⚠️ For more accurate results, install PMD: \`brew install pmd\`

## Analysis Results

EOF

    cat "$output_file" >> "$REPORT_FILE"

    cat >> "$REPORT_FILE" << 'EOF'

## Install PMD for Better Analysis

```bash
# Using Homebrew
brew install pmd

# Or download manually
curl -LO https://github.com/pmd/pmd/releases/latest/download/pmd-dist-7.0.0-bin.zip
unzip pmd-dist-7.0.0-bin.zip
```

Then re-run this script for detailed duplicate detection.

EOF

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo -e "${YELLOW}⚠️  Using simple detection (PMD not installed)${NC}"
    echo ""
    echo "📄 Report saved to: $REPORT_FILE"
}

# Main execution
PMD_CMD=""

if check_cpd; then
    run_cpd
else
    echo ""
    read -p "Would you like to install PMD? [y/N] " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        install_pmd
        run_cpd
    else
        echo ""
        echo "Running simple duplicate detection instead..."
        run_simple_detection
    fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${GREEN}✓ Duplicate code analysis complete!${NC}"
echo ""
