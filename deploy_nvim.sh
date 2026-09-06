#!/usr/bin/env bash
set -euo pipefail

# Usage: ./deploy_nvim.sh user@ip [linux|macos]
if [ "$#" -lt 1 ]; then
    echo "Usage: $0 user@host [linux|macos]" >&2
    exit 2
fi

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REMOTE_TARGET=$1
REMOTE_OS=${2:-linux} # Defaults to linux if not specified
case "$REMOTE_OS" in
    linux|macos) ;;
    *)
        echo "Unsupported OS: $REMOTE_OS (expected linux or macos)" >&2
        exit 2
        ;;
esac

# 1. Ensure remote directory exists
echo "Creating remote directory..."
ssh "$REMOTE_TARGET" "mkdir -p ~/.config/nvim"

# 2. Sync the config folder (excluding .git and other large files)
echo "Syncing config to $REMOTE_TARGET..."
rsync -avz \
    --exclude '.git' \
    --exclude-from "$REPO_DIR/.gitignore" \
    "$REPO_DIR/" "$REMOTE_TARGET:~/.config/nvim/"

# tmux reads ~/.tmux.conf, not the copy stored inside ~/.config/nvim.
ssh "$REMOTE_TARGET" "cp ~/.config/nvim/.tmux.conf ~/.tmux.conf"

# 3. Run the installation script on the remote server
echo "Running install_$REMOTE_OS.sh on $REMOTE_TARGET..."
if [ "$REMOTE_OS" == "linux" ]; then
    ssh "$REMOTE_TARGET" 'cd ~/.config/nvim && ./install_linux.sh'
else
    ssh "$REMOTE_TARGET" 'cd ~/.config/nvim && ./install_macos.sh'
fi

# 4. Launch Neovim on the remote server
echo "Launching Neovim..."
if [ "$REMOTE_OS" == "linux" ]; then
    # We use the extracted AppImage path to avoid FUSE issues
    NVIM_PATH=".config/nvim/nvim-linux-x86_64-extracted/AppRun"
else
    NVIM_PATH=".config/nvim/nvim-macos-arm64/bin/nvim"
fi

# Use -t to allocate a TTY for neovim
ssh -t "$REMOTE_TARGET" "\$HOME/$NVIM_PATH"
