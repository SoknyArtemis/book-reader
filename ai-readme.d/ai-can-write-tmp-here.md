# 临时文件

## 10-13-26-08:15 桌面嵌入方案：采用官方 GTK，放弃自建 Qt
- 用户最初要 Qt（KDE 观感 + 跨平台一致性）。调查：官方预编译 libflutter_linux_gtk.so
  不导出原始 embedder C API（FlutterEngineInitialize 等动态符号为 0），自建 Qt 嵌入器无法链接官方引擎。
- 真·Qt 两条路代价都大：
  1) gn/ninja 自编译导出 C API 的引擎：30–50GB，需连通 chromium.googlesource.com，
     本机盘仅剩 6.8GB 且网络不通；
  2) flutter-elinux 预编译（Sony fork）：EGL 后端 + 版本漂移 + 插件适配。
- 决策：放弃 Qt，回退 Flutter 官方 GTK 嵌入器（platforms/gnu_linux）。
  已清理 platforms/qt_embedder/ 与失效软链；run.sh 改回纯 GTK，已验证可构建 book_reader。
- 注意：
  - GTK 套 KDE 主题不要硬编码 GTK_THEME，让系统 Breeze 自动生效；
  - 当前环境是 KDE Plasma 6 / Wayland（XDG_SESSION_TYPE=wayland），勿默认 X11；
  - 拿不定技术栈先讨论再写（见 ai-readme）；shell 命令需兼容 fish；注释要详细。
- 后续若再谈桌面嵌入：默认 GTK；仅当用户显式要求并接受“引擎自编译 / flutter-elinux fork”代价时才考虑 Qt。
