# 1.如何使用valgrind

Valgrind 是一个强大的内存调试和性能分析工具集。以下是详细的使用指南：

## 1. 安装 Valgrind

### Ubuntu/Debian
```bash
sudo apt-get install valgrind
```

### CentOS/RHEL
```bash
sudo yum install valgrind
```

### macOS
```bash
brew install valgrind
```

## 2. 基本使用方法

### 内存检测（最常用）
```bash
valgrind --leak-check=full ./your_program
```

### 更详细的内存检测
```bash
valgrind --leak-check=full --show-leak-kinds=all --track-origins=yes ./your_program
```

## 3. 主要工具介绍

### Memcheck（默认工具）- 内存错误检测
```bash
# 检测内存泄漏
valgrind --tool=memcheck ./your_program

# 生成详细报告
valgrind --leak-check=full --track-origins=yes --log-file=valgrind.log ./your_program
```

### Cachegrind - 缓存分析
```bash
valgrind --tool=cachegrind ./your_program
```

### Callgrind - 调用图分析
```bash
valgrind --tool=callgrind ./your_program
```

### Massif - 堆分析
```bash
valgrind --tool=massif ./your_program
```

## 4. 实际使用示例

### 示例程序（有内存问题的C程序）
```c
// test.c
#include <stdlib.h>

void leak_memory() {
    malloc(100); // 内存泄漏
}

int main() {
    int *ptr = malloc(10 * sizeof(int));
    ptr[10] = 0; // 数组越界
    leak_memory();
    free(ptr);
    return 0;
}
```

### 编译和检测
```bash
# 编译时添加调试信息
gcc -g test.c -o test

# 使用valgrind检测
valgrind --leak-check=full --track-origins=yes ./test
```

## 5. 常用参数详解

```bash
--leak-check=full      # 完全泄漏检查
--show-leak-kinds=all  # 显示所有类型的泄漏
--track-origins=yes    # 跟踪未初始化值的来源
--log-file=file        # 输出到文件
--verbose              # 详细输出
--quiet                # 安静模式
--error-exitcode=1     # 发现错误时返回非零退出码
```

## 6. 解读输出结果

Valgrind 输出包含几个重要部分：

### 错误类型示例
```
==12345== Invalid write of size 4
==12345==    at 0x400123: main (test.c:8)
==12345==  Address 0x5200048 is 0 bytes after a block of size 40 alloc'd

==12345== 100 bytes in 1 blocks are definitely lost
==12345==    at 0x4C2AB80: malloc (vg_replace_malloc.c:299)
==12345==    by 0x400567: leak_memory (test.c:4)
```

## 7. 高级用法

### 抑制已知错误
创建抑制文件 `suppressions.txt`：
```
{
   <suppression_name>
   Memcheck:Leak
   fun:some_library_function
}
```

使用抑制文件：
```bash
valgrind --suppressions=suppressions.txt ./your_program
```

### 与GDB配合使用
```bash
valgrind --vgdb=yes --vgdb-error=0 ./your_program
```

然后在另一个终端：
```bash
gdb ./your_program
(gdb) target remote | vgdb
```

## 8. 实用技巧

1. **编译时一定要加 `-g` 选项**，这样才能看到具体的代码行号
2. **优化级别不要太高**，建议使用 `-O0` 或 `-O1`
3. **定期运行valgrind**，作为开发流程的一部分
4. **结合自动化测试**，在CI/CD流程中加入valgrind检查

## 9. 常见问题解决

如果valgrind报告大量系统库的"错误"，这些通常是误报，可以使用：
```bash
valgrind --track-origins=yes --show-possibly-lost=no ./your_program
```

Valgrind 是C/C++程序员必备的调试工具，熟练掌握可以大大提升代码质量和调试效率。

=================================================================
# 2. 如何使用memwatch

`memwatch` 是一个轻量级的内存泄漏检测工具。以下是详细的使用方法：

## 1. 安装 memwatch

### 下载源码：
```bash
wget http://memwatch.sourceforge.net/memwatch-2.71.tar.gz
tar -xzf memwatch-2.71.tar.gz
cd memwatch
```

### 或者直接从源码使用：
```c
// 直接包含 memwatch.h 即可，无需编译成库
#include "memwatch.h"
```

## 2. 基本使用方法

### 方法一：包含头文件方式（推荐）
```c
#include <stdio.h>
#include <stdlib.h>
#include "memwatch.h"  // 确保 memwatch.h 在编译路径中

void test_memory_leak() {
    // 这个内存不会被释放（用于测试）
    char *leak = malloc(100);
    strcpy(leak, "This will leak");
    
    // 这个内存会被正确释放
    char *no_leak = malloc(50);
    strcpy(no_leak, "This won't leak");
    free(no_leak);
}

int main() {
    printf("Memwatch test started\n");
    test_memory_leak();
    printf("Memwatch test completed\n");
    return 0;
}
```

