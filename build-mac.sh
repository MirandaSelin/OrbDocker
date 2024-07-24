#!/bin/bash

# UI permissions
XSOCK=/tmp/.X11-unix
XAUTH=/tmp/.docker.xauth

# Ensure DISPLAY is set
if [ -z "$DISPLAY" ]; then
    echo "DISPLAY variable is not set. Exiting."
    exit 1
fi

# Create the XAUTH file
touch $XAUTH

# Generate the XAUTH file content for macOS
xauth_list=$(xauth nlist $DISPLAY 2>/dev/null)
if [ -z "$xauth_list" ]; then
    echo "xauth: unable to list any entries for display $DISPLAY"
    exit 1
fi
echo "$xauth_list" | sed -e 's/^..../ffff/' | xauth -f $XAUTH nmerge -

# Allow local connections to the X server
xhost +localhost

# Generate the XAUTH file content for macOS again
echo "$xauth_list" | sed -e 's/^..../ffff/' | xauth -f $XAUTH nmerge -

# Stop and remove old container and image if they exist
docker stop -t 0 mes-orb-slam
docker rm -f mes-orb-slam &>/dev/null
docker image rm -f mes-orb-slam:0.1

# Build the new image
docker build -t mes-orb-slam:0.1 .

# Note: On macOS, you might need to ensure that your XQuartz is running and configured to allow connections from network clients
# To do this, open XQuartz preferences, go to the Security tab, and check "Allow connections from network clients"
