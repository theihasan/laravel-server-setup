#!/bin/bash

#############################################################################
# Laravel Server Setup Script - Version 3.0 - Installer
# 
# This script downloads the complete v3.0 setup and runs it.
# 
# Usage: bash <(curl -fsSL https://raw.githubusercontent.com/theihasan/laravel-server-setup/main/install-v3.sh)
#
# Author: FIGLAB
# Repository: https://github.com/theihasan/laravel-server-setup
#############################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
GITHUB_REPO="theihasan/laravel-server-setup"
GITHUB_BRANCH="main"
INSTALL_DIR="/tmp/laravel-server-setup-v3-$$"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}   Laravel Server Setup v3.0 - Installer${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}[✗]${NC} This script must be run as root"
   echo -e "${YELLOW}[→]${NC} Please run: sudo bash <(curl -fsSL ...)"
   exit 1
fi

# Check for required commands
echo -e "${CYAN}[→]${NC} Checking prerequisites..."

if ! command -v curl &> /dev/null; then
    echo -e "${YELLOW}[!]${NC} curl not found. Installing..."
    apt-get update -qq && apt-get install -y curl -qq
fi

if ! command -v git &> /dev/null; then
    echo -e "${YELLOW}[!]${NC} git not found. Installing..."
    apt-get update -qq && apt-get install -y git -qq
fi

echo -e "${GREEN}[✓]${NC} Prerequisites satisfied"
echo

# Download the complete setup
echo -e "${CYAN}[→]${NC} Downloading Laravel Server Setup v3.0..."

# Create temp directory
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# Clone the repository
if git clone --depth 1 --branch "$GITHUB_BRANCH" "https://github.com/${GITHUB_REPO}.git" . &> /dev/null; then
    echo -e "${GREEN}[✓]${NC} Downloaded successfully"
else
    echo -e "${RED}[✗]${NC} Failed to download from GitHub"
    echo -e "${YELLOW}[→]${NC} Please check your internet connection or try again later"
    rm -rf "$INSTALL_DIR"
    exit 1
fi

# Verify files exist
if [[ ! -f "setup-v3.sh" ]]; then
    echo -e "${RED}[✗]${NC} setup-v3.sh not found in repository"
    rm -rf "$INSTALL_DIR"
    exit 1
fi

if [[ ! -d "modules" ]]; then
    echo -e "${RED}[✗]${NC} modules directory not found in repository"
    rm -rf "$INSTALL_DIR"
    exit 1
fi

# Make script executable
chmod +x setup-v3.sh

echo -e "${GREEN}[✓]${NC} Setup files ready"
echo
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}   Starting Laravel Server Setup v3.0...${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo

# Run the main setup script
./setup-v3.sh

# Cleanup
SETUP_EXIT_CODE=$?
echo
echo -e "${CYAN}[→]${NC} Cleaning up temporary files..."
cd /
rm -rf "$INSTALL_DIR"
echo -e "${GREEN}[✓]${NC} Cleanup complete"

# Exit with the setup script's exit code
exit $SETUP_EXIT_CODE
