# OpenZip

[English](./README.en.md) | **简体中文**

基于 **Flutter** 的多平台压缩 / 解压缩软件。提供菜单栏、图标工具栏、收藏夹侧栏、文件列表与预览面板，覆盖新建压缩、解压、测试、修复、右键快捷操作等核心流程。

![version](https://img.shields.io/badge/version-0.1.0-blue)
![platform](https://img.shields.io/badge/platform-Windows%20%7C%20macOS%20%7C%20Linux%20%7C%20Web-lightgrey)
![license](https://img.shields.io/badge/license-Apache%202.0-green)

## 功能特性

- 浏览磁盘目录与压缩包内部结构
- 支持 **ZIP / TAR / TAR.GZ**（内置读写），**7Z / RAR**（借助系统解压器）
- 新建压缩：格式、压缩级别、密码、分卷
- 解压：指定目录 / 当前目录 / 命名子目录
- 右键快捷：添加到 `xxx.zip`、解压到当前、测试、修复、重命名、属性
- 文件列表：排序、多选、预览面板（图片 / 文本）
- 收藏夹：桌面、下载、文档、图片、音乐、视频等系统路径

## 界面结构

| 区域 | 说明 |
|------|------|
| 菜单栏 | 文件 / 编辑 / 视图 / 收藏 / 工具 / 帮助 |
| 工具栏 | 新建、打开、解压、添加、删除、测试、注释、查找 |
| 导航 | 后退、前进、向上、面包屑地址栏、刷新 |
| 左侧栏 | 收藏夹、最近打开、文件夹树 |
| 主列表 | 名称 / 大小 / 类型 / 修改时间 / 压缩后 / 压缩率 / CRC / 路径 / 属性 |
| 预览面板 | 文件信息、图片与文本预览（可在「视图」中开关） |
| 状态栏 | 状态、选中统计、格式 |

## 快速开始

```bash
flutter pub get

# 运行
flutter run -d macos     # 或 windows / linux / chrome

# 构建发布版
flutter build macos
flutter build windows
flutter build linux
flutter build web
```

## 开发

```bash
flutter analyze
flutter test
```

## CI / 发布

仓库内置 GitHub Actions：

| 工作流 | 触发 | 说明 |
|--------|------|------|
| `ci.yml` | push / PR | 分析、测试，构建 Windows / macOS / Linux / Web 产物 |
| `release.yml` | 推送 `v*` 标签 | 多平台构建并上传到 GitHub Release |

发布示例：

```bash
git tag v0.1.0
git push origin v0.1.0
```

## 平台说明

| 平台 | 产物 |
|------|------|
| Windows | `OpenZip-x64.zip` |
| macOS | `OpenZip-universal.zip` |
| Linux | `OpenZip-linux-x64.tar.gz` |
| Web | `OpenZip-web.tar.gz` |

> macOS 若提示无法验证开发者，请在「系统设置 → 隐私与安全性」中允许；访问「下载 / 文档」等目录时，系统可能要求授权。

## 关于

- **版本**：0.1.0
- **作者**：[kayingai.com](https://kayingai.com)
- **联系我们**：service@kayingai.com

## 开源协议

本项目采用 [Apache License 2.0](./LICENSE) 开源。

```
Copyright 2026 kayingai.com
```
