# 为什么用asan的配置编译zlib源码得到的libz.a中没有sanitizer的symbol

使用 ASan (AddressSanitizer) 配置编译 zlib 但生成的 libz.a 中没有 sanitizer 符号，可能有以下几个原因：

## 1. 编译选项问题

检查你的编译命令是否**真正**包含了 ASan 标志：

```bash
# 正确的编译方式应该包含：
export CFLAGS="-fsanitize=address -fno-omit-frame-pointer"
export LDFLAGS="-fsanitize=address"

./configure
make
```

## 2. 静态库的特性

静态库（.a 文件）本身可能不会显示所有符号，除非它们被引用。尝试：

```bash
# 查看 libz.a 中的所有目标文件
ar t libz.a

# 查看详细的符号表
nm libz.a | grep -i sanitize
objdump -t libz.a | grep -i sanitize
```

## 3. 链接时才会添加 ASan 运行时

ASan 的大部分功能在**链接阶段**才完整加入。静态库本身只包含编译时插入的检测代码，主要的 sanitizer 运行时库在最终链接可执行文件时添加。

## 4. 验证 ASan 是否真正生效

创建一个测试程序来验证：

```c
// test_zlib.c
#include <zlib.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main() {
    char *buffer = malloc(10);
    // 故意制造一个内存错误来测试 ASan
    buffer[10] = 'x';  // 越界写入
    free(buffer);
    return 0;
}
```

编译并测试：
```bash
# 使用 ASan 编译测试程序
gcc -fsanitize=address -fno-omit-frame-pointer test_zlib.c -L. -lz -o test_zlib

# 运行测试
./test_zlib
```

如果 ASan 正常工作，你会看到类似这样的错误报告：
```
==ERROR: AddressSanitizer: heap-buffer-overflow
```

## 5. 检查 configure 或 Makefile

zlib 可能有自己的编译配置，需要确保 ASan 标志被正确传递：

```bash
# 直接使用 CC 变量覆盖
CC="gcc -fsanitize=address -fno-omit-frame-pointer" ./configure
make
```

## 6. 替代方案：使用共享库

如果问题持续，尝试编译为共享库：
```bash
./configure --shared
make
```

然后检查 libz.so 中的符号。

最可靠的验证方法是**实际运行一个包含内存错误的测试程序**，观察 ASan 是否报告错误。静态库中缺少完整的 sanitizer 符号是正常现象，关键是要确保在最终的可执行文件中 ASan 功能正常工作。