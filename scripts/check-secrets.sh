#!/bin/bash
# Check for potential secrets in staged files
# Used by pre-commit hook

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

# Patterns that indicate potential secrets
PATTERNS=(
    "GEMINI_API_KEY\s*=\s*['\"][^'\"]+['\"]"
    "API_KEY\s*=\s*['\"][^'\"]+['\"]"
    "SECRET\s*=\s*['\"][^'\"]+['\"]"
    "PASSWORD\s*=\s*['\"][^'\"]+['\"]"
    "TOKEN\s*=\s*['\"][^'\"]+['\"]"
    "PRIVATE_KEY"
    "-----BEGIN.*PRIVATE KEY-----"
    "AIza[0-9A-Za-z_-]{35}"  # Google API Key
    "sk-[a-zA-Z0-9]{48}"     # OpenAI API Key
    "ghp_[a-zA-Z0-9]{36}"    # GitHub Personal Access Token
)

# Files to check (staged or all Swift/config files)
if git rev-parse --git-dir > /dev/null 2>&1; then
    FILES=$(git diff --cached --name-only --diff-filter=ACM | grep -E '\.(swift|plist|xcconfig|json|yml|yaml)$' || true)
else
    FILES=$(find . -type f \( -name "*.swift" -o -name "*.plist" -o -name "*.xcconfig" -o -name "*.json" -o -name "*.yml" -o -name "*.yaml" \) -not -path "./Pods/*" -not -path "./DerivedData/*" -not -path "./.build/*")
fi

if [[ -z "$FILES" ]]; then
    exit 0
fi

FOUND_SECRETS=0

for pattern in "${PATTERNS[@]}"; do
    while IFS= read -r file; do
        if [[ -f "$file" ]]; then
            # Skip template files
            if [[ "$file" == *".template"* ]] || [[ "$file" == *"Template"* ]]; then
                continue
            fi

            if grep -qE "$pattern" "$file" 2>/dev/null; then
                echo "❌ Potential secret found in: $file"
                echo "   Pattern: $pattern"
                FOUND_SECRETS=1
            fi
        fi
    done <<< "$FILES"
done

if [[ $FOUND_SECRETS -eq 1 ]]; then
    echo ""
    echo "⚠️  Secrets detected! Please remove them before committing."
    echo "   Use environment variables or Secrets.xcconfig instead."
    exit 1
fi

exit 0
