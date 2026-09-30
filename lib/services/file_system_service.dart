import 'dart:io';

import 'package:flutter/material.dart';

import '../models/archive_entry.dart';

/// 磁盘目录浏览与系统路径解析。
class FileSystemService {
  /// 真实用户主目录（绕过 macOS App 沙箱容器路径）。
  String get homePath {
    final envHome = Platform.environment['HOME'] ?? '';
    final user = Platform.environment['USER'] ?? '';
    final real = user.isEmpty ? '' : '/Users/$user';
    // 沙箱容器会把 HOME 指到 .../Containers/<id>/Data
    if (envHome.contains('Library/Containers') || envHome.contains('AppData/Local')) {
      if (real.isNotEmpty && Directory(real).existsSync()) return real;
    }
    if (envHome.isNotEmpty && Directory(envHome).existsSync()) return envHome;
    if (real.isNotEmpty && Directory(real).existsSync()) return real;
    return Directory.current.path;
  }

  String _userDir(String name, {List<String> aliases = const []}) {
    final home = homePath;
    for (final n in [name, ...aliases]) {
      final d = Directory('$home/$n');
      if (d.existsSync()) return d.path;
    }
    return home;
  }

  String get desktopPath => _userDir('Desktop', aliases: ['桌面']);
  String get downloadsPath => _userDir('Downloads', aliases: ['下载']);
  String get documentsPath => _userDir('Documents', aliases: ['文档', 'My Documents']);
  String get picturesPath =>
      _userDir('Pictures', aliases: ['图片', 'Photos', '相册']);
  String get musicPath => _userDir('Music', aliases: ['音乐', 'iTunes']);
  String get videosPath =>
      _userDir('Movies', aliases: ['Videos', '视频', '电影']);
  String get applicationsPath => _userDir('Applications');
  String get homeOrDesktop =>
      Directory(desktopPath).existsSync() ? desktopPath : homePath;

  /// 列出目录；失败时抛出 [FileSystemException]，便于界面提示权限问题。
  List<ArchiveEntry> listDirectory(String path, {bool showHidden = false}) {
    final dir = Directory(path);
    if (!dir.existsSync()) {
      throw FileSystemException('目录不存在', path);
    }
    final entries = <ArchiveEntry>[];
    try {
      final entities = dir.listSync(followLinks: false);
      for (final entity in entities) {
        final name = entity.path.split(RegExp(r'[/\\]')).last;
        if (!showHidden && name.startsWith('.')) continue;
        if (entity is File) {
          FileStat? stat;
          try {
            stat = entity.statSync();
          } catch (_) {}
          entries.add(ArchiveEntry(
            name: name,
            fullPath: entity.path,
            size: stat?.size ?? entity.lengthSync(),
            modified: stat?.modified,
            isDir: false,
          ));
        } else if (entity is Directory) {
          FileStat? stat;
          try {
            stat = entity.statSync();
          } catch (_) {}
          entries.add(ArchiveEntry(
            name: name,
            fullPath: entity.path,
            size: 0,
            modified: stat?.modified,
            isDir: true,
          ));
        }
      }
    } on FileSystemException {
      // 重新抛出，让 UI 显示「无权限」而不是假装空目录
      rethrow;
    } catch (e) {
      throw FileSystemException('无法读取目录: $e', path);
    }
    entries.sort((a, b) {
      if (a.isFolder != b.isFolder) return a.isFolder ? -1 : 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return entries;
  }

  /// 是否可读取该目录。
  bool canList(String path) {
    try {
      Directory(path).listSync(followLinks: false);
      return true;
    } catch (_) {
      return false;
    }
  }

  List<ArchiveEntry> listDriveRoots() {
    final result = <ArchiveEntry>[];
    if (Platform.isWindows) {
      for (var i = 0; i < 26; i++) {
        final letter = String.fromCharCode(65 + i);
        final drive = Directory('$letter:\\');
        if (drive.existsSync()) {
          result.add(ArchiveEntry(
            name: '$letter:\\',
            fullPath: drive.path,
            isDir: true,
          ));
        }
      }
    } else {
      for (final p in ['/', '/Users', '/Applications', '/Volumes', '/tmp', '/opt']) {
        if (Directory(p).existsSync()) {
          result.add(ArchiveEntry(
            name: p == '/' ? '磁盘 /' : p.split('/').last,
            fullPath: p,
            isDir: true,
          ));
        }
      }
    }
    return result;
  }

  List<BookmarkItem> defaultBookmarks() {
    return [
      BookmarkItem(title: '桌面', icon: Icons.desktop_windows_outlined, path: desktopPath),
      BookmarkItem(title: '下载', icon: Icons.download_rounded, path: downloadsPath),
      BookmarkItem(title: '文档', icon: Icons.description_outlined, path: documentsPath),
      BookmarkItem(title: '图片', icon: Icons.image_outlined, path: picturesPath),
      BookmarkItem(title: '音乐', icon: Icons.music_note_rounded, path: musicPath),
      BookmarkItem(title: '视频', icon: Icons.videocam_outlined, path: videosPath),
      BookmarkItem(title: '主目录', icon: Icons.home_outlined, path: homePath),
      BookmarkItem(
        title: '应用程序',
        icon: Icons.apps_rounded,
        path: applicationsPath,
      ),
    ];
  }

  /// 解压默认目录：压缩包旁同名文件夹。
  String defaultExtractDir(String archivePath) {
    final file = File(archivePath);
    final parent = file.parent.path;
    final name = archivePath.split(RegExp(r'[/\\]')).last;
    final base = name.replaceAll(RegExp(r'\.(zip|7z|rar|tar|tgz|gz)$', caseSensitive: false), '');
    final dest = Directory('$parent/$base');
    return dest.path;
  }

  /// 压缩默认输出目录。
  String defaultCompressDir() {
    if (Directory(downloadsPath).existsSync()) return downloadsPath;
    return homePath;
  }
}
