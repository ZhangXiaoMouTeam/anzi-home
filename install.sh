#!/bin/bash
# 一键安装 / 更新「ANZI 商品图」。
#
#   curl -fsSL https://raw.githubusercontent.com/ZhangXiaoMouTeam/anzi-home/main/install.sh | bash
#
# 安装包用的是本项目自己的证书，不是 Apple 签发的，所以用浏览器下载 dmg 双击安装后，
# 首次打开会被系统拦下、要右键才能开。这个脚本用 curl 下载（不会被打上隔离标记），
# 装完直接能用。
#
# 跳过了系统那层检查，就得自己把检查补回来。装之前核两样东西，任一不符立即中止：
#   1. 下载文件的 sha512 与官方发布清单一致（内容没被换过）
#   2. 应用签名的证书指纹与本项目一致（确实是本项目发布的）
set -euo pipefail

REPO="ZhangXiaoMouTeam/anzi-home"
APP_NAME="ANZI 商品图.app"
# 本项目代码签名证书的 SHA-1 指纹。
FINGERPRINT="399b3f59103b6fd4826da59efa5a1562e0218ebe"

if [ "$(uname -s)" != "Darwin" ] || [ "$(uname -m)" != "arm64" ]; then
  echo "这个软件目前只支持 Apple 芯片的 Mac。" >&2
  exit 1
fi

INSTALL_DIR="${ANZI_INSTALL_DIR:-/Applications}"
if [ ! -w "${INSTALL_DIR}" ]; then
  INSTALL_DIR="${HOME}/Applications"
  mkdir -p "${INSTALL_DIR}"
  echo "没有写入 /Applications 的权限，改装到 ${INSTALL_DIR}。"
fi

WORKDIR="$(mktemp -d)"
trap 'rm -rf "${WORKDIR}"' EXIT

echo "正在查询最新版本…"
# 先走 /latest/download（不限流）。这个跳转偶尔会短暂缓存在已删除的版本上，
# 取不到就改问 API 拿准确的 tag 再取一次。
if ! curl -fsSL "https://github.com/${REPO}/releases/latest/download/latest-mac.yml" \
  -o "${WORKDIR}/latest-mac.yml" 2>/dev/null; then
  TAG="$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" \
    | awk -F'"' '/"tag_name"/ {print $4; exit}')"
  if [ -z "${TAG}" ] || ! curl -fsSL \
    "https://github.com/${REPO}/releases/download/${TAG}/latest-mac.yml" \
    -o "${WORKDIR}/latest-mac.yml"; then
    echo "取不到发布清单，检查一下网络。" >&2
    exit 1
  fi
fi

VERSION="$(awk '/^version:/ {print $2; exit}' "${WORKDIR}/latest-mac.yml")"
ZIP_NAME="$(awk '/^path:/ {print $2; exit}' "${WORKDIR}/latest-mac.yml")"
EXPECTED_SHA="$(awk '/^sha512:/ {print $2; exit}' "${WORKDIR}/latest-mac.yml")"
if [ -z "${VERSION}" ] || [ -z "${ZIP_NAME}" ] || [ -z "${EXPECTED_SHA}" ]; then
  echo "发布清单格式不对，装不了。" >&2
  exit 1
fi

CURRENT=""
if [ -d "${INSTALL_DIR}/${APP_NAME}" ]; then
  CURRENT="$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" \
    "${INSTALL_DIR}/${APP_NAME}/Contents/Info.plist" 2>/dev/null || true)"
fi
if [ -n "${CURRENT}" ] && [ "${CURRENT}" = "${VERSION}" ]; then
  echo "已经是最新版 v${VERSION}，无需安装。"
  exit 0
fi
echo "最新版 v${VERSION}${CURRENT:+（当前 v${CURRENT}）}，开始下载…"

curl -fL --progress-bar \
  "https://github.com/${REPO}/releases/download/v${VERSION}/${ZIP_NAME}" \
  -o "${WORKDIR}/${ZIP_NAME}"

echo "校验下载内容…"
ACTUAL_SHA="$(shasum -a 512 "${WORKDIR}/${ZIP_NAME}" | awk '{print $1}' | xxd -r -p | base64)"
if [ "${ACTUAL_SHA}" != "${EXPECTED_SHA}" ]; then
  echo "下载的文件和发布清单对不上，已中止安装。多半是下载不完整，重跑一次。" >&2
  exit 1
fi

ditto -x -k "${WORKDIR}/${ZIP_NAME}" "${WORKDIR}/unpacked"
NEW_APP="${WORKDIR}/unpacked/${APP_NAME}"
[ -d "${NEW_APP}" ] || NEW_APP="$(find "${WORKDIR}/unpacked" -maxdepth 1 -name '*.app' | head -1)"
if [ ! -d "${NEW_APP}" ]; then
  echo "压缩包里没找到应用，已中止。" >&2
  exit 1
fi

echo "校验签名…"
if ! codesign --verify --strict "${NEW_APP}" 2>/dev/null; then
  echo "应用签名不完整，已中止安装。" >&2
  exit 1
fi
SIGNED_BY="$(codesign -d -r- "${NEW_APP}" 2>/dev/null | grep -o 'H"[0-9a-fA-F]*"' | tr -d 'H"' | tr 'A-Z' 'a-z')"
if [ "${SIGNED_BY}" != "${FINGERPRINT}" ]; then
  echo "签名证书不是本项目的，已中止安装。" >&2
  echo "  期望 ${FINGERPRINT}" >&2
  echo "  实际 ${SIGNED_BY:-（未签名）}" >&2
  exit 1
fi

if pgrep -f "${INSTALL_DIR}/${APP_NAME}" >/dev/null 2>&1; then
  echo "正在退出运行中的旧版本…"
  osascript -e 'quit app "ANZI 商品图"' 2>/dev/null || true
  sleep 2
fi

echo "安装到 ${INSTALL_DIR}…"
rm -rf "${INSTALL_DIR:?}/${APP_NAME}"
ditto "${NEW_APP}" "${INSTALL_DIR}/${APP_NAME}"
# macOS 自带的 xattr 没有 -r，用 find 批量清掉可能残留的隔离标记。
find "${INSTALL_DIR}/${APP_NAME}" -exec xattr -d com.apple.quarantine {} + 2>/dev/null || true

echo
echo "装好了：v${VERSION}"
echo "以后有新版，软件会自己提示并安装，不用再跑这个命令。"
# 装到自定义目录时多半是在做验证，不自动打开：那个目录随时可能被清掉，
# 应用启动到一半文件没了会直接崩。
if [ -z "${ANZI_INSTALL_DIR:-}" ]; then
  open "${INSTALL_DIR}/${APP_NAME}" 2>/dev/null || true
fi
