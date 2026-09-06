#!/usr/bin/env bash
set -euo pipefail

# Get the absolute path of the directory where THIS script lives
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APPIMAGE_PATH="$REPO_DIR/nvim-linux-x86_64.appimage"
EXTRACT_DIR="$REPO_DIR/nvim-linux-x86_64-extracted"
CHECKSUM_FILE="$EXTRACT_DIR/.appimage.sha256"

# 1. Ensure the AppImage is executable
chmod +x "$APPIMAGE_PATH"

# 2. Extract when missing or when the bundled AppImage has changed.
if command -v sha256sum >/dev/null 2>&1; then
    APPIMAGE_SHA="$(sha256sum "$APPIMAGE_PATH" | awk '{print $1}')"
else
    APPIMAGE_SHA="$(shasum -a 256 "$APPIMAGE_PATH" | awk '{print $1}')"
fi
INSTALLED_SHA=""
if [ -f "$CHECKSUM_FILE" ]; then
    INSTALLED_SHA="$(sed -n '1p' "$CHECKSUM_FILE")"
fi
if [ ! -x "$EXTRACT_DIR/AppRun" ] || [ "$APPIMAGE_SHA" != "$INSTALLED_SHA" ]; then
    echo "Extracting AppImage to avoid FUSE dependencies..."
    TEMP_DIR="$(mktemp -d "$REPO_DIR/.nvim-extract.XXXXXX")"
    trap 'rm -rf "$TEMP_DIR"' EXIT
    (cd "$TEMP_DIR" && "$APPIMAGE_PATH" --appimage-extract > /dev/null)
    printf '%s\n' "$APPIMAGE_SHA" > "$TEMP_DIR/squashfs-root/.appimage.sha256"
    BACKUP_DIR="$EXTRACT_DIR.previous"
    rm -rf "$BACKUP_DIR"
    if [ -d "$EXTRACT_DIR" ]; then
        mv "$EXTRACT_DIR" "$BACKUP_DIR"
    fi
    if ! mv "$TEMP_DIR/squashfs-root" "$EXTRACT_DIR"; then
        if [ -d "$BACKUP_DIR" ]; then
            mv "$BACKUP_DIR" "$EXTRACT_DIR"
        fi
        exit 1
    fi
    rm -rf "$BACKUP_DIR"
    trap - EXIT
    rm -rf "$TEMP_DIR"
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

touch "$CONF_FILE"
if ! grep -Fq "$NVIM_BINARY" "$CONF_FILE"; then
    echo "$ALIAS_LINE" >> "$CONF_FILE"
    echo "Success: Alias added to $CONF_FILE"
else
    echo "Note: Alias already exists in $CONF_FILE"
fi

echo "Please run: source $CONF_FILE"
