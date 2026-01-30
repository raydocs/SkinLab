#!/bin/bash
# Install development tools and pre-commit hooks
# Usage: ./scripts/install-hooks.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

echo "🚀 Setting up SkinLab development environment..."
echo ""

# Check for Homebrew
if ! command -v brew &> /dev/null; then
    echo "❌ Homebrew is not installed."
    echo "   Install from: https://brew.sh"
    exit 1
fi

# Install SwiftLint
if ! command -v swiftlint &> /dev/null; then
    echo "📦 Installing SwiftLint..."
    brew install swiftlint
else
    echo "✅ SwiftLint already installed"
fi

# Install SwiftFormat
if ! command -v swiftformat &> /dev/null; then
    echo "📦 Installing SwiftFormat..."
    brew install swiftformat
else
    echo "✅ SwiftFormat already installed"
fi

# Install pre-commit
if ! command -v pre-commit &> /dev/null; then
    echo "📦 Installing pre-commit..."
    brew install pre-commit
else
    echo "✅ pre-commit already installed"
fi

# Install pre-commit hooks
echo ""
echo "🔗 Installing pre-commit hooks..."
pre-commit install

# Make scripts executable
echo ""
echo "🔧 Making scripts executable..."
chmod +x "$SCRIPT_DIR"/*.sh

# Verify setup
echo ""
echo "🔍 Verifying installation..."
echo "   SwiftLint: $(swiftlint version)"
echo "   SwiftFormat: $(swiftformat --version)"
echo "   pre-commit: $(pre-commit --version)"

echo ""
echo "✅ Development environment setup complete!"
echo ""
echo "Available commands:"
echo "   ./scripts/lint.sh        - Run SwiftLint"
echo "   ./scripts/lint.sh --fix  - Run SwiftLint with auto-fix"
echo "   ./scripts/format.sh      - Format code with SwiftFormat"
echo "   pre-commit run --all-files - Run all pre-commit hooks"
