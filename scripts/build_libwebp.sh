#!/bin/bash
# Abner: this is only for reference.
# libwebp 编译安装脚本
# 使用方法: ./build_libwebp.sh [版本号，默认为1.3.2]

set -e

# 参数设置
LIBWEBP_VERSION=${1:-"1.3.2"}
INSTALL_DIR="/usr/local"
WORK_DIR=$(pwd)
THREADS=$(nproc)

# 安装依赖
echo "[1/6] 安装编译依赖..."
if [[ -f /etc/redhat-release ]]; then
    # CentOS/RHEL
    sudo yum install -y git automake autoconf libtool make gcc
elif [[ -f /etc/debian_version ]]; then
    # Debian/Ubuntu
    sudo apt-get update
    sudo apt-get install -y git automake autoconf libtool make gcc
else
    echo "无法识别的系统，请手动安装依赖: git automake autoconf libtool make gcc"
    exit 1
fi

# 下载源码
echo "[2/6] 下载 libwebp 源码..."
if [ ! -d "libwebp-${LIBWEBP_VERSION}" ]; then
    wget -O "libwebp-${LIBWEBP_VERSION}.tar.gz" "https://storage.googleapis.com/downloads.webmproject.org/releases/webp/libwebp-${LIBWEBP_VERSION}.tar.gz"
    tar -xzf "libwebp-${LIBWEBP_VERSION}.tar.gz"
fi

cd "libwebp-${LIBWEBP_VERSION}"

# 配置
echo "[3/6] 配置编译选项..."
./configure \
    --prefix=${INSTALL_DIR} \
    --enable-libwebpmux \
    --enable-libwebpdemux \
    --enable-libwebpdecoder \
    --enable-libwebpextras \
    --enable-swap-16bit-csp \
    --enable-experimental

# 编译
echo "[4/6] 编译 libwebp (使用 ${THREADS} 线程)..."
make -j${THREADS}

# 安装
echo "[5/6] 安装到系统..."
sudo make install

# 更新动态链接库缓存
sudo ldconfig

# 验证
echo "[6/6] 验证安装..."
if [ -f "${INSTALL_DIR}/bin/cwebp" ]; then
    echo "libwebp ${LIBWEBP_VERSION} 安装成功!"
    echo "已安装到: ${INSTALL_DIR}"
    echo "工具路径:"
    echo "  cwebp: ${INSTALL_DIR}/bin/cwebp"
    echo "  dwebp: ${INSTALL_DIR}/bin/dwebp"
    echo "  webpmux: ${INSTALL_DIR}/bin/webpmux"
    echo "  webpinfo: ${INSTALL_DIR}/bin/webpinfo"
else
    echo "安装可能失败，请检查输出日志"
    exit 1
fi

cd ${WORK_DIR}

