#!/usr/bin/env bash
# Helper script to update superpowers plugin hash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULE_FILE="$SCRIPT_DIR/../modules/home-manager/ai-code-assistants.nix"

echo "🔍 Fetching latest superpowers from GitHub..."
NEW_HASH=$(nix-prefetch-url --unpack https://github.com/obra/superpowers/archive/refs/heads/main.tar.gz 2>/dev/null | tail -n1)

if [ -z "$NEW_HASH" ]; then
  echo "❌ Failed to fetch hash"
  exit 1
fi

echo "✅ New hash: $NEW_HASH"
echo ""
echo "📝 Update the hash in: $MODULE_FILE"
echo ""
echo "Change this line:"
echo '  sha256 = "sha256-OLD_HASH";'
echo ""
echo "To:"
echo "  sha256 = \"sha256-$NEW_HASH\";"
echo ""
echo "Then run: home-manager switch"
