#!/bin/bash

# Dead Code Detection Script
# Uses Periphery to detect unused code in the Swift project

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
REPORT_FILE="${PROJECT_ROOT}/docs/DEAD_CODE_REPORT.md"

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "              🧹 Dead Code Detection"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if Periphery is installed
check_periphery() {
    if command -v periphery &> /dev/null; then
        echo -e "${GREEN}✓ Periphery is installed${NC}"
        periphery version
        return 0
    else
        echo -e "${RED}✗ Periphery is not installed${NC}"
        return 1
    fi
}

# Install Periphery
install_periphery() {
    echo ""
    echo "📦 Installing Periphery..."
    echo ""

    if command -v brew &> /dev/null; then
        echo "Using Homebrew..."
        brew install peripheryapp/periphery/periphery
    elif command -v mint &> /dev/null; then
        echo "Using Mint..."
        mint install peripheryapp/periphery
    else
        echo -e "${YELLOW}Please install Periphery manually:${NC}"
        echo ""
        echo "  Option 1: Homebrew"
        echo "    brew install peripheryapp/periphery/periphery"
        echo ""
        echo "  Option 2: Mint"
        echo "    mint install peripheryapp/periphery"
        echo ""
        echo "  Option 3: Download release"
        echo "    https://github.com/peripheryapp/periphery/releases"
        echo ""
        exit 1
    fi
}

# Generate Periphery configuration if not exists
generate_config() {
    local config_file="${PROJECT_ROOT}/.periphery.yml"

    if [ ! -f "$config_file" ]; then
        echo "📝 Generating Periphery configuration..."

        cat > "$config_file" << 'EOF'
# Periphery Configuration
# See: https://github.com/peripheryapp/periphery

project: SkinLab.xcodeproj
schemes:
  - SkinLab
targets:
  - SkinLab

# Retain declarations even if unused
retain_public: false
retain_objc_accessible: true
retain_unused_protocol_func_params: false

# Skip specific patterns
index_exclude:
  - "**/*Tests*"
  - "**/*Mock*"
  - "**/Preview Content/*"
  - "**/Generated/*"

# Output format
format: xcode
EOF
        echo -e "${GREEN}✓ Created .periphery.yml${NC}"
    fi
}

# Run Periphery scan
run_periphery() {
    echo ""
    echo "🔍 Running dead code analysis..."
    echo "   This may take a few minutes for large projects..."
    echo ""

    cd "$PROJECT_ROOT"

    # Run Periphery and capture output
    periphery_output=$(periphery scan 2>&1 || true)

    # Count issues
    unused_count=$(echo "$periphery_output" | grep -c "is unused" || echo "0")
    redundant_count=$(echo "$periphery_output" | grep -c "is redundant" || echo "0")

    total_count=$((unused_count + redundant_count))

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "              📊 Analysis Results"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo -e "  ${CYAN}Unused declarations:${NC}     $unused_count"
    echo -e "  ${YELLOW}Redundant protocols:${NC}    $redundant_count"
    echo -e "  ${RED}Total issues:${NC}           $total_count"
    echo ""

    # Generate markdown report
    generate_report "$periphery_output" "$unused_count" "$redundant_count"
}

# Generate markdown report
generate_report() {
    local output=$1
    local unused=$2
    local redundant=$3

    cat > "$REPORT_FILE" << EOF
# Dead Code Analysis Report

Generated: $(date '+%Y-%m-%d %H:%M:%S')
Tool: Periphery

## Summary

| Category | Count |
|----------|-------|
| Unused Declarations | $unused |
| Redundant Protocols | $redundant |
| **Total** | **$((unused + redundant))** |

## Unused Code

EOF

    echo '```' >> "$REPORT_FILE"
    echo "$output" | grep "is unused" | head -100 >> "$REPORT_FILE" || echo "No unused code found." >> "$REPORT_FILE"
    echo '```' >> "$REPORT_FILE"

    cat >> "$REPORT_FILE" << 'EOF'

## Redundant Protocols

EOF

    echo '```' >> "$REPORT_FILE"
    echo "$output" | grep "is redundant" | head -50 >> "$REPORT_FILE" || echo "No redundant protocols found." >> "$REPORT_FILE"
    echo '```' >> "$REPORT_FILE"

    cat >> "$REPORT_FILE" << 'EOF'

## Recommendations

### Before Removing Code
1. **Verify it's truly unused**: Check for dynamic references, reflection, or @objc
2. **Check for future use**: Review if code is planned for upcoming features
3. **Look for interface builders**: XIB/Storyboard connections may not be detected
4. **Consider public APIs**: Public interfaces may be used by external consumers

### Safe to Remove
- Private methods with no references
- Internal classes only used in removed features
- Protocol conformances that don't add functionality
- Unused parameters in private functions

### Might Be False Positives
- @IBAction and @IBOutlet (if using Interface Builder)
- @objc methods called from Objective-C
- Codable properties (used for encoding/decoding)
- SwiftUI Preview providers

### Cleanup Process
1. Create a dedicated cleanup branch
2. Remove code in small batches
3. Build and run tests after each batch
4. Review diff before merging

## Configuration

To customize Periphery behavior, edit `.periphery.yml`:

```yaml
# Retain public declarations
retain_public: true

# Exclude test files
index_exclude:
  - "**/*Tests*"
  - "**/Mock*"
```

## Running Manually

```bash
# Full scan
periphery scan

# Scan specific targets
periphery scan --targets SkinLab

# Output as JSON for processing
periphery scan --format json > dead_code.json

# Quiet mode (just counts)
periphery scan --quiet
```

EOF

    echo "📄 Full report saved to: $REPORT_FILE"
}

# Main execution
if ! check_periphery; then
    echo ""
    read -p "Would you like to install Periphery? [y/N] " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        install_periphery
    else
        echo ""
        echo "Please install Periphery and run this script again."
        exit 1
    fi
fi

generate_config
run_periphery

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${GREEN}✓ Dead code analysis complete!${NC}"
echo ""