### 编译命令：
```bash
gcc -DMEMWATCH -DMW_STDIO test.c memwatch.c -o test
```

## 3. 编译选项和配置

### 必要的编译定义：
```bash
# 基本编译
gcc -DMEMWATCH -DMW_STDIO your_program.c memwatch.c -o program

# 如果需要记录到文件
gcc -DMEMWATCH -DMEMWATCH_STDIO your_program.c memwatch.c -o program

# Android NDK 编译示例
aarch64-linux-android-clang -DMEMWATCH -DMW_STDIO app.c memwatch.c -o app
```

### 常用预处理器定义：
| 定义 | 作用 |
|------|------|
| `MEMWATCH` | 启用 memwatch |
| `MW_STDIO` | 使用标准 I/O 输出 |
| `MEMWATCH_STDIO` | 输出到文件 |
| `MW_NO_STDIO` | 禁用所有 I/O（嵌入式用） |

## 4. 高级配置

### 创建配置文件 `mwconfig.h`：
```c
// mwconfig.h
#ifndef MWCONFIG_H
#define MWCONFIG_H

#define MEMWATCH
#define MW_STDIO
#define MW_DEBUG

// 自定义输出函数
extern void my_printf(const char* fmt, ...);
#define MW_PRINTF my_printf

// 限制跟踪的分配数量
#define MW_ABORT_ON_ASSERT
#define MW_TRACK_MAX 1000

#endif
```

## 5. 在项目中的集成

### CMake 集成：
```cmake
# CMakeLists.txt
add_definitions(-DMEMWATCH -DMW_STDIO)

# 添加 memwatch 源文件
add_library(memwatch STATIC memwatch.c)

# 链接到你的目标
target_link_libraries(your_target memwatch)
```

### Android.mk 集成：
```makefile
# Android.mk
LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)
LOCAL_MODULE := memwatch
LOCAL_SRC_FILES := memwatch.c
LOCAL_CFLAGS += -DMEMWATCH -DMW_STDIO
include $(BUILD_STATIC_LIBRARY)

include $(CLEAR_VARS)
LOCAL_MODULE := your_app
LOCAL_SRC_FILES := main.c
LOCAL_STATIC_LIBRARIES := memwatch
include $(BUILD_EXECUTABLE)
```

## 6. 输出结果分析

memwatch 会在程序退出时生成报告：

### 典型输出：
```
============= MEMWATCH 2.71 Copyright (C) 1992-1999 Johan Lindh =============

Started at Sat Jan 1 12:00:00 2024
Modes: MW_STDIO MW_TRACE 

double-free: <1> test.c(15), 100 bytes at 0x12345678 was freed again.
...
Stopped at Sat Jan 1 12:00:05 2024

unfreed: <1> test.c(5), 100 bytes at 0x12345678   {0..99}
This is a memory leak.
```

## 7. 自定义处理函数

```c
#include "memwatch.h"

// 自定义错误处理
void my_memwatch_error(int type, const char* msg) {
    fprintf(stderr, "MEMWATCH ERROR [%d]: %s\n", type, msg);
    
    // 对于严重错误，可以中止程序
    if (type == MW_ERROR_ABORT) {
        abort();
    }
}

// 注册自定义处理函数
mwSetErrorHandler(my_memwatch_error);
```

## 8. 与 ASan 的对比

| 特性 | memwatch | AddressSanitizer (ASan) |
|------|----------|------------------------|
| **开销** | 较小 | 较大（2x CPU, 3x 内存） |
| **功能** | 基础内存泄漏检测 | 完整内存错误检测 |
| **平台支持** | 所有平台 | 需要编译器支持 |
| **易用性** | 简单 | 需要特定编译选项 |

## 9. 实际使用示例

### 检测特定模块：
```c
#include "memwatch.h"

void sensitive_function() {
    // 开始内存检查
    mwStart();
    
    char* buffer = malloc(1024);
    // ... 使用 buffer
    // 忘记 free(buffer) 会被检测到
    
    // 结束检查并报告
    mwStop();
}

int main() {
    sensitive_function();
    
    // 生成最终报告
    mwReport();
    return 0;
}
```

## 10. 注意事项

1. **性能影响**：memwatch 会减慢程序运行速度
2. **不是线程安全**：旧版本可能不支持多线程
3. **嵌入式系统**：可能需要调整 `MW_` 开头的配置参数
4. **与其他工具冲突**：不要同时使用多个内存检测工具

## 总结

memwatch 是一个简单有效的内存检测工具，特别适合：
- 快速检测内存泄漏
- 嵌入式系统或资源受限环境
- 不需要完整 ASan 功能的场景

对于复杂的项目，建议使用更现代的工具如 AddressSanitizer，但 memwatch 在简单场景下仍然很有用。