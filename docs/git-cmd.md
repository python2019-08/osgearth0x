# 1.如何确保 git 下载的文件 使用 LF

要确保 Git 下载（克隆/拉取）的文件默认使用 **LF（Linux 换行符）**，核心是通过 Git 的 **换行符自动转换配置**（`core.autocrlf` 和 `core.eol`）实现，同时结合项目级配置（`.gitattributes`）确保团队协作时格式统一。以下是分场景的完整配置方案：


### 一、核心原理：Git 换行符转换机制
Git 提供两个关键配置项控制换行符：
- **`core.autocrlf`**：控制「检出（checkout）」和「提交（commit）」时的换行符转换（针对 Windows 环境为主）；
- **`core.eol`**：控制「检出」文件时默认使用的换行符（针对 Linux/macOS 环境为主，或需要强制 LF 的场景）。

通过合理配置这两个项，可确保无论本地系统是什么，检出的文件都统一为 LF。


### 二、分环境配置：确保检出文件为 LF
根据你使用的操作系统（Linux/WSL、Windows），选择对应的配置方案：

#### 场景1：Linux 或 WSL 环境（推荐）
Linux/WSL 原生使用 LF，只需确保 Git 不自动将 LF 转为 CRLF 即可，配置如下：
1. 打开终端，执行全局配置（对所有 Git 仓库生效）：
   ```bash
   # 1. 禁用自动转换（提交和检出时不修改换行符）
   git config --global core.autocrlf false

   # 2. 强制检出文件时使用 LF 换行符
   git config --global core.eol lf
   ```
2. 验证配置是否生效：
   ```bash
   git config --global --get core.autocrlf  # 应输出 false
   git config --global --get core.eol        # 应输出 lf
   ```

#### 场景2：Windows 环境（需强制 LF）
Windows 原生使用 CRLF，需通过配置让 Git 检出时强制转为 LF：
1. 打开 Git Bash 或 PowerShell，执行全局配置：
   ```bash
   # 1. 提交时将 CRLF 转为 LF，检出时强制转为 LF（关键：覆盖 Windows 默认）
   git config --global core.autocrlf input

   # 2. 明确指定检出文件使用 LF
   git config --global core.eol lf
   ```
   - `core.autocrlf=input`：仅在「提交」时将 CRLF 转为 LF（确保仓库中存储的是 LF），「检出」时不转换（结合 `core.eol=lf`，强制检出为 LF）。
2. 验证配置：
   ```bash
   git config --global --get core.autocrlf  # 应输出 input
   git config --global --get core.eol        # 应输出 lf
   ```


### 三、项目级配置：.gitattributes（强制统一，推荐）
全局配置可能因团队成员的本地设置不同而失效，**项目级配置（`.gitattributes`）** 可强制所有克隆该项目的人使用统一的换行符规则（优先级高于全局配置），适合团队协作或开源项目。

#### 步骤：在项目中添加 .gitattributes 文件
1. 进入你的 Git 项目根目录（如 `osgearth0x`）：
   ```bash
   cd /path/to/your/project  # 替换为你的项目路径
   ```
2. 创建或编辑 `.gitattributes` 文件：
   ```bash
   vim .gitattributes
   ```
3. 添加以下内容（核心是对所有文件强制 LF，对二进制文件不处理）：
   ```ini
   # 对所有文件生效：检出时用 LF，提交时用 LF
   * text eol=lf

   # 对二进制文件（如图片、压缩包）不处理换行符（避免损坏文件）
   *.png binary
   *.jpg binary
   *.zip binary
   *.tar.gz binary
   *.dll binary
   *.exe binary

   # 对脚本文件额外强制 LF（可选，增强针对性）
   *.sh text eol=lf
   *.bash text eol=lf
   *.py text eol=lf
   ```
   - **规则说明**：
     - `text eol=lf`：标记文件为文本类型，检出时强制使用 LF；
     - `binary`：标记文件为二进制类型，Git 不处理换行符（避免压缩包、图片等文件损坏）。
4. 将 `.gitattributes` 提交到仓库（确保团队成员同步）：
   ```bash
   git add .gitattributes
   git commit -m "add .gitattributes: force LF line endings"
   git push  # 推送到远程仓库
   ```


### 四、验证：确保文件确实使用 LF
配置完成后，可通过以下方法验证检出的文件是否为 LF：

#### 方法1：用 `file` 命令（Linux/WSL）
```bash
# 查看任意文本文件的换行符格式（如脚本文件）
file ./download_submodules.sh
```
- 若输出包含 `line terminators: LF`，说明是 LF 格式；
- 若输出 `line terminators: CRLF`，则需重新检查配置。

#### 方法2：用 VS Code（跨平台）
1. 用 VS Code 打开任意文本文件；
2. 查看右下角状态栏：
   - 显示「LF」：格式正确；
   - 显示「CRLF」：格式错误，需重新配置并重新检出文件。

#### 方法3：重新检出文件（若配置后仍为 CRLF）
若已配置但文件仍为 CRLF，可通过以下命令强制重新检出（清除本地缓存并重新拉取）：
```bash
# 1. 清除本地文件缓存（不删除工作区文件）
git rm --cached -r .

# 2. 重新添加所有文件（触发换行符转换）
git add .

# 3. （可选）提交转换后的文件（若有修改）
git commit -m "fix line endings to LF"

# 4. 重新拉取最新代码（确保远程是 LF）
git pull
```


### 五、常见问题解决
1. **配置后新克隆的文件仍为 CRLF**：
   - 检查 `core.eol` 是否为 `lf`（`git config --get core.eol`）；
   - 确保项目根目录有 `.gitattributes` 文件，且规则正确。

2. **二进制文件被误处理为文本（如 zip 损坏）**：
   - 在 `.gitattributes` 中为对应的二进制文件添加 `binary` 规则（如 `*.zip binary`），避免 Git 处理其换行符。

3. **Windows 下 IDE 自动转为 CRLF**：
   - 在 IDE 中关闭「自动转换换行符」：如 VS Code 右下角切换为「LF」并勾选「保存时保持格式」；PyCharm 中设置「File → Line Separators → LF」。


通过以上配置，可确保无论你在什么环境下克隆/拉取 Git 仓库，文件都统一使用 LF 换行符，避免因换行符不一致导致的脚本执行错误（如 `bad interpreter: No such file or directory`）或编译问题。