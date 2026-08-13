# ANZI 商品图

导入一个款号的拍摄目录，本机识别尺码与面料，自动排出全套主图和详情页。
macOS · Apple 芯片。本仓库只分发安装包，源码见私有仓库。

## 安装

```bash
curl -fsSL https://raw.githubusercontent.com/ZhangXiaoMouTeam/anzi-home/main/install.sh | bash
```

装完会自动打开。之后有新版本，软件会自己在后台下好并提示重启安装，不用再跑这个命令。

安装脚本在装之前会核两样东西，任一不符立即中止：

- 下载文件的 sha512 与发布清单 `latest-mac.yml` 一致
- 应用签名的证书指纹与本项目一致（`399b3f59103b6fd4826da59efa5a1562e0218ebe`）

## 手动下载

到 [Releases](https://github.com/ZhangXiaoMouTeam/anzi-home/releases/latest) 下载 dmg。

用浏览器下载的话，**首次打开需要右键点应用图标 → 打开**。安装包用的是本项目自己的
证书而不是 Apple 签发的，系统会先拦一次；上面那行安装命令不会有这个问题。

## 版本说明

v2026.8.4 起支持自动升级。更早的版本（v2026.8.3 及以前）需要手动装一次新版，
之后才会自动更新。
