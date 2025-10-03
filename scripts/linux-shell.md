# 1.获取脚本的绝对路径，并处理软链接情况下的路径一致性问题

## Q
```sh
# 下面的echo 输出 "mk4ubuntu.sh: param 0=./mk4android.sh"
echo "mk4ubuntu.sh: param 0=$0"

#--获取脚本的绝对路径（处理符号链接）
SCRIPT_PATH=$(readlink -f "$0")
#--当/home/abner/abner2 是 实际路径/mnt/disk2/abner/ 的软链接时，下面的echo输出
#-- "sh-path: /mnt/disk2/abner/zdev/nv/osgearth0x/mk4android.sh"
echo "sh-path: $SCRIPT_PATH"

#--额外：获取脚本所在目录的绝对路径
# Repo_ROOT=$(dirname "$SCRIPT_PATH") 
#--当/home/abner/abner2 是 实际路径/mnt/disk2/abner/ 的软链接时，Repo_ROOT应该是 软链接目录下的路径，
#--否则，cmake 在使用CMAKE_PREFIX_PATH查找 xxxConfig.cmake 时有歧义、混淆，从而编译失败。
#--所以这里强制指定为：
Repo_ROOT=/home/abner/abner2/zdev/nv/osgearth0x
```
## A-YuanbaoAI
这段脚本的主要目的是获取脚本的绝对路径，并处理软链接情况下的路径一致性问题。以下是关键点分析和改进建议：

---

### **当前脚本分析**
```bash
# 输出脚本名称（$0）
echo "mk4ubuntu.sh: param 0=$0"  # 输出示例：mk4ubuntu.sh: param 0=./mk4android.sh

# 获取脚本的物理绝对路径（解析软链接）
SCRIPT_PATH=$(readlink -f "$0")
echo "sh-path: $SCRIPT_PATH"     # 输出示例：sh-path: /mnt/disk2/abner/zdev/nv/osgearth0x/mk4android.sh

# 强制指定为软链接路径（避免CMake路径混淆）
Repo_ROOT=/home/abner/abner2/zdev/nv/osgearth0x
```

---

### **潜在问题**
1. **硬编码路径风险**  
   `Repo_ROOT=/home/abner/abner2/...` 是硬编码路径，若用户目录名（`abner`）或软链接名（`abner2`）变化会导致脚本失效。

2. **路径逻辑矛盾**  
   脚本先通过 `readlink -f` 获取物理路径，但后续又强制使用软链接路径，可能导致行为不一致。

3. **CMake路径混淆**  
   如果项目中混合使用物理路径和软链接路径，CMake在查找 `xxxConfig.cmake` 时可能因路径歧义失败。

=======================================================
# 2. pwd -P 依然是物理路径

## Q
```bash
#!/bin/bash

# 获取脚本的物理绝对路径（解析软链接）
SCRIPT_PHYSICAL_PATH=$(readlink -f "$0")
echo "Physical path: $SCRIPT_PHYSICAL_PATH"

SCRIPT_LINK_PATH="$(cd "$(dirname "$0")" && pwd -P)/$(basename "$0")"
echo "maybe also Physical path: $SCRIPT_LINK_PATH"
```

## A-YuanbaoAI
您是对的，`pwd -P` 会解析符号链接并返回物理路径（即 "physical" 路径），而不是保留软链接结构。如果您需要获取 **包含软链接的原始路径**，需要用不同的方法处理。

---

### **问题分析**
- `pwd -P`（或 `pwd --physical`）会解析所有符号链接，返回实际路径（如 `/mnt/disk2/abner/...`）。
- 但您的需求是：**保留软链接的路径形式**（如 `/home/abner/abner2/...`），即使它是符号链接。

---

### **解决方案**
#### **方法 1：直接使用 `$0`（如果调用时已是绝对路径）**
如果脚本是通过绝对路径（含软链接）调用的，`$0` 会保留软链接结构：
```bash
SCRIPT_LINK_PATH="$0"
```

#### **方法 2：手动拼接路径（相对路径转绝对路径 + 保留软链接）**
如果 `$0` 是相对路径（如 `./mk4android.sh`），需手动转换为绝对路径，同时保留软链接：
```bash
SCRIPT_LINK_PATH="$(
    # 获取脚本所在目录（保留软链接）
    dir="$(dirname "$0")"
    # 如果是相对路径，转换为绝对路径（不解析软链接）
    if [[ "$dir" != /* ]]; then
        dir="$PWD/$dir"
    fi
    # 拼接目录和脚本名
    echo "$dir/$(basename "$0")"
)"
```

#### **方法 3：使用 `realpath --no-symlinks`（如果可用）**
某些系统（如 Ubuntu）的 `realpath` 支持 `--no-symlinks` 选项，可以生成绝对路径但不解析符号链接：
```bash
SCRIPT_LINK_PATH="$(realpath --no-symlinks "$0")"
```

---

### **改进后的完整脚本**
```bash
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
```

---

### **关键点说明**
1. **保留软链接结构**  
   - 直接使用 `$0` 或手动拼接 `$PWD/$0`，避免调用 `pwd -P` 或 `readlink -f` 解析符号链接。

2. **兼容相对路径调用**  
   - 处理 `./mk4android.sh` 或 `../path/to/script.sh` 等相对路径情况。

3. **输出示例**  
   - 若软链接 `/home/abner/abner2` 指向 `/mnt/disk2/abner`：
     ```
     mk4ubuntu.sh: param 0=./mk4android.sh
     Physical path: /mnt/disk2/abner/zdev/nv/osgearth0x/mk4android.sh
     Link path: /home/abner/abner2/zdev/nv/osgearth0x/mk4android.sh
     Repo_ROOT: /home/abner/abner2/zdev/nv/osgearth0x
     ```

---

### **为什么这样做？**
- **CMake 路径一致性**：如果项目中硬编码了软链接路径（如 `/home/abner/abner2/...`），则脚本和 CMake 必须统一使用相同路径形式，避免因路径歧义导致编译失败。
- **可移植性**：不依赖硬编码路径，适应不同的用户目录或软链接名。

---

### **验证方法**
```bash
# 创建软链接
ln -s /mnt/disk2/abner /home/abner/abner2

# 调用脚本（通过软链接路径）
cd /home/abner/abner2/zdev/nv/osgearth0x
./mk4android.sh

# 输出应显示软链接路径（/home/abner/abner2/...）
```