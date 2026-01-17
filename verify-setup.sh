#!/bin/bash

# Verification script for Laravel Server Setup v3.0

echo "╔════════════════════════════════════════════════════════════════════╗"
echo "║  Laravel Server Setup v3.0 - Installation Verification            ║"
echo "╚════════════════════════════════════════════════════════════════════╝"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "⚠️  Warning: Some checks may require root privileges"
    echo ""
fi

# Check main script
echo "📋 Checking installation files..."
echo ""

if [ -f "setup-v3.sh" ]; then
    echo "  ✓ Main script: setup-v3.sh found"
else
    echo "  ✗ Main script: setup-v3.sh NOT FOUND"
fi

# Check modules
echo ""
echo "📦 Checking modules..."
echo ""

MODULES=(webservers databases laravel queue cron monitoring)
for module in "${MODULES[@]}"; do
    if [ -f "modules/${module}.sh" ]; then
        echo "  ✓ Module: ${module}.sh found"
    else
        echo "  ✗ Module: ${module}.sh NOT FOUND"
    fi
done

# Check documentation
echo ""
echo "📚 Checking documentation..."
echo ""

DOCS=(README-V3.md QUICKSTART.md IMPLEMENTATION-SUMMARY.md)
for doc in "${DOCS[@]}"; do
    if [ -f "$doc" ]; then
        echo "  ✓ Documentation: $doc found"
    else
        echo "  ✗ Documentation: $doc NOT FOUND"
    fi
done

# Check directories
echo ""
echo "📁 Checking directories..."
echo ""

if [ -d "modules" ]; then
    echo "  ✓ Directory: modules/ found"
else
    echo "  ✗ Directory: modules/ NOT FOUND"
fi

if [ -d "templates" ]; then
    echo "  ✓ Directory: templates/ found"
else
    echo "  ✗ Directory: templates/ NOT FOUND"
fi

if [ -d "dashboards" ]; then
    echo "  ✓ Directory: dashboards/ found"
else
    echo "  ✗ Directory: dashboards/ NOT FOUND"
fi

# Check permissions
echo ""
echo "🔐 Checking permissions..."
echo ""

if [ -x "setup-v3.sh" ]; then
    echo "  ✓ setup-v3.sh is executable"
else
    echo "  ✗ setup-v3.sh is NOT executable (run: chmod +x setup-v3.sh)"
fi

# Summary
echo ""
echo "════════════════════════════════════════════════════════════════════"
echo "✅ Verification complete!"
echo ""
echo "To run the setup:"
echo "  sudo ./setup-v3.sh"
echo ""
echo "For quick start guide:"
echo "  cat QUICKSTART.md"
echo ""
echo "For full documentation:"
echo "  cat README-V3.md"
echo "════════════════════════════════════════════════════════════════════"
