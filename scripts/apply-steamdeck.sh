#!/usr/bin/env bash
# Apply Home Manager configuration for Steam Deck
set -e

FLAKE_DIR="${FLAKE_DIR:-$HOME/my-nixos}"

echo "=== Steam Deck Home Manager Setup ==="

# Check if Nix is installed
if ! command -v nix &> /dev/null; then
    echo "Nix not found. Installing..."
    curl -L https://nixos.org/nix/install | sh -s -- --daemon
    echo "Please restart your shell and run this script again."
    exit 0
fi

# Enable flakes if not already enabled
if ! grep -q "experimental-features" ~/.config/nix/nix.conf 2>/dev/null; then
    echo "Enabling Nix flakes..."
    mkdir -p ~/.config/nix
    echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
fi

# Apply Home Manager configuration
echo "Applying Home Manager configuration..."
nix run home-manager -- switch --flake "${FLAKE_DIR}#deck@steamdeck"

echo ""
echo "=== Done! ==="
echo "Installed: VSCode, OpenCode, Claude Code, MCP servers"
echo "Run 'claude' or 'opencode' to start coding!"
