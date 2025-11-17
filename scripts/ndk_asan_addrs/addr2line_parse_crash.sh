#!/bin/bash
# parse_asan.sh
ANDROID_NDK_HOME=/home/abner/Android/Sdk/ndk/27.1.12297006
ADDR2LINE="${ANDROID_NDK_HOME}/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-addr2line"
if [ ! -f "$ADDR2LINE" ]; then
    echo "错误: 找不到 addr2line 工具: $ADDR2LINE"
    exit 1
fi

# 尝试自动查找 .so 文件
# SO_FILE=$(find . -name "libandroioearth01.so" -type f | head -1)
AndroidAppPath=/home/abner/abner2/zdev/nv/osgearth0x/platform/AndroiOearth01/
SO_FILE=${AndroidAppPath}/app/build/intermediates/cxx/Debug/446nj3h3/obj/arm64-v8a/libandroioearth01.so
if [ -z "$SO_FILE" ]; then
    echo "错误: 找不到 libandroioearth01.so 文件"
    echo "请在包含 .so 文件的目录中运行此脚本"
    exit 1
fi

# *** scripts/addr_from_ndk_asan_log.py 从错误日志中提取所有地址
ADDRESSES=(
"0x47f9c70"
"0x47f4de8"
"0x47e2f90"
"0x47d53c0"
"0x5af71c0"
"0x5af6424"
"0x5af8be8"
"0x419c088"
"0x5a648b0"
"0x5f1ec84"
"0x421cb24"
"0x5e61ad8"
"0x419c088"
"0x5a648b0"
"0x5f1ec84"
"0x421cb24"
"0x598b228"
"0x59905f4"
"0x419c088"
"0x65276fc"
"0x6529c00"
"0x5f1ee40"
"0x5995aa8"
"0x5e61ad8"
"0x4e892c4"
"0x419c088"
"0x65276fc"
"0x6529c00"
"0x421cb24"
"0x5e61ad8"
"0x419c088"
"0x65276fc"
"0x6529c00"
"0x421cb24"
"0x4ce79bc"
"0x419c088"
"0x5ce8668"
"0x4d844c0"
"0x5ce9324"
"0x5ce8514"
"0x421a264"
"0x5ce9324"
"0x65276ec"
"0x6529c00"
"0x421cb24"
"0x5e61ad8"
"0x5ba4f88"
"0x5bd6e38"
"0x419c088"
"0x65276fc"
"0x6529c00"
"0x421cb24"
"0x5e61ad8"
"0x419c088"
"0x65276fc"
"0x6529c00"
"0x421cb24"
"0x5e61ad8"
"0x419c088"
"0x6a2f9a8"
"0x6a2dd50"
"0x6a18f24"
"0x6a19fcc"
"0x5e2f178"
"0x6b1a524"
"0x6b176cc"
"0x4152780"
"0x41762f4"
"0x417b944"
)

echo "=== AddressSanitizer 调用栈解析 ==="
echo "库文件: $SO_FILE"
echo "===================================="

for addr in "${ADDRESSES[@]}"; do
    echo -e "\n地址: $addr"
    $ADDR2LINE -e "$SO_FILE" -f -C -p "$addr"
done