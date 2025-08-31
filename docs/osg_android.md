# 1.在ubuntu上交叉编译 android ndk 程序时，在cmake脚本写的不好的情况下，会链接到ubuntu pc上的.a 或so吗

### **在 Ubuntu 上交叉编译 Android NDK 程序时，是否会意外链接到 PC 的 `.a` 或 `.so`？**

---

#### **1. 问题的本质**
在交叉编译 Android NDK 程序时，如果 CMake 脚本配置不当，**确实可能错误地链接到 Ubuntu 主机上的库**（如 `/usr/lib/x86_64-linux-gnu/` 下的 `.a` 或 `.so`），而非 Android NDK 提供的库。  
这会导致编译出的二进制文件无法在 Android 设备上运行（因架构和依赖不兼容）。

---

### **2. 为什么会发生？**
#### **(1) CMake 默认搜索路径**
CMake 的 `find_library` 或 `find_package` 会按以下顺序搜索库：
1. **系统路径**（如 `/usr/lib`、`/usr/local/lib`）。
2. **NDK 工具链路径**（如 `$NDK/sysroot/usr/lib`）。

如果未显式指定 NDK 的库路径，CMake 可能优先找到主机系统的库。

#### **(2) 未正确设置交叉编译环境**
- **未定义 `CMAKE_SYSROOT`**：未指定 NDK 的 sysroot 路径，导致链接器搜索主机库。
- **未设置 `CMAKE_FIND_ROOT_PATH`**：未限制搜索范围到 NDK 目录。
- **混用 `-L` 和 `-l` 参数**：错误地添加了主机库路径。

---

### **3. 如何避免链接到主机库？**
#### **(1) 正确配置 NDK 工具链**
在 CMake 中显式指定 NDK 的 sysroot 和工具链：
```cmake
set(CMAKE_SYSROOT ${ANDROID_NDK}/sysroot)  # 指定 NDK 的 sysroot
set(CMAKE_FIND_ROOT_PATH ${ANDROID_NDK})   # 限制搜索范围
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY) # 仅搜索 NDK 的库
```

#### **(2) 使用 NDK 提供的 CMake 工具链文件**
在 CMake 命令中直接指定 NDK 的工具链文件：
```bash
cmake .. \
    -DCMAKE_TOOLCHAIN_FILE=${ANDROID_NDK}/build/cmake/android.toolchain.cmake \
    -DANDROID_ABI=arm64-v8a \
    -DANDROID_PLATFORM=android-24
```

#### **(3) 禁止搜索主机路径**
```cmake
set(CMAKE_FIND_USE_SYSTEM_ENVIRONMENT_PATH OFF)  # 禁用系统环境变量路径
set(CMAKE_FIND_USE_CMAKE_SYSTEM_PATH OFF)       # 禁用 CMake 系统路径
```

#### **(4) 显式指定库路径**
```cmake
# 只链接 NDK 提供的库
target_link_libraries(my_app
    ${ANDROID_NDK}/sysroot/usr/lib/aarch64-linux-android/libz.so
)
```

---

### **4. 验证是否链接到正确库**
#### **(1) 检查链接器命令**
在编译时添加 `VERBOSE=1`，查看链接器是否使用了主机库：
```bash
make VERBOSE=1
```
输出中不应出现 `/usr/lib/x86_64-linux-gnu/` 等主机路径。

#### **(2) 使用 `readelf` 或 `objdump`**
检查生成的可执行文件依赖的库：
```bash
aarch64-linux-android-readelf -d my_app | grep NEEDED
```
输出应只显示 NDK 提供的库（如 `libc++_shared.so`），而非主机库（如 `libz.so.1`）。

#### **(3) 使用 `ldd`（模拟 Android 环境）**
通过 QEMU 模拟 Android 环境检查依赖：
```bash
qemu-aarch64 -L ${ANDROID_NDK}/sysroot/usr/lib/aarch64-linux-android ./my_app
```

---

### **5. 常见错误案例**
#### **错误 1：链接到主机的 `libz.so`**
```cmake
# 错误：未指定路径，可能找到主机的 libz
target_link_libraries(my_app z)
```
**修复**：显式链接 NDK 的 `libz`：
```cmake
target_link_libraries(my_app ${ANDROID_NDK}/sysroot/usr/lib/libz.so)
```

#### **错误 2：未隔离系统路径**
```cmake
# 错误：未禁用系统路径
find_package(ZLIB REQUIRED)
```
**修复**：限制搜索范围：
```cmake
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
find_package(ZLIB REQUIRED)
```

---

### **6. 总结**
| **关键点**                | **解决方案**                                                                 |
|---------------------------|-----------------------------------------------------------------------------|
| **工具链配置**            | 使用 `android.toolchain.cmake`，设置 `CMAKE_SYSROOT` 和 `CMAKE_FIND_ROOT_PATH`。 |
| **禁止搜索主机库**        | 设置 `CMAKE_FIND_USE_SYSTEM_ENVIRONMENT_PATH=OFF`。                          |
| **显式指定库路径**        | 直接链接 NDK 提供的库路径（如 `${ANDROID_NDK}/sysroot/usr/lib/...`）。       |
| **验证依赖**              | 通过 `readelf` 或 `ldd` 检查输出文件的动态库依赖。                          |

