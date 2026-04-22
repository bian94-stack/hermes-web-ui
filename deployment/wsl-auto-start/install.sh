#!/bin/bash
# Hermes Web UI - WSL Auto-Start Installer
# Run this script inside WSL to configure systemd service

set -e

# Detect environment
USER_NAME=$(whoami)
HOME_DIR=$(HOME)
PROJECT_PATH="${HOME_DIR}/hermes-web-ui"
NODE_PATH=$(which node)
WSL_DISTRO="Ubuntu"  # Default, can be overridden

# Check if project exists
if [[ ! -d "$PROJECT_PATH" ]]; then
    echo "Error: Project not found at $PROJECT_PATH"
    echo "Please clone the project first or specify custom path"
    exit 1
fi

# Check if dist is built
if [[ ! -f "$PROJECT_PATH/dist/server/index.js" ]]; then
    echo "Error: dist/server/index.js not found"
    echo "Please run 'npm run build' first"
    exit 1
fi

# Check if hermes CLI is available
if ! command -v hermes &> /dev/null; then
    echo "Warning: hermes CLI not found in PATH"
    echo "Make sure hermes is installed and in ~/.local/bin"
fi

echo "=== Hermes Web UI Auto-Start Installer ==="
echo "User: $USER_NAME"
echo "Project: $PROJECT_PATH"
echo "Node: $NODE_PATH"
echo ""

# Create systemd user directory
mkdir -p ~/.config/systemd/user

# Generate service file with actual values
cat > ~/.config/systemd/user/hermes-ui.service << EOF
[Unit]
Description=Hermes Web UI Service
After=network.target

[Service]
User=$USER_NAME
WorkingDirectory=$PROJECT_PATH
Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$HOME_DIR/.local/bin
Environment=NODE_ENV=production
ExecStart=$NODE_PATH $PROJECT_PATH/dist/server/index.js
Restart=always
RestartSec=5

[Install]
WantedBy=default.target
EOF

echo "Service file created: ~/.config/systemd/user/hermes-ui.service"

# Create symlink for static files (fix ENOENT issue)
CLIENT_DIR="$PROJECT_PATH/packages/server/client"
if [[ ! -d "$CLIENT_DIR" ]]; then
    mkdir -p "$(dirname "$CLIENT_DIR")"
    ln -sf "$PROJECT_PATH/dist/client" "$CLIENT_DIR"
    echo "Created symlink: $CLIENT_DIR -> $PROJECT_PATH/dist/client"
fi

# Enable linger (allow services to run without login)
if [[ ! -f "/var/lib/systemd/linger/$USER_NAME" ]]; then
    echo "Enabling linger (requires sudo)..."
    sudo mkdir -p /var/lib/systemd/linger
    sudo touch /var/lib/systemd/linger/$USER_NAME
    echo "Linger enabled"
fi

# Reload systemd
systemctl --user daemon-reload

# Enable and start service
systemctl --user enable hermes-ui.service
systemctl --user start hermes-ui.service

# Check status
echo ""
echo "=== Service Status ==="
systemctl --user status hermes-ui.service --no-pager

echo ""
echo "=== Installation Complete ==="
echo "Service is now running in background"
echo "Access: http://localhost:8648"
echo ""
echo "Next step: Run install.ps1 in Windows PowerShell (Admin)"
echo "to configure Windows auto-start tasks"