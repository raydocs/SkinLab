#!/bin/bash
# Run SwiftLint on the project
# Usage: ./scripts/lint.sh [--fix]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

# Check if SwiftLint is installed
if ! command -v swiftlint &> /dev/null; then
    echo "❌ SwiftLint is not installed."
    echo "   Install with: brew install swiftlint"
    exit 1
fi

echo "🔍 Running SwiftLint..."

if [[ "$1" == "--fix" ]]; then
    echo "   Mode: Auto-fix enabled"
    swiftlint lint --fix --config .swiftlint.yml
    swiftlint lint --config .swiftlint.yml
else
    swiftlint lint --config .swiftlint.yml
fi

echo "✅ SwiftLint completed successfully"
