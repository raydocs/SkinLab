#!/bin/bash
# Check for large files that shouldn't be committed
# Used by pre-commit hook

set -e

# Maximum file size in bytes (5MB)
MAX_SIZE=5242880

# Get staged files
if git rev-parse --git-dir > /dev/null 2>&1; then
    FILES=$(git diff --cached --name-only --diff-filter=ACM 2>/dev/null || true)
else
    exit 0
fi

if [[ -z "$FILES" ]]; then
    exit 0
fi

FOUND_LARGE=0

while IFS= read -r file; do
    if [[ -f "$file" ]]; then
        size=$(wc -c < "$file" | tr -d ' ')
        if [[ $size -gt $MAX_SIZE ]]; then
            size_mb=$(echo "scale=2; $size / 1048576" | bc)
            echo "❌ Large file detected: $file (${size_mb}MB)"
            FOUND_LARGE=1
        fi
    fi
done <<< "$FILES"

if [[ $FOUND_LARGE -eq 1 ]]; then
    echo ""
    echo "⚠️  Large files detected! Consider using Git LFS for these files."
    echo "   Max allowed size: 5MB"
    exit 1
fi

exit 0
