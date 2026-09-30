import 'package:flutter/material.dart';

enum FileGlyphKind {
  folder,
  archive,
  image,
  video,
  audio,
  code,
  doc,
  app,
  file,
}

/// 压缩包 / 文件夹 内的条目。
class ArchiveEntry {
  ArchiveEntry({
    required this.name,
    required this.fullPath,
    this.size = 0,
    this.compressedSize,
    this.modified,
    this.crc32,
    this.isDir = false,
    this.isDirectory = false,
    this.encrypted = false,
    this.method,
  });

  final String name;

  /// 压缩包内相对路径或磁盘绝对路径。
  final String fullPath;
  final int size;
  final int? compressedSize;
  final DateTime? modified;
  final int? crc32;
  final bool isDir;
  final bool isDirectory;
  final bool encrypted;
  final String? method;

  bool get isFolder => isDir || isDirectory;

  double get compressionRate {
    final c = compressedSize;
    if (!isFolder && c != null && size > 0) {
      return (1 - c / size) * 100;
    }
    return 0;
  }

  String get ext {
    final dot = name.lastIndexOf('.');
    if (dot <= 0 || dot == name.length - 1) return '';
    return name.substring(dot + 1).toLowerCase();
  }

  /// 与工具栏一致的文件图标类型。
  FileGlyphKind get glyphKind {
    if (isFolder) return FileGlyphKind.folder;
    switch (ext) {
      case 'zip':
      case '7z':
      case 'rar':
      case 'tar':
      case 'gz':
      case 'tgz':
      case 'bz2':
      case 'xz':
      case 'iso':
        return FileGlyphKind.archive;
      case 'exe':
      case 'msi':
      case 'dmg':
      case 'app':
        return FileGlyphKind.app;
      case 'txt':
      case 'md':
      case 'log':
      case 'pdf':
      case 'doc':
      case 'docx':
      case 'xls':
      case 'xlsx':
      case 'csv':
      case 'ppt':
      case 'pptx':
        return FileGlyphKind.doc;
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'gif':
      case 'bmp':
      case 'webp':
      case 'svg':
        return FileGlyphKind.image;
      case 'mp3':
      case 'wav':
      case 'flac':
      case 'aac':
      case 'm4a':
        return FileGlyphKind.audio;
      case 'mp4':
      case 'mov':
      case 'avi':
      case 'mkv':
      case 'webm':
        return FileGlyphKind.video;
      case 'dart':
      case 'js':
      case 'ts':
      case 'py':
      case 'java':
      case 'cpp':
      case 'c':
      case 'h':
      case 'cs':
      case 'go':
      case 'rs':
      case 'html':
      case 'css':
      case 'json':
      case 'xml':
      case 'yaml':
      case 'yml':
      case 'sql':
      case 'sh':
      case 'bat':
        return FileGlyphKind.code;
      default:
        return FileGlyphKind.file;
    }
  }

  IconData get icon {
    switch (glyphKind) {
      case FileGlyphKind.folder:
        return Icons.folder_rounded;
      case FileGlyphKind.archive:
        return Icons.archive_rounded;
      case FileGlyphKind.image:
        return Icons.image_rounded;
      case FileGlyphKind.video:
        return Icons.movie_rounded;
      case FileGlyphKind.audio:
        return Icons.music_note_rounded;
      case FileGlyphKind.code:
        return Icons.code_rounded;
      case FileGlyphKind.doc:
        return Icons.description_rounded;
      case FileGlyphKind.app:
        return Icons.apps_rounded;
      case FileGlyphKind.file:
        return Icons.insert_drive_file_rounded;
    }
  }

  Color get iconColor {
    switch (glyphKind) {
      case FileGlyphKind.folder:
        return const Color(0xFFF5B942);
      case FileGlyphKind.archive:
        return const Color(0xFF0084FF); // 知乎蓝
      case FileGlyphKind.image:
        return const Color(0xFF00A870);
      case FileGlyphKind.video:
        return const Color(0xFFE5484D);
      case FileGlyphKind.audio:
        return const Color(0xFFF5A623);
      case FileGlyphKind.code:
        return const Color(0xFF0099CC);
      case FileGlyphKind.doc:
        return const Color(0xFF0084FF);
      case FileGlyphKind.app:
        return const Color(0xFF6B7280);
      case FileGlyphKind.file:
        return const Color(0xFF6B7280);
    }
  }

  ArchiveEntry copyWith({
    String? name,
    String? fullPath,
    int? size,
    int? compressedSize,
    DateTime? modified,
    int? crc32,
    bool? isDir,
    bool? encrypted,
    String? method,
  }) {
    return ArchiveEntry(
      name: name ?? this.name,
      fullPath: fullPath ?? this.fullPath,
      size: size ?? this.size,
      compressedSize: compressedSize ?? this.compressedSize,
      modified: modified ?? this.modified,
      crc32: crc32 ?? this.crc32,
      isDir: isDir ?? this.isDir,
      encrypted: encrypted ?? this.encrypted,
      method: method ?? this.method,
    );
  }
}

enum SortColumn { name, size, type, modified, compressed, rate, crc, path, attr }

enum SortOrder { asc, desc }

class VolumeInfo {
  VolumeInfo({
    required this.path,
    required this.name,
    required this.format,
    required this.entries,
    this.password,
  });

  final String path;
  final String name;
  final String format;
  final List<ArchiveEntry> entries;
  final String? password;

  bool get isArchive => true;
}

/// 侧栏收藏夹节点。
class BookmarkItem {
  const BookmarkItem({
    required this.title,
    required this.icon,
    required this.path,
    this.isArchiveNode = false,
  });

  final String title;
  final IconData icon;
  final String path;
  final bool isArchiveNode;
}
