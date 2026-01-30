#!/bin/bash

# Stale Feature Flags Detector
# Scans for potentially unused or stale feature flags

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SOURCE_DIR="${PROJECT_ROOT}/SkinLab"
REPORT_FILE="${PROJECT_ROOT}/docs/STALE_FLAGS_REPORT.md"

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

echo "🚩 Scanning for feature flags..."

# Common feature flag patterns
FLAG_PATTERNS=(
    "FeatureFlag"
    "isEnabled"
    "isFeatureEnabled"
    "feature_"
    "FF_"
    "FEATURE_"
    "enabledFeatures"
    "LaunchDarkly"
    "RemoteConfig"
    "featureFlags"
)

# Find potential feature flag definitions
find_flag_definitions() {
    echo "📍 Searching for feature flag definitions..."

    # Look for enum cases, static lets, or variable definitions
    grep -rn "enum.*Flag\|case.*Flag\|static.*let.*flag\|static.*var.*flag\|FeatureFlag\." \
        "$SOURCE_DIR" --include="*.swift" 2>/dev/null | head -100 || true
}

# Find feature flag usages
find_flag_usages() {
    local flag_name=$1
    grep -rn "$flag_name" "$SOURCE_DIR" --include="*.swift" 2>/dev/null | wc -l | tr -d ' '
}

# Check if flag is only defined but never used
check_unused_flags() {
    echo ""
    echo "🔍 Analyzing flag usage patterns..."

    # Find all potential flag definitions
    definitions=$(grep -rn "case \|static.*let.*:.*Bool\|static.*var.*:.*Bool" \
        "$SOURCE_DIR" --include="*.swift" 2>/dev/null | \
        grep -i "flag\|feature\|enable\|toggle" || true)

    echo "$definitions"
}

# Find flags that might be always true/false
find_hardcoded_flags() {
    echo ""
    echo "🔒 Checking for hardcoded flags..."

    # Look for flags that return constant values
    grep -rn "return true\|return false" "$SOURCE_DIR" --include="*.swift" 2>/dev/null | \
        grep -i "flag\|feature\|enabled" | head -20 || true
}

# Find old/dated feature flags
find_dated_flags() {
    echo ""
    echo "📅 Looking for dated feature flags..."

    # Look for flags with dates or version numbers in comments
    grep -rn "2023\|2024\|v1\.\|v2\.\|temporary\|remove after" "$SOURCE_DIR" \
        --include="*.swift" 2>/dev/null | \
        grep -i "flag\|feature\|todo\|fixme" | head -20 || true
}

# Generate report
generate_report() {
    cat > "$REPORT_FILE" << EOF
# Stale Feature Flags Report

Generated: $(date '+%Y-%m-%d %H:%M:%S')

## Overview

This report identifies potentially stale or unused feature flags that may need cleanup.

## Feature Flag Definitions Found

EOF

    echo '```swift' >> "$REPORT_FILE"
    find_flag_definitions >> "$REPORT_FILE"
    echo '```' >> "$REPORT_FILE"

    cat >> "$REPORT_FILE" << 'EOF'

## Potential Issues

### Hardcoded Flags
These flags appear to return constant values and might be candidates for removal:

```swift
EOF
    find_hardcoded_flags >> "$REPORT_FILE"
    echo '```' >> "$REPORT_FILE"

    cat >> "$REPORT_FILE" << 'EOF'

### Dated/Temporary Flags
These flags have dates or "temporary" markers and should be reviewed:

```swift
EOF
    find_dated_flags >> "$REPORT_FILE"
    echo '```' >> "$REPORT_FILE"

    cat >> "$REPORT_FILE" << 'EOF'

## Recommendations

### Cleanup Process
1. **Identify Rollout Status**: Check if feature is fully rolled out
2. **Verify Usage**: Confirm the flag is still needed
3. **Remove Dead Code**: Delete flag and all conditional code paths
4. **Update Tests**: Remove flag-related test variations
5. **Document**: Update any documentation referencing the flag

### Best Practices
- Add creation dates to feature flags
- Set expected cleanup dates for temporary flags
- Use consistent naming: `FeatureFlag.skinAnalysisV2`
- Document flag purpose in code comments
- Review flags quarterly

### Flag Lifecycle

```
Created → Testing → Rollout (%) → 100% → Cleanup → Removed
                        ↓
                    (if failed)
                        ↓
                    Rollback → Cleanup
```

## Action Items

| Flag | Status | Action | Owner |
|------|--------|--------|-------|
| (Add identified flags here) | | | |

EOF
}

# Main execution
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "              🚩 Feature Flag Analysis"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Count flag occurrences
flag_def_count=$(find_flag_definitions | wc -l | tr -d ' ')
hardcoded_count=$(find_hardcoded_flags | wc -l | tr -d ' ')
dated_count=$(find_dated_flags | wc -l | tr -d ' ')

echo ""
echo -e "  ${CYAN}Flag definitions found:${NC}    $flag_def_count"
echo -e "  ${YELLOW}Potentially hardcoded:${NC}    $hardcoded_count"
echo -e "  ${RED}Dated/temporary flags:${NC}    $dated_count"
echo ""

# Generate the report
generate_report

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📄 Full report saved to: $REPORT_FILE"
echo ""

# Recommendations
if [ "$hardcoded_count" -gt 0 ] || [ "$dated_count" -gt 0 ]; then
    echo -e "${YELLOW}⚠️  Recommendations:${NC}"
    if [ "$hardcoded_count" -gt 0 ]; then
        echo "   - Review $hardcoded_count hardcoded flags for removal"
    fi
    if [ "$dated_count" -gt 0 ]; then
        echo "   - Check $dated_count dated flags for cleanup"
    fi
    echo ""
fi
