#!/bin/bash

# UI permissions
XSOCK=/tmp/.X11-unix
XAUTH=/tmp/.docker.xauth
touch $XAUTH
xauth nlist $DISPLAY | sed -e 's/^..../ffff/' | xauth -f $XAUTH nmerge -

xhost +local:docker

# Remove old container and image
docker stop -t 0 mes-orb-slam-dense
docker image rm -f mes-orb-slam-dense:0.1
docker rm -f mes-orb-slam-dense &>/dev/null

# Build with limited parallel jobs
docker build -t mes-orb-slam-dense:0.1 . --build-arg MAKEFLAGS="-j4"
