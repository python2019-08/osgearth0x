# 1.gdb 和 valgrind 在调试 C++ 时有什么核心区别？简要回答
核心区别：  
- **gdb**：主打「运行时调试」，可断点、单步执行、查看变量/寄存器，定位逻辑错误（如数组越界、空指针调用），不依赖特殊编译选项（加 `-g` 即可）；  
- **valgrind**：主打「内存问题检测」，通过模拟执行监测内存泄漏、野指针、越界访问、双重释放等，需特殊编译（建议 `-O0 -g`），运行开销大，但无需手动设置断点。  

简单说：gdb 查「逻辑错」，valgrind 查「内存错」。

# 2.请谈谈 C++ 中内存泄漏和段错误 (Segfault) 的常见成因与修复思路。简要回答

### 一、内存泄漏
- **常见成因**：1. 动态分配内存（`new`/`malloc`）后未释放（`delete`/`free`）；2. 智能指针循环引用；3. 容器/集合未清理元素导致资源滞留。
- **修复思路**：1. 优先用智能指针（`unique_ptr`/`shared_ptr`）自动管理内存；2. 配对使用分配/释放函数，避免遗漏；3. 用 Valgrind/ASAN 检测泄漏点；4. 避免智能指针循环引用（用 `weak_ptr` 打破依赖）。

### 二、段错误（Segfault）
- **常见成因**：1. 访问空指针（`nullptr->xxx`）；2. 数组/缓冲区越界访问；3. 访问已释放的野指针；4. 栈溢出（递归过深/局部变量过大）；5. 权限错误（写只读内存）。
- **修复思路**：1. 指针使用前判空、边界检查；2. 避免野指针（释放后置空，不跨作用域引用局部变量）；3. 用 GDB 断点调试定位崩溃位置，查看核心转储（core dump）；4. 优化递归深度/局部变量大小，避免栈溢出。

# 3.你如何使用 valgrind（或 ASan）检测并定位 C++ 内存泄漏？简要回答

### 一、Valgrind（memcheck）使用
> 1. 编译：加 `-g -O0`（保留调试信息，禁用优化）；
> 2. 运行：`valgrind --leak-check=full ./程序名`；
> 3. 定位：查看日志中 `definitely lost` 条目，根据堆栈信息（文件名+行号）找到未释放的内存分配点；
> 4. 修复：补充 `delete`/`free`，或改用智能指针。

### 二、ASan（AddressSanitizer）使用
> 1. 编译：加 `-fsanitize=address -g -O1`（ASan 兼容低优化）；
> 2. 运行：直接执行 `./程序名`；
> 3. 定位：程序退出时输出泄漏报告，含详细堆栈（分配/未释放路径）；
> 4. 修复：按报告定位泄漏点，清理未释放的动态内存/资源。

核心：依赖编译选项注入检测逻辑，通过堆栈日志精准定位泄漏源头。

# 4.C++ 项目使用 CMake 时，最常见的构建失败原因有哪些？简要回答

> 1. 依赖库未找到（`find_package` 失败，路径未配置或库未安装）；
> 2. 头文件/源文件路径错误（`include_directories` 缺失、文件路径拼写错误）；
> 3. 编译选项不兼容（C++ 标准版本不匹配、架构/ABI 不一致、编译器选项冲突）；
> 4. 链接错误（库文件缺失、链接顺序错误、静态/动态库混用）；
> 5. CMake 版本过低（不支持新项目语法/模块）；
> 6. 变量未定义（依赖变量未设置、缓存变量冲突）；
> 7. 交叉编译配置错误（工具链文件路径错误、目标平台参数不匹配）。

# 5.如何在 GDB 中快速判断一个多线程 C++ 程序是否发生了死锁？简要回答

> 1. 运行 `info threads` 查看所有线程状态（死锁时线程多为 `__lll_lock_wait`/`pthread_mutex_lock` 等阻塞状态）；
> 2. 对阻塞线程执行 `thread <id>` 切换线程，再用 `bt` 查看调用栈，确认是否卡在锁操作；
> 3. 执行 `info locks`（或 `info threads -l`）查看各线程持有的锁和等待的锁，判断是否存在循环等待；
> 4. 结合 `pthread_mutex_t` 变量值（如通过 `print mutex` 查看锁状态）辅助验证。

核心：通过线程状态、锁持有/等待关系，定位循环等待的锁依赖。

# 6.你会如何设计一个 C++ 项目的自动化 CI Pipeline（包含构建、测试、内存检查）？简要回答
doubaoAI:
> 1. 环境准备：CI 服务器（如 GitHub Actions/GitLab CI）配置 C++ 编译器、CMake、vcpkg/依赖库、GTest/Boost.Test、Valgrind/ASan；
> 2. 构建阶段：拉取代码 → 执行 CMake 生成构建文件（指定架构/编译选项）→ 编译项目（Debug/Release 双模式）；
> 3. 测试阶段：运行单元测试（GTest）/集成测试，输出测试覆盖率（gcov/lcov）；
> 4. 内存检查：用 ASan 编译运行测试（快速检测泄漏/越界），关键模块用 Valgrind 补充验证；
> 5. 结果反馈：构建/测试/内存检查失败触发告警，生成报告（测试覆盖率、内存问题日志）。

