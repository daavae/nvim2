#!/usr/bin/env bash
set -euo pipefail

# Usage: ./deploy_nvim.sh user@ip [linux|macos]
REMOTE_TARGET=$1
REMOTE_OS=${2:-linux} # Defaults to linux if not specified

# 1. Ensure remote directory exists
echo "Creating remote directory..."
ssh "$REMOTE_TARGET" "mkdir -p ~/.config/nvim"

# 2. Sync the config folder (excluding .git and other large files)
echo "Syncing config to $REMOTE_TARGET..."
# We use '.' to refer to the current directory contents
rsync -avz --exclude '.git' --exclude 'nvim-pack-lock.json' ./ "$REMOTE_TARGET:~/.config/nvim/"

# 3. Run the installation script on the remote server
echo "Running install_$REMOTE_OS.sh on $REMOTE_TARGET..."
ssh "$REMOTE_TARGET" "cd ~/.config/nvim && ./install_$REMOTE_OS.sh"

# 4. Launch Neovim on the remote server
echo "Launching Neovim..."
if [ "$REMOTE_OS" == "linux" ]; then
    # We use the extracted AppImage path to avoid FUSE issues
    NVIM_PATH="~/.config/nvim/nvim-linux-x86_64-extracted/AppRun"
else
    NVIM_PATH="~/.config/nvim/nvim-macos-arm64/bin/nvim"
fi

# Use -t to allocate a TTY for neovim
ssh -t "$REMOTE_TARGET" "$NVIM_PATH"
