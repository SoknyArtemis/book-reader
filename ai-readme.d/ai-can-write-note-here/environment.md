# 开发环境要点（2026-10-13）

- 系统：openSUSE
- shell：fish（命令需兼容 fish，勿用 bash 专属写法）
- 包管理：优先 Linuxbrew（前缀 /home/linuxbrew/.linuxbrew）
- 网络：优先镜像源（PUB_HOSTED_URL=https://pub.flutter-io.cn，FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn）
- 桌面环境：KDE Plasma 6 / Wayland（XDG_SESSION_TYPE=wayland），勿默认 X11
