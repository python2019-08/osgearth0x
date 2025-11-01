#!/bin/bash
# diagnose_symbols.sh - 诊断符号文件

SYMBOL_FILE="/home/abner/abner2/zdev/nv/osgearth0x/platform/AndroiOearth01/app/build/outputs/apk/debug/app-debug/lib/arm64-v8a/libandroioearth01.so"
# SYMBOL_FILE="/mnt/disk2/abner/zdev/nv/osgearth0x/platform/AndroiOearth01/app/build/intermediates/cxx/Debug/3s1t2b4t/obj/arm64-v8a/libandroioearth01.so"

echo "=== 符号文件诊断 ==="

# 检查文件类型和大小
echo "1. 文件信息:"
file "$SYMBOL_FILE"
ls -lh "$SYMBOL_FILE"
echo ""

# 检查是否包含调试信息
echo "2. 检查调试段:"
readelf -S "$SYMBOL_FILE" | grep -E "debug|\.debug" | head -10
echo ""

# 检查符号表
echo "3. 检查相关符号:"
nm -C "$SYMBOL_FILE" 2>/dev/null | grep -E "(TileDrawable|LineSegmentIntersector|IntersectionVisitor)" | head -10

if [ $? -ne 0 ]; then
    echo "使用 objdump 检查符号:"
    objdump -t -C "$SYMBOL_FILE" 2>/dev/null | grep -E "(TileDrawable|LineSegmentIntersector)" | head -10
fi
echo ""

# 测试特定符号
echo "4. 测试符号解析:"
$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-addr2line -e "$SYMBOL_FILE" -f -C -p 0x1000 2>&1 | head -5
