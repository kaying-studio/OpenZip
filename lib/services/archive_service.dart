import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';

import '../models/archive_entry.dart';

enum ArchiveFormat { zip, tar, tarGz, sevenZip, rar, auto }

class ArchiveOpenResult {
  ArchiveOpenResult({
    required this.path,
    required this.format,
    required this.entries,
    this.comment = '',
    this.encrypted = false,
    this.rawArchive,
  });

  final String path;
  final ArchiveFormat format;
  final List<ArchiveEntry> entries;
  final String comment;
  final bool encrypted;

  /// 原始 Archive，解压时使用。
  final Archive? rawArchive;

  String get name => path.split(RegExp(r'[/\\]')).last;

  String get formatLabel {
    switch (format) {
      case ArchiveFormat.zip:
        return 'ZIP';
      case ArchiveFormat.tar:
        return 'TAR';
      case ArchiveFormat.tarGz:
        return 'TAR.GZ';
      case ArchiveFormat.sevenZip:
        return '7Z';
      case ArchiveFormat.rar:
        return 'RAR';
      case ArchiveFormat.auto:
        return '未知';
    }
  }
}

class CompressOptions {
  const CompressOptions({
    this.format = ArchiveFormat.zip,
    this.level = 6,
    this.password,
    this.splitVolumeSize = 0,
    this.includeBaseFolder = true,
    this.storeOnly = false,
  });

  final ArchiveFormat format;
  final int level;
  final String? password;
  final int splitVolumeSize;
  final bool includeBaseFolder;
  final bool storeOnly;
}

class ExtractOptions {
  const ExtractOptions({
    this.overwrite = true,
    this.keepFullPath = true,
  });

  final bool overwrite;
  final bool keepFullPath;
}

class ArchiveService {
  /// 支持的扩展名。
  static const supportedExtensions = {
    'zip',
    '7z',
    'rar',
    'tar',
    'gz',
    'tgz',
    'bz2',
    'xz',
  };

  static ArchiveFormat formatFromPath(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.zip')) return ArchiveFormat.zip;
    if (lower.endsWith('.tar')) return ArchiveFormat.tar;
    if (lower.endsWith('.tar.gz') || lower.endsWith('.tgz') || lower.endsWith('.gz')) {
      return ArchiveFormat.tarGz;
    }
    if (lower.endsWith('.7z')) return ArchiveFormat.sevenZip;
    if (lower.endsWith('.rar')) return ArchiveFormat.rar;
    return ArchiveFormat.auto;
  }

  static bool isArchivePath(String path) {
    final lower = path.toLowerCase();
    return supportedExtensions.any(lower.endsWith);
  }

  Future<ArchiveOpenResult> open(String path) async {
    final file = File(path);
    if (!file.existsSync()) {
      throw FileSystemException('文件不存在', path);
    }

    final format = formatFromPath(path);
    final bytes = await file.readAsBytes();

    switch (format) {
      case ArchiveFormat.zip:
        return _openZip(path, bytes);
      case ArchiveFormat.tar:
      case ArchiveFormat.tarGz:
        return _openTar(path, bytes, format);
      case ArchiveFormat.sevenZip:
        return _openSevenZip(path, bytes);
      case ArchiveFormat.rar:
        return _openRar(path, bytes);
      case ArchiveFormat.auto:
        // 启发式识别
        if (_looksLikeZip(bytes)) return _openZip(path, bytes);
        if (_looksLike7z(bytes)) return _openSevenZip(path, bytes);
        if (_looksLikeRar(bytes)) return _openRar(path, bytes);
        if (_looksLikeGzip(bytes)) return _openTar(path, bytes, ArchiveFormat.tarGz);
        if (_looksLikeTar(bytes)) return _openTar(path, bytes, ArchiveFormat.tar);
        throw UnsupportedError('不支持的压缩格式: $path');
    }
  }

