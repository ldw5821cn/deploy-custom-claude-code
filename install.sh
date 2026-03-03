#!/usr/bin/env bash
# Claude Custom Manager Installer
# Usage: curl -fsSL https://.../install.sh | sudo bash

set -e

REPO="${REPO:-SSBun/deploy-custom-claude-code}"
BRANCH="${BRANCH:-main}"
SCRIPT_URL="https://raw.githubusercontent.com/$REPO/$BRANCH/claude-custom"
INSTALL_DIR="/usr/local/bin"
CONFIG_DIR="$HOME/.claude-custom"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=== Claude Custom Manager Installer ==="
echo ""

# Check for sudo
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Error: Please run with sudo${NC}"
  echo "  sudo curl -fsSL https://raw.githubusercontent.com/$REPO/$BRANCH/install.sh | bash"
  exit 4
fi

# Download claude-custom
echo -e "${YELLOW}Downloading claude-custom...${NC}"
if ! curl -fsSL "$SCRIPT_URL" -o "$INSTALL_DIR/claude-custom"; then
    echo -e "${RED}Error: Failed to download claude-custom${NC}"
    exit 1
fi
chmod +x "$INSTALL_DIR/claude-custom"
echo -e "${GREEN}✓ Installed to $INSTALL_DIR/claude-custom${NC}"

# Create config directory
if [ ! -d "$CONFIG_DIR" ]; then
    mkdir -p "$CONFIG_DIR"
    echo -e "${GREEN}✓ Created config directory: $CONFIG_DIR${NC}"
fi

# Check for jq
if ! command -v jq &> /dev/null; then
    echo ""
    echo -e "${YELLOW}jq is required but not installed.${NC}"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "Install with: brew install jq"
    else
        echo "Install with: sudo apt-get install jq"
    fi
    echo -e "${YELLOW}Please install jq, then run: claude-custom --help${NC}"
else
    echo -e "${GREEN}✓ jq is installed${NC}"
fi

echo ""
echo -e "${GREEN}=== Installation Complete! ===${NC}"
echo ""
echo "Run: claude-custom --help"
echo "Add a deployment: claude-custom add <name>"
