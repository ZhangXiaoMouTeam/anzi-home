# ANZI 商品图

**官网：<https://zhangxiaomouteam.github.io/anzi-home/>**

导入一个款号的拍摄目录，本机识别尺码与面料，自动排出全套主图和详情页。
macOS · Apple 芯片与 Intel；Windows 10/11 · x64。本仓库只分发安装包和官网页面，源码在私有仓库。

## Mac 安装

```bash
curl -fsSL https://raw.githubusercontent.com/ZhangXiaoMouTeam/anzi-home/main/install.sh | bash
```

Apple 芯片和 Intel 都会自动装对应版本，装完会自动打开。之后有新版本，软件会自己在后台下好并提示重启安装，不用再跑这个命令。

安装脚本在装之前会核两样东西，任一不符立即中止：

- 下载文件的 sha512 与发布清单 `latest-mac.yml` 一致
- 应用签名的证书指纹与本项目一致（`399b3f59103b6fd4826da59efa5a1562e0218ebe`）

## 手动下载

到 [Releases](https://github.com/ZhangXiaoMouTeam/anzi-home/releases/latest) 下载 dmg：
Apple 芯片选 `-arm64.dmg`，Intel 选 `-x64.dmg`。

Windows 请选择 `-windows-x64.exe` 安装包，或 `-windows-x64.zip` 免安装包。Windows 暂不自动安装更新，请下载新版覆盖安装；本地工作区数据保留。安装包尚未配置 Authenticode 签名，系统可能提示未知发布者，请核对下载来源及发布页的 `SHA256SUMS.txt`。

用浏览器下载的话，**首次打开需要右键点应用图标 → 打开**。安装包用的是本项目自己的
证书而不是 Apple 签发的，系统会先拦一次；上面那行安装命令不会有这个问题。

## 使用前准备

AI 识别和生图需要安装并登录 Codex CLI。所选商品图片会按任务发送给 AI 服务；识别不可用时，本地 OCR 补充缺失信息。Windows 包内已包含离线 OCR、视觉模型和中文字体，不需要另装 Node.js。

## 版本说明

v2026.8.4 起支持自动升级。更早的版本（v2026.8.3 及以前）需要手动装一次新版，
之后才会自动更新。
