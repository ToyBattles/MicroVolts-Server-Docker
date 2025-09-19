#!/bin/bash

# Script to edit Microvolts Emulator configuration
# Usage: ./edit_config.sh [editor]
# If no editor specified, defaults to nano

CONFIG_FILE="./Setup/config.ini"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Configuration file $CONFIG_FILE not found!"
    exit 1
fi

# Choose editor
if [ $# -eq 0 ]; then
    EDITOR="nano"
else
    EDITOR="$1"
fi

echo "Opening $CONFIG_FILE with $EDITOR..."
echo "After editing, the servers will be restarted automatically."

# Edit the file
$EDITOR "$CONFIG_FILE"

# Check if file was modified
if [ "$CONFIG_FILE" -nt "$CONFIG_FILE" ]; then
    echo "Configuration updated. Restarting servers..."
    docker-compose down
    docker-compose up -d
    echo "Servers restarted successfully!"
else
    echo "No changes detected."
fi