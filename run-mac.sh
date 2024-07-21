#!/bin/bash
# Start XQuartz if not already running
if ! pgrep -x "XQuartz" > /dev/null
then
    open -a XQuartz
    sleep 2 # Wait for XQuartz to start
fi

# Allow connections from localhost
xhost + 127.0.0.1

# Get the IP address of the host
HOST_IP=$(ifconfig en0 | grep inet | awk '$1=="inet" {print $2}')

# Create a new container with the updated DISPLAY variable
docker run -td --privileged \
    --name="mes-orb-slam" \
    -e DISPLAY=${HOST_IP}:0 \
    -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
    mes-orb-slam:0.1
