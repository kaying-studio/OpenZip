# OpenZip

**English** | [简体中文](./README.md)

A multi-platform compression and extraction app built with **Flutter**. It provides a menu bar, icon toolbar, favorites sidebar, file list with preview panel, and covers core flows such as create archive, extract, test, repair, and right-click shortcuts.

![version](https://img.shields.io/badge/version-0.1.0-blue)
![platform](https://img.shields.io/badge/platform-Windows%20%7C%20macOS%20%7C%20Linux%20%7C%20Web-lightgrey)
![license](https://img.shields.io/badge/license-Apache%202.0-green)

## Features

- Browse disk folders and archive contents
- **ZIP / TAR / TAR.GZ** (built-in read/write), **7Z / RAR** (via system extractors)
- Create archives: format, compression level, password, volumes
- Extract to folder / current directory / named subfolder
- Context menu: add to `xxx.zip`, extract here, test, repair, rename, properties
- File list: sorting, multi-select, preview (images / text)
- Favorites: Desktop, Downloads, Documents, Pictures, Music, Videos, and more

## UI Layout

| Area | Description |
|------|-------------|
| Menu bar | File / Edit / View / Favorites / Tools / Help |
| Toolbar | New, Open, Extract, Add, Delete, Test, Comment, Find |
| Navigation | Back, Forward, Up, breadcrumb address bar, Refresh |
| Sidebar | Favorites, recent archives, folder tree |
| List | Name / Size / Type / Modified / Compressed / Ratio / CRC / Path / Attr |
| Preview | File info, image & text preview (toggle in View) |
| Status bar | Status, selection stats, format |

## Getting Started

```bash
flutter pub get

# Run
flutter run -d macos     # or windows / linux / chrome

# Release builds
flutter build macos
flutter build windows
flutter build linux
flutter build web
```

## Development

```bash
flutter analyze
flutter test
```

## CI / Release

GitHub Actions workflows are included:

| Workflow | Trigger | Description |
|----------|---------|-------------|
| `ci.yml` | push / PR | Analyze, test, build Windows / macOS / Linux / Web |
| `release.yml` | `v*` tags | Multi-platform build and GitHub Release upload |

Release example:

```bash
git tag v0.1.0
git push origin v0.1.0
```

## Platforms

| Platform | Artifact |
|----------|----------|
| Windows | `OpenZip-x64.zip` |
| macOS | `OpenZip-universal.zip` |
| Linux | `OpenZip-linux-x64.tar.gz` |
| Web | `OpenZip-web.tar.gz` |

> On macOS, allow the app under System Settings → Privacy & Security if Gatekeeper blocks it. Access to Downloads/Documents may require a one-time permission.

## About

- **Version**: 0.1.0
- **Author**: [kayingai.com](https://kayingai.com)
- **Contact**: service@kayingai.com

## License

Licensed under the [Apache License 2.0](./LICENSE).

```
Copyright 2026 kayingai.com
```
