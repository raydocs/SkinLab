#!/bin/bash

# Tech Debt Report Generator
# Scans codebase for TODOs, FIXMEs, HACKs and generates a markdown report

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
REPORT_FILE="${PROJECT_ROOT}/docs/TECH_DEBT_REPORT.md"
SOURCE_DIR="${PROJECT_ROOT}/SkinLab"

# Colors for terminal output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo "🔍 Scanning for tech debt markers..."

# Create report header
cat > "$REPORT_FILE" << EOF
# Tech Debt Report

Generated: $(date '+%Y-%m-%d %H:%M:%S')

## Summary

EOF

# Count occurrences
TODO_COUNT=$(grep -rn "TODO" "$SOURCE_DIR" --include="*.swift" 2>/dev/null | wc -l | tr -d ' ')
FIXME_COUNT=$(grep -rn "FIXME" "$SOURCE_DIR" --include="*.swift" 2>/dev/null | wc -l | tr -d ' ')
HACK_COUNT=$(grep -rn "HACK" "$SOURCE_DIR" --include="*.swift" 2>/dev/null | wc -l | tr -d ' ')
TEMP_COUNT=$(grep -rn "TEMP\|TEMPORARY" "$SOURCE_DIR" --include="*.swift" 2>/dev/null | wc -l | tr -d ' ')
DEPRECATED_COUNT=$(grep -rn "@available.*deprecated" "$SOURCE_DIR" --include="*.swift" 2>/dev/null | wc -l | tr -d ' ')
FORCE_UNWRAP_COUNT=$(grep -rn "![^=]" "$SOURCE_DIR" --include="*.swift" 2>/dev/null | grep -v "!=" | grep -v "//\|/\*" | wc -l | tr -d ' ')

TOTAL_COUNT=$((TODO_COUNT + FIXME_COUNT + HACK_COUNT + TEMP_COUNT))

# Write summary
cat >> "$REPORT_FILE" << EOF
| Marker | Count | Priority |
|--------|-------|----------|
| TODO | $TODO_COUNT | Low |
| FIXME | $FIXME_COUNT | Medium |
| HACK | $HACK_COUNT | High |
| TEMP/TEMPORARY | $TEMP_COUNT | High |
| Deprecated APIs | $DEPRECATED_COUNT | Medium |

**Total Tech Debt Items: $TOTAL_COUNT**

---

EOF

# Function to add section with items
add_section() {
    local marker=$1
    local priority=$2
    local emoji=$3

    echo "## $emoji $marker Items ($priority Priority)" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"

    results=$(grep -rn "$marker" "$SOURCE_DIR" --include="*.swift" 2>/dev/null || true)

    if [ -z "$results" ]; then
        echo "✅ No $marker items found." >> "$REPORT_FILE"
    else
        echo '```' >> "$REPORT_FILE"
        echo "$results" | while read -r line; do
            # Make paths relative
            relative_line="${line#$PROJECT_ROOT/}"
            echo "$relative_line"
        done >> "$REPORT_FILE"
        echo '```' >> "$REPORT_FILE"
    fi

    echo "" >> "$REPORT_FILE"
}

# Add sections for each marker
add_section "FIXME" "Medium" "🔧"
add_section "HACK" "High" "⚠️"
add_section "TEMP\|TEMPORARY" "High" "🚨"
add_section "TODO" "Low" "📝"

# Add deprecated APIs section
echo "## 📅 Deprecated API Usage" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

deprecated_results=$(grep -rn "@available.*deprecated" "$SOURCE_DIR" --include="*.swift" 2>/dev/null || true)

if [ -z "$deprecated_results" ]; then
    echo "✅ No deprecated API usage found." >> "$REPORT_FILE"
else
    echo '```' >> "$REPORT_FILE"
    echo "$deprecated_results" | while read -r line; do
        relative_line="${line#$PROJECT_ROOT/}"
        echo "$relative_line"
    done >> "$REPORT_FILE"
    echo '```' >> "$REPORT_FILE"
fi

echo "" >> "$REPORT_FILE"

# Add force unwrap warnings (potential crashes)
echo "## 💥 Force Unwrap Warnings" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "These force unwraps could cause crashes if the value is nil:" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# Look for patterns like variable! (but not != or comments)
force_unwraps=$(grep -rn "![^=\s]" "$SOURCE_DIR" --include="*.swift" 2>/dev/null | \
    grep -v "!=" | \
    grep -v "//.*!" | \
    grep -v "/\*.*!" | \
    head -50 || true)

if [ -z "$force_unwraps" ]; then
    echo "✅ No obvious force unwrap issues found." >> "$REPORT_FILE"
else
    echo '```' >> "$REPORT_FILE"
    echo "$force_unwraps" | while read -r line; do
        relative_line="${line#$PROJECT_ROOT/}"
        echo "$relative_line"
    done >> "$REPORT_FILE"
    echo '```' >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "> Note: Some force unwraps may be intentional (IBOutlets, known-good data). Review individually." >> "$REPORT_FILE"
fi

echo "" >> "$REPORT_FILE"

# Add recommendations
cat >> "$REPORT_FILE" << 'EOF'
---

## Recommendations

### High Priority (Address This Sprint)
- **HACK items**: These are known shortcuts that could cause issues
- **TEMP items**: Temporary code that should be removed or replaced

### Medium Priority (Address This Month)
- **FIXME items**: Known bugs or issues that need fixing
- **Deprecated APIs**: Will break in future iOS versions

### Low Priority (Backlog)
- **TODO items**: Future improvements and features

### Best Practices
1. Add ticket numbers to TODOs: `// TODO: [SKIN-123] Implement caching`
2. Include context: `// FIXME: This fails when user has no photos`
3. Set deadlines for TEMP code: `// TEMP: Remove after v2.0 launch`
4. Regularly review and clean up tech debt

EOF

# Print summary to terminal
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "                    📊 Tech Debt Report Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ "$HACK_COUNT" -gt 0 ] || [ "$TEMP_COUNT" -gt 0 ]; then
    echo -e "  ${RED}🚨 HIGH PRIORITY${NC}"
    echo -e "     HACK items:      $HACK_COUNT"
    echo -e "     TEMP items:      $TEMP_COUNT"
fi

if [ "$FIXME_COUNT" -gt 0 ] || [ "$DEPRECATED_COUNT" -gt 0 ]; then
    echo -e "  ${YELLOW}⚠️  MEDIUM PRIORITY${NC}"
    echo -e "     FIXME items:     $FIXME_COUNT"
    echo -e "     Deprecated APIs: $DEPRECATED_COUNT"
fi

echo -e "  ${GREEN}📝 LOW PRIORITY${NC}"
echo -e "     TODO items:      $TODO_COUNT"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "  Total tech debt items: ${YELLOW}$TOTAL_COUNT${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📄 Full report saved to: $REPORT_FILE"
echo ""
