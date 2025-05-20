#!/bin/bash

# Enable job control for background process management
set -m

# Remove leftover X11 lock files from previous runs, if they exist, to prevent startup issues
# Using -f to suppress errors if files don't exist
rm -f /tmp/.X1-lock
rm -rf /tmp/.X11-unix

# Set up VNC password securely
# Use a random 8-character alphanumeric password if VNC_PASSWORD is unset
if [ -z "${VNC_PASSWORD}" ]; then
    echo "Warning: VNC_PASSWORD environment variable is not set. Generating a random password."
    echo "You will not be able to access the VNC server without knowing this password."
    VNC_PASSWORD=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | fold -w 8 | head -n 1)
fi

# Create VNC configuration directory and set password
mkdir -p /root/.vnc
echo -n "${VNC_PASSWORD}" | /opt/TurboVNC/bin/vncpasswd -f > /root/.vnc/passwd
chmod 400 /root/.vnc/passwd
# Unset password variable for security
unset VNC_PASSWORD

# Set VNC port from environment variable or default to 5900
VNC_PORT=${VNC_PORT:-5900}

# Start TurboVNC server with specified geometry and port
# TurboVNC forks itself, so no need for backgrounding here
# Exit if vncserver fails to start
/opt/TurboVNC/bin/vncserver -rfbauth /root/.vnc/passwd -geometry 1200x800 -rfbport "${VNC_PORT}" -wm openbox :1 || {
    echo "Error: Failed to start TurboVNC server on port ${VNC_PORT}"
    exit 1
}

# Set Websockify port from environment variable or default to 6080
WEBSOCKIFY_PORT=${WEBSOCKIFY_PORT:-6080}

# Start websockify to bridge VNC to WebSocket for noVNC access
# Run in background to allow script to continue
/opt/venv/bin/websockify --web=/noVNC "${WEBSOCKIFY_PORT}" localhost:"${VNC_PORT}" &

# Set DISPLAY environment variable for X11 applications
export DISPLAY=:1

# Start uprock-mining in the foreground to keep the container running
# Exit if uprock-mining fails to start
exec /usr/bin/uprock-mining || {
    echo "Error: Failed to start uprock-mining"
    exit 1
}
