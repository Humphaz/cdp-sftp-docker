#!/bin/bash

# Check if jq is installed
if ! command -v jq &>/dev/null; then
    echo "jq is required but not installed. Please ensure jq is available in the container."
    exit 1
fi

# Configuration directory and files
CONFIG_DIR="/data/config/sftp"
USER_DIR="/data/sftp"
SFTP_CONFIG="$CONFIG_DIR/sftp_config.json"

# Function to create a user with appropriate permissions for existing directory structure
create_user() {
    local user=$1
    local password=$2
    local user_home="$USER_DIR/$user"
    
    # Set the top-level chroot directory ownership to root
    chown root:root "$user_home"
    chmod 755 "$user_home"
    
    # Recursively set ownership of all files and subdirectories to the user
    chown -R "$user:$user" "$user_home"/*
    
    # Create the user with no shell, set password, and home directory
    if ! id "$user" &>/dev/null; then
        useradd -d "$user_home" -s /sbin/nologin "$user"
    fi

    # Encrypt password and set it for the user
    echo "$user:$password" | chpasswd
}

# Check if the configuration file exists and read it to set up users
if [[ -f "$SFTP_CONFIG" ]]; then
    while IFS= read -r line; do
        # Extract user and password from JSON config
        user=$(echo "$line" | jq -r '.user')
        password=$(echo "$line" | jq -r '.password')

        # Create user with specified settings
        create_user "$user" "$password"
    done < <(jq -c '.users[]' "$SFTP_CONFIG")
else
    echo "Configuration file $SFTP_CONFIG not found!"
fi

# Start the SSH server
exec /usr/sbin/sshd -D -e

