#!/usr/bin/env bash
# Interactive configuration switcher with fzf
set -euo pipefail

FLAKE_DIR="${FLAKE_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check fzf is available
check_fzf() {
    if ! command -v fzf &> /dev/null; then
        echo -e "${RED}Error: fzf is required but not installed${NC}"
        echo "Install with: nix-shell -p fzf"
        exit 1
    fi
}

# Get all configurations from flake
get_configs() {
    cd "$FLAKE_DIR"

    # Darwin configurations
    nix eval .#darwinConfigurations --apply 'x: builtins.attrNames x' --json 2>/dev/null | \
        jq -r '.[]' | while read -r name; do
            echo "darwin:$name"
        done

    # NixOS configurations
    nix eval .#nixosConfigurations --apply 'x: builtins.attrNames x' --json 2>/dev/null | \
        jq -r '.[]' | while read -r name; do
            echo "nixos:$name"
        done

    # Home Manager configurations
    nix eval .#homeConfigurations --apply 'x: builtins.attrNames x' --json 2>/dev/null | \
        jq -r '.[]' | while read -r name; do
            echo "home:$name"
        done
}

# Format for display
format_config() {
    local config="$1"
    local type="${config%%:*}"
    local name="${config#*:}"

    case "$type" in
        darwin)
            echo -e "${GREEN}󰀵 darwin${NC}  $name"
            ;;
        nixos)
            echo -e "${BLUE} nixos${NC}   $name"
            ;;
        home)
            echo -e "${YELLOW} home${NC}    $name"
            ;;
    esac
}

# Build command for selected config
build_command() {
    local config="$1"
    local action="${2:-switch}"
    local type="${config%%:*}"
    local name="${config#*:}"

    case "$type" in
        darwin)
            echo "darwin-rebuild $action --flake $FLAKE_DIR#$name"
            ;;
        nixos)
            echo "sudo nixos-rebuild $action --flake $FLAKE_DIR#$name"
            ;;
        home)
            echo "home-manager $action --flake $FLAKE_DIR#$name"
            ;;
    esac
}

# Main
main() {
    local action="${1:-switch}"

    check_fzf

    echo -e "${BLUE}Loading configurations...${NC}" >&2

    # Get configs and let user select
    local configs
    configs=$(get_configs)

    if [[ -z "$configs" ]]; then
        echo -e "${RED}No configurations found${NC}"
        exit 1
    fi

    # Create display list
    local display_list=""
    while IFS= read -r config; do
        display_list+="$(format_config "$config")"$'\n'
    done <<< "$configs"

    # fzf selection
    local selected
    selected=$(echo -e "$display_list" | fzf \
        --ansi \
        --height=40% \
        --reverse \
        --border=rounded \
        --prompt="Select configuration > " \
        --header="Action: $action | ↑↓ to navigate, Enter to select, Esc to cancel" \
        --preview-window=hidden)

    if [[ -z "$selected" ]]; then
        echo -e "${YELLOW}Cancelled${NC}"
        exit 0
    fi

    # Parse selection back to config format
    local type name config
    if [[ "$selected" == *"darwin"* ]]; then
        type="darwin"
    elif [[ "$selected" == *"nixos"* ]]; then
        type="nixos"
    elif [[ "$selected" == *"home"* ]]; then
        type="home"
    fi

    # Extract name (last word)
    name=$(echo "$selected" | awk '{print $NF}')
    config="$type:$name"

    # Build and execute
    local cmd
    cmd=$(build_command "$config" "$action")

    echo ""
    echo -e "${GREEN}Running:${NC} $cmd"
    echo ""

    eval "$cmd"
}

# Help
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    echo "Usage: $(basename "$0") [action]"
    echo ""
    echo "Actions:"
    echo "  switch  - Build and activate (default)"
    echo "  build   - Build only"
    echo "  test    - Build and activate temporarily (NixOS only)"
    echo ""
    echo "Examples:"
    echo "  $(basename "$0")          # switch"
    echo "  $(basename "$0") build    # build only"
    exit 0
fi

main "${1:-switch}"
