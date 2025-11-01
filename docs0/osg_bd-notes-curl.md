=====================================
# 1.curl的github地址
cURL 的官方 GitHub 地址是： https://github.com/curl/curl
 
### 关键信息：
- **项目主页**：https://curl.se（官方文档、下载等）  
- **GitHub 仓库**：https://github.com/curl/curl（源码、Issue、Pull Requests）  
- **License**：MIT 许可证（自由使用和修改）  

### 功能简介：
cURL 是一个广泛使用的 **命令行工具和库**（`libcurl`），支持多种网络协议（HTTP/HTTPS/FTP/SFTP 等），常用于数据传输、API 测试等场景。

## 1.1 curl的依赖库缺失的问题

从你的 CMake 配置日志来看，编译 `curl` 时遇到了多个依赖库缺失的问题（如 `libbrotli`、`libnghttp2`、`libidn2`、`libpsl` 等）。以下是完整的解决方案：

---

### **1. 安装缺失的依赖库**
在 Ubuntu/Debian 系统中，运行以下命令安装所有必需的开发包：
```bash
sudo apt update
sudo apt install -y \
    libssl-dev \
    zlib1g-dev \
    libbrotli-dev \
    libnghttp2-dev \
    libldap2-dev \
    libidn2-dev \
    libpsl-dev \
    libzstd-dev
```

**关键库说明**：
- `libnghttp2-dev`：HTTP/2 支持（必需）  
- `libbrotli-dev`：Brotli 压缩算法支持  
- `libidn2-dev`：国际化域名支持（IDN）  https://github.com/libidn/libidn2
- `libpsl-dev`：公共后缀列表（Public Suffix List）支持  
- `libldap2-dev`：LDAP 协议支持（可选）  
   
   zlib的github：  https://github.com/madler/zlib
---

### **2. 重新运行 CMake**
安装依赖后，清除之前的构建缓存并重新配置：
```bash
rm -rf build  # 删除旧构建目录
cmake -S . -B build -DCMAKE_BUILD_TYPE=Debug
```

---

### **3. 选择性禁用非必需功能（可选）**
如果某些库仍无法安装，可以通过 CMake 选项禁用对应功能：
```bash
cmake -S . -B build \
    -DCMAKE_BUILD_TYPE=Debug \
    -DCURL_DISABLE_LDAP=ON \          # 禁用 LDAP
    -DCURL_DISABLE_BROTLI=ON \        # 禁用 Brotli
    -DCURL_DISABLE_IDN=ON \           # 禁用 IDN
    -DCURL_DISABLE_PSL=ON             # 禁用 PSL


```

---

### **4. 编译和安装**
```bash
cmake --build build --parallel $(nproc)
sudo cmake --install build
```

---

### **5. 验证安装**
检查 `curl` 是否支持所需协议：
```bash
curl --version
```
输出应显示启用的功能，例如：
```
Features: HTTP2 HTTPS-proxy IDN IPv6 Largefile NTLM PSL SSL TLS-SRP UnixSockets brotli zstd
```

---

### **6. 常见问题解决**
#### **Q1: 仍然找不到 `libnghttp2`**
- **原因**：可能路径未正确识别。  
- **解决**：手动指定库路径：
  ```bash
  cmake -S . -B build \
      -DNGHTTP2_INCLUDE_DIR=/usr/include/nghttp2 \
      -DNGHTTP2_LIBRARY=/usr/lib/x86_64-linux-gnu/libnghttp2.so
  ```

#### **Q2: OpenSSL 版本冲突**
- **现象**：链接到旧版 OpenSSL（如 1.1.x）。  
- **解决**：强制使用新版：
  ```bash
  cmake -S . -B build \
      -DOPENSSL_ROOT_DIR=/usr/local/openssl \  # 替换为你的路径
      -DOPENSSL_USE_STATIC_LIBS=OFF
  ```

#### **Q3: 系统库与自定义库冲突**
- **现象**：CMake 优先找到系统库而非自定义安装的库。  
- **解决**：调整 `PKG_CONFIG_PATH`：
  ```bash
  export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH
  ```

---

