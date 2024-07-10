#!/bin/bash
# Allow Docker container to access the X server
xhost +local:root

# Create a new container
docker run -td --privileged --net=host --ipc=host \
    --name="mes-orb-slam" \
    -e "DISPLAY=$DISPLAY" \
    -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
    mes-orb-slam:0.1