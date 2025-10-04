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

======================================
# 2.$(pwd)    $PWD

在 Unix/Linux/macOS 等类 Unix 系统的终端中，`$(pwd)` 和 `$PWD` 都与「当前工作目录（Present Working Directory）」相关，但二者的**本质、执行逻辑和使用场景存在关键区别**，具体对比如下：


### 核心区别对比表
| 特性                | `$PWD`                          | `$(pwd)`                        |
|---------------------|---------------------------------|---------------------------------|
| 本质                | **环境变量**（系统预定义的变量） | **命令替换**（执行 `pwd` 命令并获取输出） |
| 数据来源            | 系统维护的目录状态变量          | 执行 `pwd` 命令后返回的结果      |
| 执行时机与开销      | 直接读取变量值，无额外执行开销  | 需启动子进程运行 `pwd` 命令，有轻微开销 |
| 结果是否「实时」    | 通常实时，但极端场景下可能滞后  | 每次执行都实时获取当前目录      |
| 典型使用场景        | 脚本/命令中快速引用当前目录路径 | 需强制确认「最新当前目录」时    |


### 1. `$PWD`：预定义的环境变量
`$PWD` 是系统**默认自带的环境变量**，其值由 Shell（如 Bash、Zsh）自动维护，始终指向当前用户所在的目录路径。

#### 特点：
- **无执行开销**：直接读取变量值，无需额外运行命令，效率更高。
- **基本实时性**：当你通过 `cd` 命令切换目录时，Shell 会自动更新 `$PWD` 的值，确保其与当前目录一致（99% 的日常场景下完全可靠）。
- **使用简单**：直接通过 `$` 符号引用即可，无需额外括号。

#### 示例：
```bash
# 查看 $PWD 的值（当前目录）
echo $PWD
# 输出示例：/home/yourname/Documents

# 切换目录后，$PWD 自动更新
cd ../Downloads
echo $PWD
# 输出示例：/home/yourname/Downloads
```


### 2. `$(pwd)`：命令替换（执行 `pwd` 命令）
`$(...)` 是 Shell 中的「命令替换语法」—— 它会先执行括号内的 `pwd` 命令，再将命令的**输出结果**作为字符串返回。  
简单说：`$(pwd)` = 「先运行 `pwd` 命令，再用命令的结果代替这个表达式」。

#### 特点：
- **实时性绝对可靠**：每次使用 `$(pwd)` 时，都会重新执行一次 `pwd` 命令，获取的是「当前瞬间」的目录（极端场景下比 `$PWD` 更准，见下文）。
- **有轻微执行开销**：执行 `pwd` 命令需要启动一个子进程，虽然开销极小，但高频使用（如循环内）时会比 `$PWD` 慢。
- **等价于反引号 `pwd`**：在老的 Shell 脚本中，可能会看到 `pwd`（反引号包裹），其功能与 `$(pwd)` 完全一致，但 `$(...)` 语法更清晰、支持嵌套，现在更推荐使用。

#### 示例：
```bash
# 查看 $(pwd) 的值（本质是执行 pwd 命令并输出结果）
echo $(pwd)
# 输出示例：/home/yourname/Documents

# 切换目录后，$(pwd) 重新执行，结果更新
cd ../Pictures
echo $(pwd)
# 输出示例：/home/yourname/Pictures
```


### 关键差异：极端场景下的不一致
在绝大多数日常操作（如 `cd` 切换目录、执行普通命令）中，`$PWD` 和 `$(pwd)` 的结果完全一致。但在**极少数特殊场景**下，二者可能出现差异：

当你通过「非 `cd` 方式」改变当前目录时（如通过 `chdir()` 系统调用的程序、或某些特殊工具），Shell 可能没来得及更新 `$PWD` 变量，此时：
- `$PWD` 会显示「旧的目录路径」（变量未更新）；
- `$(pwd)` 会执行 `pwd` 命令，获取「新的实际目录路径」（结果准确）。

#### 示例（模拟极端场景）：
```bash
# 1. 先查看初始状态，二者一致
echo "PWD变量: $PWD"       # 输出：PWD变量: /home/yourname
echo "pwd命令: $(pwd)"     # 输出：pwd命令: /home/yourname

# 2. 通过 Python 调用 chdir() 切换目录（不触发 Shell 的 $PWD 更新）
python3 -c "import os; os.chdir('/tmp')"

# 3. 再次查看，二者出现差异
echo "PWD变量: $PWD"       # 输出：PWD变量: /home/yourname（变量未更新，显示旧路径）
echo "pwd命令: $(pwd)"     # 输出：pwd命令: /tmp（执行命令，显示实际新路径）
```


### 总结：该用哪个？
1. **日常使用/脚本开发（99% 场景）**：优先用 `$PWD`  
   - 优势：无执行开销、语法简洁，且结果完全可靠。

2. **需强制确保目录实时性（极端场景）**：用 `$(pwd)`  
   - 例如：脚本中涉及第三方工具（可能修改目录但不通知 Shell）、或需要绝对精确的目录路径时。

3. **避免混淆**：不要写成 `$(PWD)` 或 `$pwd`  
   - `$(PWD)`：会执行名为 `PWD` 的命令（系统中不存在该命令，会报错）；
   - `$pwd`：会引用名为 `pwd` 的自定义变量（默认未定义，输出空值）。

==========================================
# 3. 例子

这里，/home/abner/abner2 是 实际路径/mnt/disk2/abner/ 的软链接。

path_softlink.sh代码如下 
```sh 
#!/bin/bash
echo "mk4ubuntu.sh: param 0=$0" # 输出脚本名称

# 获取脚本的物理绝对路径（解析软链接）
SCRIPT_PHYSICAL_PATH=$(readlink -f "$0")
echo "Physical path: $SCRIPT_PHYSICAL_PATH"

path01="$PWD/$0"
path02="$(pwd)"
echo "path01=${path01}"
echo "path02=${path02}"
exit 11
```
运行path_softlink.sh ：
```sh
~/abner2/zdev/nv/osgearth0x/scripts/test$ ./path_softlink.sh 
mk4ubuntu.sh: param 0=./path_softlink.sh
Physical path: /mnt/disk2/abner/zdev/nv/osgearth0x/scripts/test/path_softlink.sh
path01=/home/abner/abner2/zdev/nv/osgearth0x/scripts/test/./path_softlink.sh
path02=/home/abner/abner2/zdev/nv/osgearth0x/scripts/test

# --------
~$ /home/abner/abner2/zdev/nv/osgearth0x/scripts/test/path_softlink.sh
mk4ubuntu.sh: param 0=/home/abner/abner2/zdev/nv/osgearth0x/scripts/test/path_softlink.sh
Physical path: /mnt/disk2/abner/zdev/nv/osgearth0x/scripts/test/path_softlink.sh
path01=/home/abner//home/abner/abner2/zdev/nv/osgearth0x/scripts/test/path_softlink.sh
path02=/home/abner

# --------
/mnt/disk2/abner/zdev/nv/osgearth0x/scripts/test$ ./path_softlink.sh 
mk4ubuntu.sh: param 0=./path_softlink.sh
Physical path: /mnt/disk2/abner/zdev/nv/osgearth0x/scripts/test/path_softlink.sh
path01=/mnt/disk2/abner/zdev/nv/osgearth0x/scripts/test/./path_softlink.sh
path02=/mnt/disk2/abner/zdev/nv/osgearth0x/scripts/test

```
从上面的运行结果来看，**用"$PWD/$0" 不能稳定地得到 软链接版本的全路径**。