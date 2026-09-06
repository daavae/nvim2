#!/usr/bin/env bash
set -euo pipefail

# Get the absolute path of the directory where THIS script lives
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 1. Clear quarantine attributes and refresh the bundled Neovim directory.
xattr -c "$REPO_DIR/nvim-macos-arm64.tar.gz"
TEMP_DIR="$(mktemp -d "$REPO_DIR/.nvim-macos.XXXXXX")"
trap 'rm -rf "$TEMP_DIR"' EXIT
tar -xzf "$REPO_DIR/nvim-macos-arm64.tar.gz" -C "$TEMP_DIR"
BACKUP_DIR="$REPO_DIR/nvim-macos-arm64.previous"
rm -rf "$BACKUP_DIR"
if [ -d "$REPO_DIR/nvim-macos-arm64" ]; then
    mv "$REPO_DIR/nvim-macos-arm64" "$BACKUP_DIR"
fi
if ! mv "$TEMP_DIR/nvim-macos-arm64" "$REPO_DIR/nvim-macos-arm64"; then
    if [ -d "$BACKUP_DIR" ]; then
        mv "$BACKUP_DIR" "$REPO_DIR/nvim-macos-arm64"
    fi
    exit 1
fi
rm -rf "$BACKUP_DIR"
trap - EXIT
rm -rf "$TEMP_DIR"

# 2. Identify the active shell config
if [[ "$SHELL" == *"zsh"* ]]; then
    CONF_FILE="$HOME/.zshrc"
else
        CONF_FILE="$HOME/.bashrc"
fi

# 3. Add the alias using the absolute path we found earlier
# We use a check to avoid adding the same line multiple times
ALIAS_LINE="alias nvim='$REPO_DIR/nvim-macos-arm64/bin/nvim'"

touch "$CONF_FILE"
if ! grep -Fq "$REPO_DIR/nvim-macos-arm64/bin/nvim" "$CONF_FILE"; then
	echo "$ALIAS_LINE" >>"$CONF_FILE"
	echo "Success: Alias added to $CONF_FILE"
else
	echo "Note: Alias already exists in $CONF_FILE"
fi

echo "Please run: source $CONF_FILE"
