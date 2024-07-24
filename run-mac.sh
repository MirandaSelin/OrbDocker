#!/bin/bash

# Start XQuartz if not already running
if ! pgrep -x "XQuartz" > /dev/null; then
    open -a XQuartz
    sleep 5 # Wait for XQuartz to start
fi

# Allow connections from localhost
xhost + 127.0.0.1

# Set the DISPLAY variable to the typical value for XQuartz
export DISPLAY=:0

# Set up XAUTH file path
XSOCK=/tmp/.X11-unix
XAUTH=/tmp/.docker.xauth

# Create and update XAUTH file
touch $XAUTH
xauth nlist $DISPLAY | sed -e 's/^..../ffff/' | xauth -f $XAUTH nmerge -

# Remove conflicting XAUTH entries (if any)
xauth remove $DISPLAY

# Create a new container with the updated DISPLAY variable and XAUTH file
docker run -td --privileged \
    --name="mes-orb-slam" \
    -e DISPLAY=${DISPLAY} \
    -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
    -v $XAUTH:$XAUTH \
    -e XAUTHORITY=$XAUTH \
    mes-orb-slam:0.1

# Verify the DISPLAY variable is set correctly in the container
docker exec mes-orb-slam echo $DISPLAY

## might need to run this to allow access for xquartz
## sudo chmod 1777 /tmp/.X11-unix
