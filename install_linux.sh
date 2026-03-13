#!/usr/bin/env bash
set -euo pipefail

# Get the absolute path of the directory where THIS script lives
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APPIMAGE_PATH="$REPO_DIR/nvim-linux-x86_64.appimage"
EXTRACT_DIR="$REPO_DIR/nvim-linux-x86_64-extracted"

# 1. Ensure the AppImage is executable
chmod +x "$APPIMAGE_PATH"

# 2. Extract the AppImage if it hasn't been extracted yet
if [ ! -d "$EXTRACT_DIR" ]; then
    echo "Extracting AppImage to avoid FUSE dependencies..."
    cd "$REPO_DIR"
    # Extract creating squashfs-root
    "$APPIMAGE_PATH" --appimage-extract > /dev/null
    # Rename to our permanent directory
    mv squashfs-root "$EXTRACT_DIR"
    echo "AppImage extracted successfully."
fi

NVIM_BINARY="$EXTRACT_DIR/AppRun"

# 3. Identify the active shell config
if [[ "$SHELL" == *"zsh"* ]]; then
    CONF_FILE="$HOME/.zshrc"
else
    CONF_FILE="$HOME/.bashrc"
fi

# 4. Add the alias using the absolute path
# We use a check to avoid adding the same line multiple times
ALIAS_LINE="alias nvim='$NVIM_BINARY'"

if ! grep -q "$NVIM_BINARY" "$CONF_FILE"; then
    echo "$ALIAS_LINE" >> "$CONF_FILE"
    echo "Success: Alias added to $CONF_FILE"
else
    echo "Note: Alias already exists in $CONF_FILE"
fi

echo "Please run: source $CONF_FILE"
