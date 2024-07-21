#!/bin/bash

# UI permissions
XSOCK=/tmp/.X11-unix
XAUTH=/tmp/.docker.xauth

# Create the XAUTH file
touch $XAUTH

# Generate the XAUTH file content for macOS
xauth nlist $DISPLAY | sed -e 's/^..../ffff/' | xauth -f $XAUTH nmerge -

# Allow local connections to the X server
xhost +localhost

# Stop and remove old container and image if they exist
docker stop -t 0 mes-orb-slam
docker rm -f mes-orb-slam &>/dev/null
docker image rm -f mes-orb-slam:0.1

# Build the new image
docker build -t mes-orb-slam:0.1 .

# Note: On macOS, you might need to ensure that your XQuartz is running and configured to allow connections from network clients
# To do this, open XQuartz preferences, go to the Security tab, and check "Allow connections from network clients"
