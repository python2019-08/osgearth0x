# 1.CMAKE_CXX_FLAGS 和 add_compile_options的优先级

在 CMake 中，**`CMAKE_CXX_FLAGS` 和 `add_compile_options()` 的优先级取决于设置顺序**，但通常遵循特定的规则：

## 优先级规则（从高到低）

1. **`target_compile_options()`** （最高优先级）
2. **`add_compile_options()`** 
3. **`CMAKE_CXX_FLAGS`** 
4. **`CMAKE_CXX_FLAGS_<CONFIG>`**（如 `CMAKE_CXX_FLAGS_RELEASE`）

## 实际执行顺序

```cmake
# 1. 首先应用 CMAKE_CXX_FLAGS（基础标志）
set(CMAKE_CXX_FLAGS "-Wall -Wextra")

# 2. 然后应用 add_compile_options()（追加）
add_compile_options("-O2")

# 3. 最后应用 target_compile_options()（覆盖）
target_compile_options(my_target PRIVATE "-O3")
```

## 示例验证

### CMakeLists.txt:
```cmake
cmake_minimum_required(VERSION 3.10)
project(TestFlags)

# 级别1：基础标志
set(CMAKE_CXX_FLAGS "-Wall -std=c++11")

# 级别2：全局编译选项
add_compile_options("-O2")

# 级别3：目标特定选项（最高优先级）
add_executable(test_app main.cpp)
target_compile_options(test_app PRIVATE "-O3 -DDEBUG=1")
```

### 最终编译命令：
```bash
# 实际执行的编译命令（按优先级合并）：
clang++ -Wall -std=c++11 -O2 -O3 -DDEBUG=1 main.cpp -o test_app
# ^^^^^^^^^  ^^^^^^^^^^^ ^^^^ ^^^^^^^^^^^^^^
# CMAKE_CXX  add_compile  target_compile
# _FLAGS     _options     _options（优先级最高）
```

## 冲突解决规则

### 相同选项：后者覆盖前者
```cmake
add_compile_options("-O2")
target_compile_options(my_target PRIVATE "-O3")  # -O3 生效
```

### 不同选项：合并
```cmake
add_compile_options("-Wall")
target_compile_options(my_target PRIVATE "-Wextra")  # 同时生效：-Wall -Wextra
```

## 推荐的最佳实践

### 1. 使用分层设置：
```cmake
# 基础配置（最低优先级）
set(CMAKE_CXX_FLAGS "-std=c++17 -pthread")

# 项目全局选项（中等优先级）
add_compile_options("-Wall", "-Wextra")

# 目标特定选项（最高优先级）
target_compile_options(my_lib PRIVATE "-O3")
target_compile_options(my_app PRIVATE "-O2")
```

### 2. 使用生成器表达式进行条件设置：
```cmake
# 根据配置类型设置不同选项
target_compile_options(my_target
  PRIVATE
    "$<$<CONFIG:Release>:-O3>"
    "$<$<CONFIG:Debug>:-O0 -g>"
)
```

### 3. 避免标志冲突：
```cmake
# 不推荐：可能冲突
set(CMAKE_CXX_FLAGS "-O2")
add_compile_options("-O3")  # 冲突！

# 推荐：清晰分层
set(CMAKE_CXX_FLAGS "-std=c++17")      # 语言标准
add_compile_options("-Wall")          # 警告级别  
target_compile_options(my_target PRIVATE "-O3")  # 优化级别
```

## 调试标志优先级

查看最终编译命令：
```cmake
# 显示详细编译命令
set(CMAKE_VERBOSE_MAKEFILE ON)

# 或者使用 message() 调试
get_target_property(FLAGS my_target COMPILE_OPTIONS)
message("Final flags: ${FLAGS}")
```

## 总结

**优先级顺序**：  
`target_compile_options() > add_compile_options() > CMAKE_CXX_FLAGS`

**推荐策略**：
- 使用 `CMAKE_CXX_FLAGS` 设置**编译器无关**的基础选项
- 使用 `add_compile_options()` 设置**项目全局**选项
- 使用 `target_compile_options()` 设置**目标特定**选项

这样既能保持灵活性，又能避免意外的标志覆盖。
================================================================
# 2. osg的android arm64依赖库 有的是用-std=c++17 编译的，有的是用-std=gnu++17 ，这两种库编译osg 的so时会有冲突吗

这两种标准编译的库在链接时**通常不会有冲突**，但存在一些潜在风险。以下是详细分析：

## 1. ABI 兼容性分析

### C++ ABI 的关键组成部分：
| ABI 组件 | C++14 vs C++17 | c++17 vs gnu++17 |
|---------|----------------|------------------|
| **名称修饰** | ✅ 基本兼容 | ✅ 完全一致 |
| **内存布局** | ✅ 结构体/类兼容 | ✅ 完全一致 |
| **异常处理** | ✅ 兼容 | ✅ 完全一致 |
| **RTTI** | ✅ 兼容 | ✅ 完全一致 |

### 关键结论：
- **`-std=c++17` 和 `-std=gnu++17` 使用相同的 ABI**
- **主要区别在于语言特性和 GNU 扩展的可用性**

