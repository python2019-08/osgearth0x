# This script is created based on "docs/66how2build-ndk-code-in-docker.md"

FROM ubuntu:22.04

# 安装基本工具和依赖
RUN apt-get update && \
    apt-get install -y \
    build-essential \
    autoconf \
    automake \
    libtool \
    pkg-config \
    gettext \
    gettext-base \
    autopoint \
    gtk-doc-tools \
    cmake \
    ninja-build \
    git \
    wget \
    unzip \
    python3 \
    openjdk-11-jdk \
    libgl1-mesa-dev \
    libglu1-mesa-dev \
    libxext-dev  \
    && rm -rf /var/lib/apt/lists/* \
    && git config --global --add safe.directory /workspace/3rd/libpsl  
    

# 设置工作目录
WORKDIR /workspace

 
# 下载 Android NDK
# ARG NDK_VERSION=27.1.12297006
# ARG ARCH=x86_64
RUN wget https://dl.google.com/android/repository/android-ndk-r27d-linux.zip?hl=zh-cn -O android-ndk-r27d-linux.zip && \
    unzip android-ndk-r27d-linux.zip && \
    rm android-ndk-r27d-linux.zip && \
    mv android-ndk-r27d /opt/android-ndk

RUN wget https://github.com/Kitware/CMake/releases/download/v3.31.8/cmake-3.31.8-linux-x86_64.sh \
   && chmod +x cmake-3.28.3-linux-x86_64.sh  \
   && ./cmake-3.28.3-linux-x86_64.sh --skip-license --prefix=/usr/local    

# 设置环境变量
ENV ANDROID_NDK_HOME=/opt/android-ndk
ENV PATH="${ANDROID_NDK_HOME}:${PATH}"

# 设置默认 shell
CMD ["/bin/bash"]