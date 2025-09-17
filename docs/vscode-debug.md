# 按F5时，运行.vscode/tasks.json的哪个task 
 
 按F5时，运行下面的哪个task 
```
// .vscode/tasks.json
{
    "version": "2.0.0",
    "tasks": [
        {
            "label": "cmake-configure",
            "type": "shell",
            "command": "${workspaceFolder}/scripts/osgearth-configure.sh",
            "args": [ ],
            "problemMatcher": [],
            "group": {
                "kind": "build",
                "isDefault": false
            }
        },
        {
            "label": "cmake-build",
            "type": "shell",
            "command": "cmake --build build/ubuntu",
            "problemMatcher": ["$gcc"],
            "group": {
                "kind": "build",
                "isDefault": true
            },
            "dependsOn": ["cmake-configure"]
        },
        {
            "label": "cmake-build-only",
            "type": "shell",
            // 使用 --target只编译当前调试的目标（如 osgearth_viewer）
            "command": "cmake --build build/ubuntu --target osgearth_viewer",  // 只编译特定目标
            "problemMatcher": ["$gcc"],
            "group": {
                "kind": "build",
                "isDefault": false
            }
        }
    ]
}
```

当您按 `F5` 调试时，**实际运行的 task 由 `launch.json` 中的 `preLaunchTask` 字段决定**。根据您提供的 `tasks.json`，以下是具体分析：

---

### **1. 关键规则**
- **`F5` 的默认行为**：  
  如果没有在 `launch.json` 中指定 `preLaunchTask`，VSCode 会尝试运行 `tasks.json` 中标记为 `"isDefault": true` 的构建任务（即 `group` 中 `"isDefault": true` 的任务）。
- **您的配置**：  
  在 `tasks.json` 中，只有 `cmake-build` 任务设置了 `"isDefault": true`。

---

### **2. 当前按 `F5` 时的行为**
#### **情况一：如果 `launch.json` 未设置 `preLaunchTask`**
- **自动运行**：`cmake-build`（因为它是默认任务）  
  → 这会触发完整的项目编译（包括所有目标）  
  → 并先执行 `cmake-configure`（因为 `dependsOn` 依赖）

#### **情况二：如果 `launch.json` 设置了 `preLaunchTask`**
```json
// .vscode/launch.json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Debug osgearth_viewer",
            "preLaunchTask": "cmake-build-only",  // 明确指定任务
            // ... 其他配置
        }
    ]
}
```
- **自动运行**：`cmake-build-only`  
  → 仅编译 `osgearth_viewer` 目标（增量编译，更快）  
  → **不会触发 `cmake-configure`**（因为没有 `dependsOn`）

---

### **3. 如何验证当前运行的 Task？**
#### **方法一：查看 VSCode 输出面板**
按 `F5` 后，观察 **终端输出** 或 **“问题”面板**，会显示实际运行的 Task 名称：
```
> Executing task: cmake-build <
```

#### **方法二：检查 `launch.json`**
确认是否有 `preLaunchTask` 字段：
```bash
cat .vscode/launch.json | grep "preLaunchTask"
```

---

### **4. 推荐配置方案**
#### **目标**：按 `F5` 时 **仅编译当前调试目标**（如 `osgearth_viewer`）
```json
// .vscode/launch.json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Debug osgearth_viewer",
            "preLaunchTask": "cmake-build-only",  // 关键修改
            "program": "${workspaceFolder}/build/ubuntu/applications/osgearth_viewer/osgearth_viewer",
            // ... 其他配置
        }
    ]
}
```

#### **效果**：
- 按 `F5` → 仅运行 `cmake-build-only` → 快速增量编译  
- 避免不必要的全量编译

---

### **5. 各 Task 的作用总结**
| Task 名称            | 命令                                      | 用途                          | 建议调用方式               |
|-----------------------|------------------------------------------|-----------------------------|--------------------------|
| `cmake-configure`     | 运行配置脚本                              | **首次配置**时手动运行        | 手动执行（仅需一次）       |
| `cmake-build`         | `cmake --build build/ubuntu`             | 全量编译所有目标              | 手动执行（需全量编译时）   |
| `cmake-build-only`    | `cmake --build build/ubuntu --target XX` | 增量编译单个目标（调试用）      | 设为 `preLaunchTask`      |

---

### **6. 完整调试流程示例**
#### **首次配置**
1. 手动运行 `cmake-configure`（通过命令面板或终端）
2. 确保生成 `build/ubuntu/CMakeCache.txt`

#### **日常调试**
1. 按 `F5`  
   → 自动触发 `cmake-build-only`（仅编译 `osgearth_viewer`）  
   → 启动调试器

#### **全量编译（可选）**
- 手动运行 `cmake-build` 任务

---

### **7. 常见问题**
#### **问题**：按 `F5` 仍然全量编译  
**原因**：`launch.json` 未设置 `preLaunchTask`，且 `cmake-build` 是默认任务。  
**修复**：  
```json
// .vscode/launch.json
"preLaunchTask": "cmake-build-only"
```

#### **问题**：`cmake-build-only` 找不到目标  
**原因**：`--target` 名称错误。  
**修复**：  
```bash
# 查看可编译目标列表
cmake --build build/ubuntu --target help
```

---

### **总结**
- **默认行为**：按 `F5` 会运行 `cmake-build`（全量编译）  
- **优化方案**：在 `launch.json` 中设置 `"preLaunchTask": "cmake-build-only"`  
- **验证方法**：观察输出面板或检查 `launch.json` 配置  

如果需要进一步调试，可以提供您的 `launch.json` 内容，我会帮您检查具体配置！ 🛠️