  bool _looksLikeZip(Uint8List b) =>
      b.length > 4 && b[0] == 0x50 && b[1] == 0x4B;
  bool _looksLike7z(Uint8List b) =>
      b.length > 6 &&
      b[0] == 0x37 &&
      b[1] == 0x7A &&
      b[2] == 0xBC &&
      b[3] == 0xAF &&
      b[4] == 0x27 &&
      b[5] == 0x1C;
  bool _looksLikeRar(Uint8List b) =>
      b.length > 7 &&
      b[0] == 0x52 &&
      b[1] == 0x61 &&
      b[2] == 0x72 &&
      b[3] == 0x21;
  bool _looksLikeGzip(Uint8List b) => b.length > 2 && b[0] == 0x1F && b[1] == 0x8B;
  bool _looksLikeTar(Uint8List b) =>
      b.length > 262 && String.fromCharCodes(b.sublist(257, 262)) == 'ustar';

  ArchiveOpenResult _openZip(String path, Uint8List bytes) {
    final archive = ZipDecoder().decodeBytes(bytes, verify: true);
    final entries = archive.files.map(_entryFromFile).toList()
      ..sort((a, b) {
        if (a.isFolder != b.isFolder) return a.isFolder ? -1 : 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

    String comment = '';
    try {
      comment = archive.comment ?? '';
    } catch (_) {}

    return ArchiveOpenResult(
      path: path,
      format: ArchiveFormat.zip,
      entries: entries,
      comment: comment,
      rawArchive: archive,
    );
  }

  ArchiveOpenResult _openTar(String path, Uint8List bytes, ArchiveFormat format) {
    final Archive archive;
    if (format == ArchiveFormat.tarGz || path.toLowerCase().endsWith('.gz')) {
      archive = TarDecoder().decodeBytes(GZipDecoder().decodeBytes(bytes));
    } else {
      archive = TarDecoder().decodeBytes(bytes);
    }
    final entries = archive.files.map(_entryFromFile).toList()
      ..sort((a, b) {
        if (a.isFolder != b.isFolder) return a.isFolder ? -1 : 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    return ArchiveOpenResult(
      path: path,
      format: format,
      entries: entries,
      rawArchive: archive,
    );
  }

  /// 7z / rar：优先走系统解压器；失败则给出清晰错误。
  ArchiveOpenResult _openSevenZip(String path, Uint8List bytes) {
    final tool = _findSevenZipBinary();
    if (tool == null) {
      throw UnsupportedError(
        '未找到 7z 解压程序。请安装 p7zip/7-Zip，或改用 ZIP 格式。',
      );
    }
    return _openViaSystemTool(path, tool, ArchiveFormat.sevenZip);
  }

  ArchiveOpenResult _openRar(String path, Uint8List bytes) {
    final tool = _findRarBinary();
    if (tool == null) {
      throw UnsupportedError(
        '未找到 RAR 解压程序。请安装 unrar/7-Zip，或改用 ZIP 格式。',
      );
    }
    return _openViaSystemTool(path, tool, ArchiveFormat.rar);
  }

  ArchiveOpenResult _openViaSystemTool(String path, String tool, ArchiveFormat format) {
    // 列表解析：7z/unrar l
    final result = Process.runSync(
      tool,
      tool.contains('7z') || tool.endsWith('7zz') ? ['l', '-slt', path] : ['l', path],
    );
    if (result.exitCode != 0) {
      throw Exception('解析压缩包失败: ${result.stderr}');
    }
    final stdout = result.stdout.toString();
    final entries = _parseSevenZipList(stdout, fileName: path);
    return ArchiveOpenResult(
      path: path,
      format: format,
      entries: entries,
    );
  }

  List<ArchiveEntry> _parseSevenZipList(String output, {String fileName = ''}) {
    final entries = <ArchiveEntry>[];
    final blocks = output.split('\n\n');
    for (final block in blocks) {
      String? name;
      int size = 0;
      int? packed;
      bool isDir = false;
      DateTime? modified;
      for (final line in block.split('\n')) {
        if (line.startsWith('Path = ')) {
          name = line.substring(7).trim();
        } else if (line.startsWith('Size = ')) {
          size = int.tryParse(line.substring(7).trim()) ?? 0;
        } else if (line.startsWith('Packed Size = ')) {
          packed = int.tryParse(line.substring(14).trim());
        } else if (line.startsWith('Attributes = ')) {
          isDir = line.contains('D');
        } else if (line.startsWith('Modified = ')) {
          modified = DateTime.tryParse(line.substring(11).trim());
        } else if (line.startsWith('Folder = ')) {
          isDir = line.substring(9).trim().contains('+');
        }
      }
      if (name == null || name == fileName || name.isEmpty) continue;
      final leaf = name.split(RegExp(r'[/\\]')).last;
      if (leaf.isEmpty) isDir = true;
      entries.add(
        ArchiveEntry(
          name: leaf,
          fullPath: name,
          size: size,
          compressedSize: packed,
          modified: modified,
          isDir: isDir,
        ),
      );
    }
    entries.sort((a, b) {
      if (a.isFolder != b.isFolder) return a.isFolder ? -1 : 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return entries;
  }

  String? _findSevenZipBinary() {
    const candidates = ['7z', '7zz', '7za', '/usr/local/bin/7z', '/opt/homebrew/bin/7z', '/usr/bin/7z'];
    for (final c in candidates) {
      try {
        final r = Process.runSync('which', [c]);
        if (r.exitCode == 0 && r.stdout.toString().trim().isNotEmpty) {
          return r.stdout.toString().trim();
        }
      } catch (_) {}
      if (File(c).existsSync()) return c;
    }
    return null;
  }

  String? _findRarBinary() {
    const candidates = ['unrar', 'rar', '/usr/local/bin/unrar', '/opt/homebrew/bin/unrar'];
    for (final c in candidates) {
      try {
        final r = Process.runSync('which', [c]);
        if (r.exitCode == 0 && r.stdout.toString().trim().isNotEmpty) {
          return r.stdout.toString().trim();
        }
      } catch (_) {}
      if (File(c).existsSync()) return c;
    }
    return _findSevenZipBinary();
  }

  ArchiveEntry _entryFromFile(ArchiveFile file) {
    final name = file.name.replaceAll('\\', '/');
    final isDir = !file.isFile || name.endsWith('/');
    final leaf = name.endsWith('/')
        ? name.substring(0, name.length - 1).split('/').last
        : name.split('/').last;
    int? compressed;
    try {
      final dynamic d = file;
      final c = d.compressedSize as int?;
      compressed = c;
    } catch (_) {
      compressed = null;
    }
    return ArchiveEntry(
      name: leaf.isEmpty ? name : leaf,
      fullPath: name,
      size: file.size,
      compressedSize: compressed ?? file.size,
      isDir: isDir,
      modified: file.lastModTime > 0
          ? DateTime.fromMillisecondsSinceEpoch(file.lastModTime * 1000)
          : null,
      crc32: file.crc32,
    );
  }

  /// 解压整个包或指定条目。
  Future<void> extract({
    required String archivePath,
    required String destDir,
    List<String>? entryPaths,
    ExtractOptions options = const ExtractOptions(),
    void Function(double progress, String current)? onProgress,
  }) async {
    final dest = Directory(destDir);
    if (!dest.existsSync()) dest.createSync(recursive: true);

    final format = formatFromPath(archivePath);

    // 7z / rar 走系统工具
    if (format == ArchiveFormat.sevenZip) {
      final tool = _findSevenZipBinary();
      if (tool == null) throw UnsupportedError('需要 7z 才能解压 7Z 格式');
      await _extractViaTool(tool, archivePath, destDir, entryPaths, onProgress);
      return;
    }
    if (format == ArchiveFormat.rar) {
      final tool = _findRarBinary();
      if (tool == null) throw UnsupportedError('需要 unrar/7z 才能解压 RAR 格式');
      await _extractViaTool(tool, archivePath, destDir, entryPaths, onProgress);
      return;
    }

    final result = await open(archivePath);
    final archive = result.rawArchive!;
    final files = archive.files.where((f) {
      if (entryPaths == null || entryPaths.isEmpty) return true;
      return entryPaths.contains(f.name.replaceAll('\\', '/'));
    }).toList();

    var done = 0;
    for (final file in files) {
      final name = file.name.replaceAll('\\', '/');
      if (file.isFile) {
        final target = options.keepFullPath
            ? '$destDir/${_normalizeRel(name)}'
            : '$destDir/${name.split('/').last}';
        final targetFile = File(target);
        if (!targetFile.parent.existsSync()) {
          targetFile.parent.createSync(recursive: true);
        }
        if (targetFile.existsSync() && !options.overwrite) {
          done++;
          onProgress?.call(done / files.length, name);
          continue;
        }
        final content = file.readBytes() ?? Uint8List(0);
        await targetFile.writeAsBytes(content, flush: true);
      } else {
        final dir = Directory('$destDir/${_normalizeRel(name)}');
        if (!dir.existsSync()) dir.createSync(recursive: true);
      }
      done++;
      onProgress?.call(done / files.length, name);
    }
  }

  String _normalizeRel(String name) {
    var n = name.replaceAll('\\', '/');
    while (n.startsWith('/')) {
      n = n.substring(1);
    }
    // 防目录穿越
    if (n.contains('../')) {
      n = n.replaceAll('../', '');
    }
    return n;
  }

  Future<void> _extractViaTool(
    String tool,
    String archivePath,
    String destDir,
    List<String>? entryPaths,
    void Function(double, String)? onProgress,
  ) async {
    onProgress?.call(0.05, '准备解压...');
    final args = tool.contains('7z') || tool.endsWith('7zz')
        ? [
            'x',
            archivePath,
            '-o$destDir',
            '-y',
            if (entryPaths != null && entryPaths.isNotEmpty) ...entryPaths,
          ]
        : [
            'x',
            '-o+',
            archivePath,
            '$destDir${Platform.pathSeparator}',
            if (entryPaths != null && entryPaths.isNotEmpty) ...entryPaths,
          ];
    final result = await Process.run(tool, args);
    if (result.exitCode != 0) {
      throw Exception('解压失败: ${result.stderr}');
    }
    onProgress?.call(1, '完成');
  }

  /// 压缩文件/文件夹到 zip（纯 Dart，跨平台）。
  Future<void> compress({
    required List<String> sourcePaths,
    required String outputPath,
    CompressOptions options = const CompressOptions(),
    void Function(double progress, String current)? onProgress,
  }) async {
    final format = options.format == ArchiveFormat.auto
        ? formatFromPath(outputPath)
        : options.format;

    if (format == ArchiveFormat.sevenZip) {
      await _compressVia7z(sourcePaths, outputPath, options, onProgress);
      return;
    }

    final archive = Archive();
    var totalWeight = 0;
    for (final p in sourcePaths) {
      final type = FileSystemEntity.typeSync(p);
      if (type == FileSystemEntityType.file) {
        totalWeight += File(p).lengthSync();
      } else if (type == FileSystemEntityType.directory) {
        totalWeight += _dirSize(Directory(p));
      }
    }
    if (totalWeight == 0) totalWeight = 1;

    var processed = 0;
    for (final p in sourcePaths) {
      final type = FileSystemEntity.typeSync(p);
      final name = p.split(RegExp(r'[/\\]')).last;
      if (type == FileSystemEntityType.file) {
        final file = File(p);
        final bytes = file.readAsBytesSync();
        processed += bytes.length;
        onProgress?.call(
          (processed / totalWeight * 0.7).clamp(0, 1).toDouble(),
          name,
        );
        archive.addFile(ArchiveFile(
          options.includeBaseFolder ? name : name,
          bytes.length,
          bytes,
        ));
      } else if (type == FileSystemEntityType.directory) {
        await _addDirectory(
          archive,
          Directory(p),
          options.includeBaseFolder ? name : '',
          (doneName, weight) {
            processed += weight;
            onProgress?.call(
              (processed / totalWeight * 0.7).clamp(0, 1).toDouble(),
              doneName,
            );
          },
        );
      }
    }

    onProgress?.call(0.75, '正在编码...');

    List<int> encoded;
    if (format == ArchiveFormat.zip) {
      encoded = ZipEncoder().encode(archive);
    } else if (format == ArchiveFormat.tar) {
      encoded = TarEncoder().encode(archive);
    } else if (format == ArchiveFormat.tarGz) {
      final tar = TarEncoder().encode(archive);
      encoded = GZipEncoder().encode(tar);
    } else {
      encoded = ZipEncoder().encode(archive);
    }

    onProgress?.call(0.9, '正在写入...');
    await File(outputPath).writeAsBytes(encoded, flush: true);
    onProgress?.call(1, '完成');
  }

  Future<void> _compressVia7z(
    List<String> sourcePaths,
    String outputPath,
    CompressOptions options,
    void Function(double, String)? onProgress,
  ) async {
    final tool = _findSevenZipBinary();
    if (tool == null) throw UnsupportedError('需要安装 7z 才能创建 7Z 格式');
    onProgress?.call(0.1, '调用 7z...');
    final level = (options.storeOnly ? 0 : options.level).clamp(0, 9);
    final args = <String>[
      'a',
      '-t7z',
      '-mx=$level',
      if (options.password != null && options.password!.isNotEmpty)
        '-p${options.password}',
      outputPath,
      ...sourcePaths,
    ];
    final result = await Process.run(tool, args);
    if (result.exitCode != 0) {
      throw Exception('7z 压缩失败: ${result.stderr}');
    }
    onProgress?.call(1, '完成');
  }

  int _dirSize(Directory dir) {
    var total = 0;
    for (final e in dir.listSync(recursive: true, followLinks: false)) {
      if (e is File) total += e.lengthSync();
    }
    return total;
  }

  Future<void> _addDirectory(
    Archive archive,
    Directory dir,
    String prefix,
    void Function(String name, int weight) onEach,
  ) async {
    for (final entity in dir.listSync(recursive: true, followLinks: false)) {
      if (entity is File) {
        final rel = _relative(entity.path, dir.path);
        final name = prefix.isEmpty ? rel : '$prefix/$rel';
        final bytes = await entity.readAsBytes();
        onEach(name, bytes.length);
        archive.addFile(ArchiveFile(name, bytes.length, bytes));
      } else if (entity is Directory) {
        final rel = _relative(entity.path, dir.path);
        final name = prefix.isEmpty ? rel : '$prefix/$rel';
        archive.addFile(ArchiveFile('$name/', 0, <int>[]));
      }
    }
  }

  String _relative(String path, String base) {
    final p = path.replaceAll('\\', '/');
    final b = base.replaceAll('\\', '/');
    if (p.startsWith(b)) {
      var r = p.substring(b.length);
      while (r.startsWith('/')) {
        r = r.substring(1);
      }
      return r;
    }
    return p.split('/').last;
  }

  /// 删除压缩包内条目后另存（ZIP）。
  Future<void> removeEntries({
    required String archivePath,
    required List<String> entryPaths,
    required String outputPath,
    void Function(double, String)? onProgress,
  }) async {
    final result = await open(archivePath);
    final archive = result.rawArchive;
    if (archive == null) {
      throw UnsupportedError('当前格式不支持直接编辑');
    }
    final removeSet = entryPaths.toSet();
    final next = Archive();
    var i = 0;
    final total = archive.files.length;
    for (final f in archive.files) {
      final name = f.name.replaceAll('\\', '/');
      final skip = removeSet.any((e) => name == e || name.startsWith('$e/'));
      if (!skip) {
        next.addFile(f);
      }
      i++;
      onProgress?.call(i / total, name);
    }
    final encoded = ZipEncoder().encode(next);
    await File(outputPath).writeAsBytes(encoded, flush: true);
    onProgress?.call(1, '完成');
  }

  Future<void> testArchive(
    String archivePath,
    void Function(double, String)? onProgress,
  ) async {
    final result = await open(archivePath);
    final archive = result.rawArchive;
    if (archive != null) {
      var i = 0;
      for (final f in archive.files) {
        if (f.isFile) {
          // 触发 content 解码校验
          // ignore: unused_local_variable
          final content = f.content;
        }
        i++;
        onProgress?.call(i / archive.files.length, f.name);
      }
      return;
    }
    // 系统工具格式
    final tool = result.format == ArchiveFormat.sevenZip
        ? _findSevenZipBinary()
        : _findRarBinary();
    if (tool == null) throw UnsupportedError('无法测试该格式');
    onProgress?.call(0.2, '测试中...');
    final r = await Process.run(tool, ['t', archivePath]);
    if (r.exitCode != 0) throw Exception('测试失败: ${r.stderr}');
    onProgress?.call(1, '通过');
  }
}