**最终建议**：始终使用 NDK 的 CMake 工具链文件，并严格限制库搜索路径！

================================================================
# 2. CMAKE_SYSTEM_ROOT 和 CMAKE_FIND_ROOT_PATH

是的，在 CMake 交叉编译场景中，**目标平台的根路径（目标系统根文件系统）主要对应 `CMAKE_SYSTEM_ROOT` 变量**，但它与 `CMAKE_FIND_ROOT_PATH` 存在关联，二者共同影响文件查找行为，需要结合理解：


### 1. 核心结论：目标平台根路径的“官方代表”是 `CMAKE_SYSTEM_ROOT`
`CMAKE_SYSTEM_ROOT` 是 CMake 中**专门定义“目标平台根文件系统路径”** 的变量，其语义非常明确：  
它指向目标平台（即你最终要运行程序的平台，如 ARM 嵌入式设备、Android 系统）的根目录（类似 Linux 系统的 `/` 目录），包含目标平台的 `bin`、`lib`、`include` 等标准目录。

例如，在 x86 主机上为 ARM 嵌入式设备编译时，若 ARM 设备的根文件系统打包在主机的 `/opt/arm-rootfs` 目录下，则需设置：  
```bash
cmake -DCMAKE_SYSTEM_ROOT=/opt/arm-rootfs ...
```


### 2. 关键关联：`CMAKE_SYSTEM_ROOT` 与 `CMAKE_FIND_ROOT_PATH` 的关系
你之前提到的 `CMAKE_FIND_ROOT_PATH` 是 **“查找路径的补充/扩展”**，它与 `CMAKE_SYSTEM_ROOT` 的关系如下：
- **默认继承**：若未显式设置 `CMAKE_FIND_ROOT_PATH`，CMake 会自动将 `CMAKE_SYSTEM_ROOT` 加入到 `CMAKE_FIND_ROOT_PATH` 的查找列表中（即默认用目标根路径参与查找）；
- **显式扩展**：若你显式设置了 `CMAKE_FIND_ROOT_PATH`（如 `-DCMAKE_FIND_ROOT_PATH=/path/to/extra-libs`），则查找列表会包含 **`CMAKE_SYSTEM_ROOT + 你设置的额外路径`**。

简单说：`CMAKE_SYSTEM_ROOT` 是“目标根路径的基准”，`CMAKE_FIND_ROOT_PATH` 是“基于基准的查找路径集合”，二者共同构成了 CMake 对“目标平台路径”的查找范围。


### 3. 回到原问题：为何“禁止从目标根路径查找程序”关联这两个变量？
当你设置 `-DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER` 时，其本质是：  
**禁止 CMake 在“`CMAKE_FIND_ROOT_PATH` 包含的所有路径”中查找程序**——而由于 `CMAKE_FIND_ROOT_PATH` 默认包含 `CMAKE_SYSTEM_ROOT`（目标根路径），因此这一配置间接实现了“禁止从目标平台根路径（`CMAKE_SYSTEM_ROOT`）查找程序”的效果。

举个具体例子（交叉编译 ARM 程序）：
- 若未设置 `CMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER`：CMake 会先在 `CMAKE_SYSTEM_ROOT/bin`（目标平台的 `bin` 目录，如 `/opt/arm-rootfs/bin`）中查找 `gcc`，但该目录下的 `gcc` 是 ARM 版本（无法在 x86 主机运行），会导致编译失败；

- 若设置了 `CMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER`：CMake 会跳过 `CMAKE_SYSTEM_ROOT/bin`（及 `CMAKE_FIND_ROOT_PATH` 包含的其他目标路径），直接在主机的 `PATH` 路径（如 `/usr/bin`）中查找 x86 版本的 `gcc`，确保工具可用。


### 4. 两个变量的核心区别（避免混淆）
为了更清晰区分，可参考下表：

| 变量                | 核心语义                                  | 作用场景                                  |
|---------------------|-------------------------------------------|-------------------------------------------|
| `CMAKE_SYSTEM_ROOT` | 目标平台的**根文件系统路径**（基准）      | 定义目标系统的“根目录”，是交叉编译的基础配置 |
| `CMAKE_FIND_ROOT_PATH` | 补充的**查找路径集合**（扩展）          | 额外指定目标平台的库/头文件路径（如第三方库） |


### 总结
- **目标平台的根路径”的官方变量是 `CMAKE_SYSTEM_ROOT`**，它代表目标系统的根目录；
- `CMAKE_FIND_ROOT_PATH` 会默认包含 `CMAKE_SYSTEM_ROOT`，因此 `CMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER` 通过禁止搜索 `CMAKE_FIND_ROOT_PATH`，间接实现了“禁止从目标根路径（`CMAKE_SYSTEM_ROOT`）查找程序”；
- 交叉编译中，`CMAKE_SYSTEM_ROOT` 是“目标根路径的基准”，`CMAKE_FIND_ROOT_PATH` 是“查找范围的扩展”，二者共同影响文件查找行为。