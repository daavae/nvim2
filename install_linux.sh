#!/usr/bin/env bash
set -euo pipefail

# Get the absolute path of the directory where THIS script lives
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APPIMAGE_PATH="$REPO_DIR/nvim-linux-x86_64.appimage"

# 1. Ensure the AppImage is executable
chmod +x "$APPIMAGE_PATH"

# 2. Identify the active shell config
if [[ "$SHELL" == *"zsh"* ]]; then
    CONF_FILE="$HOME/.zshrc"
else
    CONF_FILE="$HOME/.bashrc"
fi

# 3. Add the alias using the absolute path
# We use a check to avoid adding the same line multiple times
ALIAS_LINE="alias nvim='$APPIMAGE_PATH'"

if ! grep -q "$APPIMAGE_PATH" "$CONF_FILE"; then
    echo "$ALIAS_LINE" >> "$CONF_FILE"
    echo "Success: Alias added to $CONF_FILE"
else
    echo "Note: Alias already exists in $CONF_FILE"
fi

echo "Please run: source $CONF_FILE"
