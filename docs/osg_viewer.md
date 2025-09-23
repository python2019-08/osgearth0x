# 1.请解释  XRANDR
OPTION(OSGVIEWER_USE_XRANDR "Set to ON to enable Xrandr support for GraphicsWindowX11." ON)
请解释  XRANDR

`XRANDR` 是 X11 显示系统中的一个重要扩展（全称 **X Resize and Rotate**），主要用于动态管理显示器的分辨率、刷新率、屏幕旋转以及多显示器配置。

简单来说，它允许用户或程序在运行时：
- 更改显示器的分辨率（如从 1920×1080 切换到 2560×1440）
- 调整屏幕刷新率（如从 60Hz 切换到 144Hz）
- 旋转屏幕（如竖屏显示）
- 配置多显示器布局（如扩展桌面、复制显示等）

在你提到的 CMake 选项 `OSGVIEWER_USE_XRANDR` 中：
- 当开启（`ON`）时，OSG 的 `GraphicsWindowX11` 会利用 XRANDR 扩展，使 OSG 程序能自动适应显示器的分辨率变化，或在多显示器环境下正确工作。
- 当关闭（`OFF`）时，OSG 将不使用 XRANDR，可能导致程序无法响应显示器配置变化，或在复杂显示环境下出现适配问题。

对于需要在 X11 环境下运行的 OSG 程序（尤其是需要支持多显示器或动态分辨率调整的场景），通常建议保持该选项为 `ON`，以获得更好的显示兼容性。