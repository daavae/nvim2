#!/usr/bin/env bash
set -euo pipefail

# Get the absolute path of the directory where THIS script lives
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 1. Clear quarantine attributes and extract inside the repo folder
xattr -c "$REPO_DIR/nvim-macos-x86_64.tar.gz"
tar -xzvf "$REPO_DIR/nvim-macos-x86_64.tar.gz" -C "$REPO_DIR"

# 2. Identify the active shell config
if [[ "$SHELL" == *"zsh"* ]]; then
	CONF_FILE="$HOME/.zshrc"
else
	CONF_FILE="$HOME/.bashrc"
fi

# 3. Add the alias using the absolute path we found earlier
# We use a check to avoid adding the same line multiple times
ALIAS_LINE="alias nvim='$REPO_DIR/nvim-macos-x86_64/bin/nvim'"

if ! grep -q "$REPO_DIR/nvim-macos-x86_64/bin/nvim" "$CONF_FILE"; then
	echo "$ALIAS_LINE" >>"$CONF_FILE"
	echo "Success: Alias added to $CONF_FILE"
else
	echo "Note: Alias already exists in $CONF_FILE"
fi

echo "Please run: source $CONF_FILE"
