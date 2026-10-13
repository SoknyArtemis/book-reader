#!/usr/bin/env bash
# 快速启动 / 验证脚本
# 自动配置 brew(GTK 运行时) 与 Flutter 镜像所需环境变量，再运行本项目。
#
# 平台目录约定：
#   Flutter 要求 Linux 平台目录必须位于项目根且命名为 linux，
#   无法改路径。因此真实文件放在 platforms/gnu_linux，
#   本脚本在构建/运行前临时建软链（linux -> platforms/gnu_linux），
#   退出后删除，使根目录平时保持整洁。
#   注意：必须用本脚本跑；IDE 直接 flutter run 会因找不到根目录 linux/ 而失败。
#
# 渲染后端：
#   使用 Flutter 官方 GTK 嵌入器（platforms/gnu_linux）。观感由系统 KDE 的
#   GTK 主题设置决定，本脚本不做任何主题硬编码。
#
# 用法:
#   ./run.sh            # 构建并启动 GTK 版
#   ./run.sh build      # 仅构建
#   ./run.sh analyze    # flutter analyze
#
# 可用环境变量覆盖默认值:
#   BREW_PREFIX    brew 安装前缀（默认 /home/linuxbrew/.linuxbrew）
#   FLUTTER_BIN    fvm 所在 bin 目录（默认 $BREW_PREFIX/bin；Flutter 由 fvm 管理）
set -euo pipefail
shopt -s nullglob

# ---- 路径 ----
BREW_PREFIX="${BREW_PREFIX:-/home/linuxbrew/.linuxbrew}"
FLUTTER_BIN="${FLUTTER_BIN:-$BREW_PREFIX/bin}"

# ---- 环境变量 ----
export PATH="$FLUTTER_BIN:$PATH"
# 构建期依赖（GTK3 等）由系统 pkg-config 解析；不再前置 brew，
# 以免 brew 版 libgtk-3 被链入二进制、遮蔽系统 GTK 的 Breeze 主题。
export PKG_CONFIG_PATH="${PKG_CONFIG_PATH:-}"
export PUB_HOSTED_URL="${PUB_HOSTED_URL:-https://pub.flutter-io.cn}"
export FLUTTER_STORAGE_BASE_URL="${FLUTTER_STORAGE_BASE_URL:-https://storage.flutter-io.cn}"
# 启动期 GTK 运行时走系统库（已通过 GDK_BACKEND=wayland 走原生 Wayland 后端）
export DISPLAY="${DISPLAY:-:0}"

# 强制 GTK 走原生 Wayland 后端（本项目面向 KDE Plasma/Wayland），
# 以获得正确的 CSD 标题栏与 Breeze 主题集成；
# 否则在 XWayland/KWin 下会退化为老式标题栏（看着像 GTK2）。
# 若该环境变量已被显式设置则尊重其值，便于在纯 X11 环境下临时覆盖。
export GDK_BACKEND="${GDK_BACKEND:-wayland}"

# 切到脚本所在目录（项目根），兼容任意调用路径
cd "$(dirname "$0")"

# ---- 平台软链：构建前建、退出时删（保持根目录整洁）----
ensure_platform_links() {
  for d in platforms/*/; do
    local name link
    name="$(basename "$d")"
    link="$name"
    [ "$name" = "gnu_linux" ] && link="linux"
    [ -L "$link" ] || ln -sf "platforms/$name" "$link"
  done
}
cleanup_platform_links() {
  for link in linux android web windows; do
    [ -L "$link" ] && rm -f "$link"
  done
}
trap cleanup_platform_links EXIT
ensure_platform_links

# ---- 构建 / 运行 ----
BUNDLE="build/linux/x64/release/bundle"
EXE="$BUNDLE/book_reader"

cmd="${1:-run}"

case "$cmd" in
  analyze)
    fvm flutter --no-version-check analyze
    ;;
  build)
    fvm flutter --no-version-check build linux
    ;;
  run|*)
    fvm flutter --no-version-check build linux
    "$EXE"
    ;;
esac