YuanbaoAI: 我会设计一个基于现代CI工具的多阶段Pipeline，以下是简洁设计：

## 1. Pipeline阶段设计

```yaml
# 示例：GitLab CI 或 GitHub Actions
stages:
  - build          # 编译构建
  - test          # 单元测试
  - memory_check  # 内存检查
  - security_scan # 安全扫描
  - deploy        # 部署（可选）
```

## 2. 各阶段具体配置

### Stage 1: 构建阶段
```yaml
build_job:
  stage: build
  script:
    - cmake -B build -DCMAKE_BUILD_TYPE=Release
    - cmake --build build --parallel 4
    - ctest --test-dir build --output-on-failure
  artifacts:
    paths:
      - build/
      - bin/
```

### Stage 2: 测试阶段
```yaml
unit_tests:
  stage: test
  script:
    - ./run_unit_tests --gtest_output=xml:test_results.xml
    - # 生成测试覆盖率报告
  coverage: '/Coverage: (\d+)%/'
```

### Stage 3: 内存检查阶段
```yaml
memory_check:
  stage: memory_check
  script:
    - # 编译带ASan的版本
    - cmake -B build_asan -DCMAKE_BUILD_TYPE=Debug -DUSE_ASAN=ON
    - cmake --build build_asan
    - # 运行内存检查测试
    - ./run_memory_tests
    - valgrind --leak-check=full ./memory_intensive_tests
```

## 3. 关键工具集成

### 编译配置
```cmake
# CMakePresets.json
{
  "configurePresets": [
    {
      "name": "ci-debug",
      "cacheVariables": {
        "CMAKE_BUILD_TYPE": "Debug",
        "USE_ASAN": "ON",
        "BUILD_TESTING": "ON"
      }
    }
  ]
}
```

### 内存检查配置
```bash
# ASan 编译选项
export CFLAGS="-fsanitize=address -fno-omit-frame-pointer"
export CXXFLAGS="-fsanitize=address -fno-omit-frame-pointer"
export LDFLAGS="-fsanitize=address"
```

## 4. 触发条件优化

```yaml
# 智能触发规则
rules:
  - if: $CI_COMMIT_BRANCH == "main"
    when: always
  - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    when: always
  - if: $CI_COMMIT_TAG
    when: manual  # 标签发布手动触发
```

## 5. 缓存优化

```yaml
cache:
  key: "$CI_COMMIT_REF_SLUG"
  paths:
    - build/
    - vcpkg/installed/
    - .cache/ccache/
  policy: pull-push
```

## 6. 关键质量门禁

- **编译成功率**: 100%
- **测试通过率**: ≥95%
- **内存泄漏**: 零容忍
- **代码覆盖率**: ≥80%

## 7. 通知机制

```yaml
notifications:
  on_success: 
    - slack:#ci-success
  on_failure:
    - slack:#ci-failures
    - email:team@company.com
```

这样设计的Pipeline具备快速反馈、全面检查、资源优化等特点，适合现代C++项目的持续集成需求。

# 7.Terminal-Bench 题目示例：如果要设计一个“修复 C++ 段错误”的任务，你会如何设置场景（源码、GDB）和评分逻辑？简要回答

### 场景设置
> 1. 源码：提供含典型段错误（如空指针访问、数组越界、野指针操作）的极简C++代码（50行内），带编译脚本（`CMakeLists.txt`/`Makefile`）；
> 2. GDB环境：预置编译好的带调试信息（`-g`）的可执行文件，提供核心转储（core dump）文件或直接在CI中模拟GDB交互；
> 3. 任务要求：用GDB定位段错误根因（行号+成因），修复代码并验证无崩溃。

### 评分逻辑
> 1. 定位准确性（40%）：是否通过GDB `bt`/`info threads`等命令精准找到崩溃行和成因；
> 2. 修复正确性（40%）：修复后代码无段错误，逻辑正常（无新bug）；
> 3. 调试规范性（20%）：GDB操作步骤简洁合理（如断点、变量查看等命令使用正确）。

# 8.Terminal Bench执行命令uv run tb run --agent oracle和 --agent terminus有什么区别？简要回答

核心区别在于**执行任务的代理类型（后端/能力不同）**：  
- `--agent oracle`：使用 Oracle 相关代理（可能是预置规则、官方参考实现或特定环境适配的后端），侧重标准化、基准化执行；  
- `--agent terminus`：使用 Terminus 代理（可能是自定义、第三方或侧重终端交互/调试的后端），侧重灵活适配终端场景（如 GDB 调试、命令行操作）。  

简单说：oracle 偏向“标准基准代理”，terminus 偏向“终端交互代理”，适配不同任务场景（如基准验证 vs 终端调试类任务）。

