#!/bin/bash
# parse_callstack.sh - 使用 llvm-addr2line 解析 callstack

# 设置路径
LLVM_ADDR2LINE="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-addr2line"
# SYMBOL_FILE="/home/abner/abner2/zdev/nv/osgearth0x/platform/AndroiOearth01/app/build/outputs/apk/debug/app-debug/lib/arm64-v8a/libandroioearth01.so"
SYMBOL_FILE="/mnt/disk2/abner/zdev/nv/osgearth0x/platform/AndroiOearth01/app/build/intermediates/cxx/Debug/3s1t2b4t/obj/arm64-v8a/libandroioearth01.so"

# 检查文件是否存在
if [ ! -f "$LLVM_ADDR2LINE" ]; then
    echo "错误: 未找到 llvm-addr2line: $LLVM_ADDR2LINE"
    exit 1
fi

if [ ! -f "$SYMBOL_FILE" ]; then
    echo "错误: 未找到符号文件: $SYMBOL_FILE"
    exit 1
fi

echo "=== 使用 llvm-addr2line 解析 callstack ==="
echo "符号文件: $SYMBOL_FILE"
echo "工具: $LLVM_ADDR2LINE"
echo ""

# 定义 callstack 地址数组（从你的日志中提取）
# 格式: "地址:函数名+偏移量"
# "0x39e17f0:osgEarth::REX::TileDrawable::accept(osg::PrimitiveFunctor&) const+112"
declare -a CALLSTACK=(
"0x3824a10:osgEarth::TileLayer::isKeyInVisualRange(osgEarth::TileKey const&) const+136"
"0x39e73a4:osgEarth::REX::TileNode::passInLegalRange(osgEarth::REX::RenderingPass const&) const+100 "
"0x39e6fb0:osgEarth::REX::TileNode::initializeData()+208"
"0x39e9634:osgEarth::REX::TileNode::createChildren()+1096"
"0x39e8fd4:osgEarth::REX::TileNode::cull(osgEarth::REX::TerrainCuller*)+436"
"0x39ea034:osgEarth::REX::TileNode::traverse(osg::NodeVisitor&)+460 "
"0x3150568:osg::NodeVisitor::traverse(osg::Node&)+100"
"0x39b93d4:osgEarth::REX::TerrainCuller::apply(osg::Node&)+324"
"0x3b536a0:osg::NodeVisitor::apply(osg::Group&)+36"
"0x317e448:osg::Group::accept(osg::NodeVisitor&)+72"
)

# APK 中的偏移量
APK_OFFSET=0x2e0000

echo "APK 偏移量: $APK_OFFSET"
echo "开始解析..."
echo "=========================================="

# 遍历每个 callstack 条目
for entry in "${CALLSTACK[@]}"; do
    # 分离地址和函数信息
    address=$(echo "$entry" | cut -d':' -f1)
    func_info=$(echo "$entry" | cut -d':' -f2)
    
    # 计算实际地址（减去 APK 偏移）
    real_addr=$((address - APK_OFFSET))
    hex_real_addr=$(printf "0x%x" $real_addr)
    
    echo ""
    echo "🔍 帧: $func_info"
    echo "   原始地址: $address"
    echo "   实际地址: $hex_real_addr (减去偏移 $APK_OFFSET)"
    echo "   源文件位置:"
    
    # 使用 llvm-addr2line 定位
    result=$($LLVM_ADDR2LINE -e "$SYMBOL_FILE" -f -C -p $hex_real_addr 2>&1)
    
    if [ $? -eq 0 ]; then
        # 格式化输出
        IFS=$'\n' read -d '' -r -a lines <<< "$result" || true
        for line in "${lines[@]}"; do
            echo "     $line"
        done
    else
        echo "     解析失败: $result"
    fi
    echo "   ------------------------------------"
done

echo ""
echo "=== 解析完成 ==="