### **7. 完整编译选项参考**
| **选项**                  | **作用**                          | **示例值**          |
|---------------------------|----------------------------------|--------------------|
| `-DCMAKE_BUILD_TYPE`       | 调试/发布模式                    | `Debug` 或 `Release` |
| `-DCURL_DISABLE_HTTP2`    | 禁用 HTTP/2 支持                 | `OFF`（默认启用）   |
| `-DCURL_ZLIB=ON`          | 启用 Zlib 压缩                   | `ON`（默认）        |
| `-DBUILD_SHARED_LIBS`     | 构建动态库                       | `ON`               |
| `-DENABLE_ARES=ON`        | 启用异步 DNS 解析（c-ares）      | `OFF`              |

---

### **总结**
1. **优先安装所有依赖库**（步骤1），确保基础功能可用。  
2. **选择性禁用非必需功能**（步骤3）以绕过顽固错误。  
3. **验证编译结果**（步骤5）确认所需协议已启用。  

如果问题仍未解决，请提供：
- `cmake --build build --verbose` 的完整输出。  
- `ls -l /usr/include/nghttp2` 和 `ls -l /usr/lib/x86_64-linux-gnu/libnghttp2*` 的结果。

=====================================
# 2.curl的依赖库libpsl 

`libpsl`（Public Suffix List 库）的官方 GitHub 地址是：  
👉 **https://github.com/rockdaboot/libpsl**  

---

### 关键信息：
- **功能**：用于处理 **Public Suffix List**（公共后缀列表，如域名解析中的 `.com`、`.co.uk` 等规则）。  
- **依赖项目**：被 cURL、Wget、LibreSSL 等工具使用。  
- **License**：MIT 许可证。  

---

### 安装方法（如果系统包管理器未提供）：
#### 1. 从源码编译安装：
```bash
git clone https://github.com/rockdaboot/libpsl
cd libpsl
./autogen.sh
./configure 
make
sudo make install
```

#### 2. 解决依赖问题：
- 需要先安装 `libicu-dev`（Unicode 支持）和 `libidn2-dev`（国际化域名）：
  ```bash
  sudo apt install libicu-dev libidn2-dev  # Ubuntu/Debian
  <!--  https://github.com/unicode-org/icu   -->
  ```

---

### 常见问题：
- **`pkg-config` 路径问题**：  
  如果安装后仍报错，尝试更新 `PKG_CONFIG_PATH`：
  ```bash
  export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH
  ```
 
---

### 文档参考：
- 官方文档：https://github.com/rockdaboot/libpsl#readme  
- Public Suffix List 规则：https://publicsuffix.org/  

希望帮你解决问题！

=========================================

# 3.curl的依赖库OpenSSL 

OpenSSL 的官方 GitHub 仓库地址如下：

### **OpenSSL GitHub 主仓库**
🔗 https://github.com/openssl/openssl

---

### **关键信息**
1. **代码托管**：  
   - 包含 OpenSSL 的完整源代码（C 语言实现），支持 TLS/SSL 协议、加密算法（如 AES、RSA、ECDSA）等。
   - 采用 Apache License 2.0 开源协议。

2. **分支说明**：
   - **`master`**: 主开发分支（最新功能，可能不稳定）。  
   - **`openssl-3.x`**: 当前稳定版本分支（如 OpenSSL 3.0、3.1 等）。  
   - **`openssl-1.1.x`**: 旧版维护分支（仅修复关键安全漏洞，已结束主流支持）。

3. **文档与资源**：
   - https://wiki.openssl.org/：编译指南、API 文档。  
   - https://github.com/openssl/openssl/issues：提交 Bug 或功能请求。  
   - https://github.com/openssl/openssl/releases：下载稳定版本。

---

### **其他相关仓库**
- **OpenSSL 官网**：https://www.openssl.org  
- **OpenSSL 官方 Docker 镜像**：https://github.com/openssl/tools  

---

### **注意事项**
- **安全建议**：  
  始终使用最新稳定版本（如 OpenSSL 3.x），避免已知漏洞。  
  升级命令（Linux 示例）：
  ```bash
  # 下载最新版
  git clone https://github.com/openssl/openssl.git
  cd openssl
  ./config --prefix=/usr/local/openssl --openssldir=/usr/local/openssl
  #   ./config --prefix=$(pwd)/build --openssldir=/usr/local/openssl
  make
  sudo make install
  ```

- **贡献代码**：  
  提交 Pull Request 前请阅读 https://github.com/openssl/openssl/blob/master/CONTRIBUTING.md。

 

============================================
