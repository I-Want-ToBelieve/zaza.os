#!/bin/bash

# Get the SHA-256 hash of the yabai program
YABAI_PATH=$(which yabai)
if [ -z "$YABAI_PATH" ]; then
    echo "yabai not found!"
    exit 1
fi
HASH=$(shasum -a 256 "$YABAI_PATH" | awk '{print $1}')

# Check if HASH is non-empty
if [ -z "$HASH" ]; then
    echo "Failed to get hash for yabai!"
    exit 1
fi

# Construct the new sudoers entry
SUDOERS_ENTRY="i.want.to.believe ALL=(root) NOPASSWD: sha256:$HASH $YABAI_PATH --load-sa"

# Write the entry to /private/etc/sudoers.d/yabai
echo "$SUDOERS_ENTRY" | sudo tee /private/etc/sudoers.d/yabai > /dev/null

# Set the appropriate permissions for the sudoers file
sudo chmod 0440 /private/etc/sudoers.d/yabai


yabai --restart-service
echo "Updated /private/etc/sudoers.d/yabai successfully!"
