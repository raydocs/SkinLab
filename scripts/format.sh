#!/bin/bash
# Run SwiftFormat on the project
# Usage: ./scripts/format.sh [--check]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

# Check if SwiftFormat is installed
if ! command -v swiftformat &> /dev/null; then
    echo "❌ SwiftFormat is not installed."
    echo "   Install with: brew install swiftformat"
    exit 1
fi

echo "🎨 Running SwiftFormat..."

if [[ "$1" == "--check" ]]; then
    echo "   Mode: Check only (no changes)"
    swiftformat --lint .
else
    echo "   Mode: Format in place"
    swiftformat .
fi

echo "✅ SwiftFormat completed successfully"
