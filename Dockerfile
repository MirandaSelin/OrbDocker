FROM ubuntu:focal

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

# Install dependencies for PCL 1.7.1
RUN apt-get update && apt-get install -y \
    libflann-dev \
    libqhull-dev \
    libusb-1.0-0-dev \
    libpcap-dev \
    libpng-dev \
    libproj-dev

# Add PPA for older VTK version and install VTK 6
RUN add-apt-repository ppa:rock-core/qt4 && \
    apt-get update && \
    apt-get install -y \
    libvtk6-dev \
    libvtk6-qt-dev

# Clone PCL source code
RUN git clone https://github.com/PointCloudLibrary/pcl.git /pcl
WORKDIR /pcl
RUN git checkout pcl-1.7.1

# Create build directory
RUN mkdir build
WORKDIR /pcl/build

# Configure and build PCL with VTK 6
RUN cmake .. \
    -DBUILD_SHARED_LIBS=ON \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/usr/local \
    -DPCL_ENABLE_SSE=ON \
    -DPCL_ENABLE_AVX=ON \
    -DBUILD_tools=ON \
    -DBUILD_examples=ON \
    -DVTK_DIR=/usr/lib/vtk-6.3
RUN make -j$(nproc)
RUN make install

# Clean up
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

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

# Clone ORB_SLAM3 from the new repository
RUN git clone https://github.com/fishmarch/ORB-SLAM3-Dense.git /root/Dev/ORB-SLAM3-Dense --depth 1

# Apply the patch
WORKDIR /root/Dev/ORB-SLAM3-Dense
# RUN patch -p1 < ../Patch/orb_slam3_patch.diff
RUN patch -p1 < ../Patch/patch.diff

# Build ORB_SLAM3
RUN chmod +x build.sh && ./build.sh

WORKDIR /root
COPY ./src ./src

# Build example
RUN cd ~/src/build && cmake .. && make

# Set default command to start an interactive shell
CMD ["/bin/bash"]