## 2. 潜在冲突场景

### 场景一：头文件包含时的语法差异
```cpp
// 如果某个头文件使用了 GNU 扩展
#ifdef __GNUC__
// GNU 特定语法
__attribute__((always_inline)) 
#endif
void some_function();

// 用 -std=c++17 编译时会报错，因为 __attribute__ 是 GNU 扩展
```

### 场景二：标准库实现的细微差异
```cpp
// 不同标准可能暴露不同的符号
// gnu++17 可能提供额外的 GNU 扩展函数
```

### 场景三：预处理器的差异
```cpp
// gnu++17 可能定义额外的宏
#ifdef __GLIBCXX__  // GNU libstdc++ 特定宏
// 某些扩展功能
#endif
```

## 3. OSG 的具体情况分析

### OSG 的代码特点：
```cpp
// OSG 通常使用标准 C++，较少依赖 GNU 扩展
// 示例：osg/Referenced.cpp
Referenced::Referenced()
{
    _refCount = 0;
    _refMutex = new Mutex();
}

// 大多数是标准 C++ 代码，ABI 风险较低
```

### 但需要注意的 OSG 组件：
- **插件系统**：可能使用平台特定功能
- **线程和同步**：可能使用 GNU 扩展
- **数学库**：可能使用编译器特定优化

## 4. 实际验证方法

### 方法一：检查符号兼容性
```bash
# 检查两个库的符号表
nm -D lib_compiled_with_gnu17.so | grep -i osg | head -10
nm -D lib_compiled_with_cxx17.so | grep -i osg | head -10

# 比较关键符号是否一致
objdump -T libosg.so | grep -E "GLIBC|GCC"
```

### 方法二：编译时检测
```bash
# 尝试链接并观察错误
clang++ -std=c++17 main.cpp -losg -lother_gnu17_lib -o test

# 或者强制统一标准
clang++ -std=gnu++17 main.cpp -losg -lother_lib -o test
```

### 方法三：运行时测试
```cpp
// 简单的兼容性测试
#include <osg/Version>
#include <iostream>

int main() {
    std::cout << "OSG version: " << osgGetVersion() << std::endl;
    
    // 测试基本功能
    osg::ref_ptr<osg::Group> root = new osg::Group();
    std::cout << "OSG basic functionality OK" << std::endl;
    
    return 0;
}
```

## 5. 解决方案和最佳实践

### 方案一：统一编译标准（推荐）
```bash
# 重新编译所有依赖库为统一标准
# 推荐使用 -std=gnu++17（兼容性更好）

# 编译 OSG 和所有依赖
clang++ -std=gnu++17 -shared -o libosg.so osg_files.cpp
```

### 方案二：使用兼容性包装
```cmake
# CMakeLists.txt 中统一标准
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# 强制所有目标使用相同标准
if(ANDROID)
    # Android 上建议使用 GNU 扩展以获得更好兼容性
    set(CMAKE_CXX_EXTENSIONS ON)  # 相当于 -std=gnu++17
else()
    set(CMAKE_CXX_EXTENSIONS OFF) # 相当于 -std=c++17
endif()
```

### 方案三：分层链接策略
```cmake
# 将不同标准的库分层链接
target_link_libraries(osg_core
    lib_compiled_with_cxx17  # 核心库用严格标准
)

target_link_libraries(osg_plugins
    osg_core
    lib_compiled_with_gnu17  # 插件可以用 GNU 扩展
)
```

## 6. Android 特定考虑

### Android NDK 的情况：
```bash
# Android NDK 的 C++ 库相对统一，冲突风险较低
# 但仍建议统一标准

# 检查 NDK 的默认标准
find $ANDROID_NDK -name "*.mk" -exec grep -l "c++_standard" {} \;
```

### 推荐配置：
```cmake
# 针对 Android arm64 的最佳实践
set(ANDROID_STL c++_shared)  # 使用共享 C++ 运行时
set(ANDROID_CPP_FEATURES "rtti exceptions")  # 启用 RTTI 和异常

# 统一 C++ 标准
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=gnu++17")
```

## 7. 风险缓解措施

### 编译时检查：
```cpp
// 在 OSG 代码中添加静态断言
static_assert(__cplusplus >= 201703L, "Requires C++17 or later");

// 检查 GNU 扩展兼容性
#ifndef __STRICT_ANSI__
// 安全地使用 GNU 扩展
#endif
```

### 运行时兼容性检查：
```cpp
void check_abi_compatibility() {
    // 验证关键类型的尺寸
    static_assert(sizeof(std::string) == EXPECTED_SIZE, 
                  "ABI compatibility check failed");
}
```

## 8. 结论

**对于 OSG Android arm64 编译**：

1. **大概率不会冲突**：OSG 主要使用标准 C++，ABI 兼容性好
2. **建议统一标准**：使用 `-std=gnu++17` 编译所有依赖库
3. **重点测试**：特别是插件系统和线程相关功能
4. **Android 兼容性好**：NDK 环境相对统一，风险较低

**推荐操作**：重新用 `-std=gnu++17` 编译所有库，确保标准统一，这样可以避免潜在的边界情况。