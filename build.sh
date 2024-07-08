# UI permisions
XSOCK=/tmp/.X11-unix
XAUTH=/tmp/.docker.xauth
touch $XAUTH
xauth nlist $DISPLAY | sed -e 's/^..../ffff/' | xauth -f $XAUTH nmerge -

xhost +local:docker

# remove old container and image
docker stop -t 0 mes-orb-slam
docker image rm -f mes-orb-slam:0.1
docker rm -f mes-orb-slam &>/dev/null

# build
docker build -t mes-orb-slamv:0.1 .
