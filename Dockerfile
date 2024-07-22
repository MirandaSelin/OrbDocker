# Build PCL 1.7.2 in Ubuntu 14.04
FROM ubuntu:14.04 AS builder

# Set environment variables to avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    libusb-1.0-0-dev \
    libeigen3-dev \
    libflann-dev \
    libboost-all-dev \
    libvtk5.8 \
    libvtk5-dev \
    libqhull-dev \
    libgtest-dev \
    freeglut3-dev \
    pkg-config \
    libxmu-dev \
    libxi-dev \
    libopenni-dev \
    libpcap-dev \
    libglew-dev \
    libpng-dev \
    libjpeg-dev \
    libtiff-dev \
    git \
    wget

# Download and extract PCL source code
RUN wget https://github.com/PointCloudLibrary/pcl/archive/pcl-1.7.2.tar.gz \
    && tar -xvf pcl-1.7.2.tar.gz

# Modify the source code to fix the pointer comparison issue
RUN cd pcl-pcl-1.7.2 \
    && sed -i 's/children_[i] == false/children_[i] == nullptr/g' outofcore/include/pcl/outofcore/impl/octree_base_node.hpp

# Build and install PCL
RUN cd pcl-pcl-1.7.2 \
    && mkdir build \
    && cd build \
    && cmake .. \
    && make -j$(nproc) \
    && make install

# Use a new stage to create a clean final image
FROM ubuntu:focal

COPY --from=builder /usr/local /usr/local

# Set environment variables to avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Update and install basic packages
RUN apt-get update && apt-get install -y \
    git \
    curl \
    nano \
    lsb-core \
    wget \
    cmake \
    build-essential \
    libeigen3-dev \
    libgl1-mesa-dev \
    libglew-dev \
    libgtk-3-dev \
    libboost-all-dev \
    libssl-dev \
    libcanberra-gtk3-module \
    unzip \
    iputils-ping \
    x11-apps \
    && rm -rf /var/lib/apt/lists/*

# Install Pangolin 0.6
RUN cd /tmp && git clone https://github.com/stevenlovegrove/Pangolin && \
    cd Pangolin && git checkout v0.6 && mkdir build && cd build && \
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_FLAGS=-std=c++11 .. && \
    make -j$(nproc) && make install && \
    cd / && rm -rf /tmp/Pangolin

# Add debugging steps
RUN echo "Testing network connectivity..." && \
    ping -c 4 github.com

# Install OpenCV 3.2.0
RUN apt-get install -y libgtk-3-dev
RUN cd /tmp && git clone https://github.com/opencv/opencv.git && \
    cd opencv && \
    git checkout 3.2.0 && \
    mkdir build && cd build && \
    cmake -D CMAKE_BUILD_TYPE=Release -D BUILD_EXAMPLES=OFF -D BUILD_DOCS=OFF -D BUILD_PERF_TESTS=OFF -D BUILD_TESTS=OFF -D CMAKE_INSTALL_PREFIX=/usr/local .. &&\
    make -j$(nproc) && make install && \
    cd / && rm -rf /tmp/opencv

# Install sublime-text
RUN wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | gpg --dearmor | tee /etc/apt/trusted.gpg.d/sublimehq-archive.gpg > /dev/null
RUN echo "deb https://download.sublimetext.com/ apt/stable/" | tee /etc/apt/sources.list.d/sublime-text.list
RUN apt update && apt install -y sublime-text

# Add EuRoC dataset
RUN cd ~ && wget http://robotics.ethz.ch/~asl-datasets/ijrr_euroc_mav_dataset/machine_hall/MH_01_easy/MH_01_easy.zip
RUN apt-get update && apt-get install -y unzip
RUN cd ~ && unzip MH_01_easy.zip && rm *.zip

# Clean up
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install VTK using the package manager
RUN apt-get update && apt-get install -y \
    libvtk7-dev \
    libvtk7.1p \
    python3-vtk7

# Copy the patch file into the Docker image
COPY orb_slam3_patch.diff /root/Dev/Patch/
COPY patch.diff /root/Dev/Patch/

# Copy the shell scripts into the image
COPY mono_euroc.sh /root/Dev/Scripts/mono_euroc.sh
COPY mono_inertial_euroc.sh /root/Dev/Scripts/mono_inertial_euroc.sh
COPY mono_webcam.sh /root/Dev/Scripts/mono_webcam.sh

# Make the scripts executable
RUN chmod +x /root/Dev/Scripts/mono_euroc.sh
RUN chmod +x /root/Dev/Scripts/mono_inertial_euroc.sh
RUN chmod +x /root/Dev/Scripts/mono_webcam.sh

# Update and install basic packages
RUN apt-get update && apt-get install -y \
    libpcap-dev \
    libpng-dev \
    libusb-1.0-0-dev \
    libflann-dev \
    openssl \
    && rm -rf /var/lib/apt/lists/*

# Clone ORB_SLAM3 from the new repository
RUN git clone https://github.com/fishmarch/ORB-SLAM3-Dense.git /root/Dev/ORB-SLAM3-Dense --depth 1

# Apply the patch
WORKDIR /root/Dev/ORB-SLAM3-Dense
# RUN patch -p1 < ../Patch/orb_slam3_patch.diff
RUN patch -p1 < ../Patch/patch.diff

# Set VTK_DIR environment variable
ENV VTK_DIR=/usr/lib/cmake/vtk-7.1

# Set C++ compiler and standard
RUN echo 'set(CMAKE_CXX_COMPILER "/usr/bin/c++")' >> CMakeLists.txt && \
    echo 'set(CMAKE_CXX_COMPILER_ARG1 "")' >> CMakeLists.txt && \
    echo 'set(CMAKE_CXX_COMPILER_ID "GNU")' >> CMakeLists.txt && \
    echo 'set(CMAKE_CXX_COMPILER_VERSION "7.5.0")' >> CMakeLists.txt && \
    echo 'set(CMAKE_CXX_COMPILER_VERSION_INTERNAL "")' >> CMakeLists.txt && \
    echo 'set(CMAKE_CXX_COMPILER_WRAPPER "")' >> CMakeLists.txt && \
    echo 'set(CMAKE_CXX_STANDARD_COMPUTED_DEFAULT "14")' >> CMakeLists.txt

# Build ORB_SLAM3
RUN sed -i 's/c++11/c++11/g' CMakeLists.txt
RUN chmod +x build.sh && ./build.sh

WORKDIR /root
COPY ./src ./src

# Build example
RUN cd ~/src/build && cmake .. && make

# Set default command to start an interactive shell
CMD ["/bin/bash"]