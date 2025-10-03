#!/bin/bash

# 输出脚本名称
echo "mk4ubuntu.sh: param 0=$0"

# 获取脚本的物理绝对路径（解析软链接）
SCRIPT_PHYSICAL_PATH=$(readlink -f "$0")
echo "Physical path: $SCRIPT_PHYSICAL_PATH"

# 获取脚本的软链接路径（保留软链接结构）
if [[ "$0" == /* ]]; then
    # 如果$0是绝对路径（可能含软链接），直接使用
    SCRIPT_LINK_PATH="$0"
else
    # 如果$0是相对路径，转换为绝对路径（不解析软链接）
    SCRIPT_LINK_PATH="$PWD/$0"
fi
echo "Link path: $SCRIPT_LINK_PATH"

# 使用软链接路径作为 Repo_ROOT
Repo_ROOT=$(dirname "$SCRIPT_LINK_PATH")
echo "Repo_ROOT: $Repo_ROOT"

# 验证路径是否存在
if [[ ! -d "$Repo_ROOT" ]]; then
    echo "Error: Repo_ROOT does not exist: $Repo_ROOT"
    exit 1
fi