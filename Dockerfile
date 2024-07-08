FROM ubuntu:focal

# Set environment variable to suppress interactive prompts
ARG DEBIAN_FRONTEND=noninteractive

# Update and install basic packages
RUN apt-get update && \
    apt-get install -y git curl nano lsb-core wget cmake build-essential libeigen3-dev libgl1-mesa-dev libglew-dev

# Install Pangolin 0.6
RUN cd /tmp && git clone https://github.com/stevenlovegrove/Pangolin && \
    cd Pangolin && git checkout v0.6 && mkdir build && cd build && \
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_FLAGS=-std=c++11 .. && \
    make -j$(nproc) && make install && \
    cd / && rm -rf /tmp/Pangolin

# Install OpenCV 4.4.0
RUN apt-get install -y libgtk-3-dev
RUN cd /tmp && git clone https://github.com/opencv/opencv.git && \
    cd opencv && git checkout 4.4.0 && \
    mkdir build && cd build && \
    cmake -D CMAKE_BUILD_TYPE=Release -D BUILD_EXAMPLES=OFF  -D BUILD_DOCS=OFF -D BUILD_PERF_TESTS=OFF -D BUILD_TESTS=OFF -D CMAKE_INSTALL_PREFIX=/usr/local .. && \
    make -j$(nproc) && make install && \
    cd / && rm -rf /tmp/opencv

# Install sublime-text
RUN wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | gpg --dearmor | tee /etc/apt/trusted.gpg.d/sublimehq-archive.gpg > /dev/null
RUN echo "deb https://download.sublimetext.com/ apt/stable/" | tee /etc/apt/sources.list.d/sublime-text.list
RUN apt update && apt install -y sublime-text

# Install additional libraries for ORB_SLAM3
RUN apt-get install -y libboost-all-dev libssl-dev libcanberra-gtk3-module

# Install ORB_SLAM3
ADD https://api.github.com/repos/Leonana69/ORB_SLAM3/git/refs/heads/master version.json
RUN cd ~ && mkdir Dev && cd Dev && git clone https://github.com/Leonana69/ORB_SLAM3.git --depth 1 && \
    cd ORB_SLAM3 && bash build.sh

WORKDIR /root

# Copy source files
COPY ./src ./src

# Build example
RUN cd /root/src && mkdir build && cd build && cmake .. && make

# Final working directory
WORKDIR /root/src/build
