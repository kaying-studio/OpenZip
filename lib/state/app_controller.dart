import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';

import '../models/archive_entry.dart';
import '../services/archive_service.dart';
import '../services/file_system_service.dart';
import '../utils/format_utils.dart';

/// 主窗口业务状态：地址栏、文件列表、选中项、压缩包内容等。
class AppController extends ChangeNotifier {
  AppController({
    ArchiveService? archiveService,
    FileSystemService? fileSystemService,
  })  : _archive = archiveService ?? ArchiveService(),
        _fs = fileSystemService ?? FileSystemService() {
    _bookmarks = _fs.defaultBookmarks();
    // 启动定位到真实「桌面」或主目录，避免沙箱容器路径
    _browse(_fs.homeOrDesktop, pushHistory: false);
  }

  final ArchiveService _archive;
  final FileSystemService _fs;

  // ---- 导航 ----
  final List<String> _history = [];
  int _historyIndex = -1;
  String _currentPath = '';
  String? _openArchivePath;
  String _archiveInnerPath = ''; // 压缩包内当前目录
  String? _statusMessage = '就绪';
  String? _listError;
  double _progress = 0;
  bool _busy = false;

  // ---- 列表 ----
  List<ArchiveEntry> _visibleEntries = [];
  List<ArchiveEntry> _allEntries = [];
  final Set<String> _selectedPaths = {};

  /// 仅选中变化时更新，避免整树 notifyListeners 造成卡顿。
  final ValueNotifier<Set<String>> selectionListenable =
      ValueNotifier<Set<String>>(const {});

  void _emitSelection() {
    selectionListenable.value = Set<String>.unmodifiable(_selectedPaths);
    notifyListeners();
  }
  SortColumn _sortColumn = SortColumn.name;
  SortOrder _sortOrder = SortOrder.asc;
  bool _showHidden = false;
  bool _folderTreeVisible = true;

  // ---- 压缩包 ----
  ArchiveOpenResult? _archiveResult;
  late List<BookmarkItem> _bookmarks;
  final List<String> _recentArchives = [];

  // ---- 编辑菜单/视图 ----
  bool _showToolbar = true;
  bool _showStatusBar = true;
  bool _showDetailsView = true;
  bool _previewVisible = true;

  // ========== Getters ==========
  String get currentPath => _currentPath;
  String? get openArchivePath => _openArchivePath;
  String get archiveInnerPath => _archiveInnerPath;
  bool get isBrowsingArchive => _openArchivePath != null;
  ArchiveOpenResult? get archiveResult => _archiveResult;
  List<ArchiveEntry> get visibleEntries => _visibleEntries;
  Set<String> get selectedPaths => _selectedPaths;
  List<BookmarkItem> get bookmarks => _bookmarks;
  List<String> get recentArchives => _recentArchives;
  SortColumn get sortColumn => _sortColumn;
  SortOrder get sortOrder => _sortOrder;
  bool get showHidden => _showHidden;
  bool get showToolbar => _showToolbar;
  bool get showStatusBar => _showStatusBar;
  bool get showDetailsView => _showDetailsView;
  bool get previewVisible => _previewVisible;
  bool get folderTreeVisible => _folderTreeVisible;
  String? get statusMessage => _statusMessage;
  String? get listError => _listError;
  double get progress => _progress;
  bool get busy => _busy;
  bool get canGoBack => _historyIndex > 0;
  bool get canGoForward => _historyIndex < _history.length - 1;

  List<ArchiveEntry> get selectedEntries =>
      _visibleEntries.where((e) => _selectedPaths.contains(e.fullPath)).toList();

  ArchiveEntry? get firstSelected =>
      selectedEntries.isEmpty ? null : selectedEntries.first;

  String get statusSelectionText {
    if (_selectedPaths.isEmpty) {
      return '${_visibleEntries.length} 个项目';
    }
    var total = 0;
    for (final e in selectedEntries) {
      if (!e.isFolder) total += e.size;
    }
    return '已选择 ${_selectedPaths.length} 个项目（${formatBytes(total)}）';
  }

  String get displayTitle {
    if (_openArchivePath != null) {
      final name = _openArchivePath!.split(RegExp(r'[/\\]')).last;
      return 'OpenZip — $name';
    }
    return 'OpenZip';
  }

  String get addressText {
    if (_openArchivePath != null) {
      final name = _openArchivePath!.split(RegExp(r'[/\\]')).last;
      final inner = _archiveInnerPath.isEmpty ? '' : ' / $_archiveInnerPath';
      return '$name$inner';
    }
    return _currentPath;
  }

  List<String> get addressSegments {
    if (_openArchivePath != null) {
      final name = _openArchivePath!.split(RegExp(r'[/\\]')).last;
      final segs = <String>[name];
      if (_archiveInnerPath.isNotEmpty) {
        segs.addAll(_archiveInnerPath.split('/'));
      }
      return segs;
    }
    final parts = _currentPath.split(RegExp(r'[/\\]')).where((s) => s.isNotEmpty).toList();
    if (Platform.isWindows && _currentPath.contains(':')) {
      return [_currentPath.split('\\').first, ...parts.skip(1)];
    }
    return ['/', ...parts];
  }

  /// 面包屑点击：按段索引跳转。
  void navigateToSegment(int index) {
    if (index < 0) return;
    if (_openArchivePath != null) {
      if (index == 0) {
        navigateInner('');
      } else {
        navigateInner(addressSegments.sublist(1, index + 1).join('/'));
      }
      return;
    }
    final segs = addressSegments;
    if (index >= segs.length) return;
    if (Platform.isWindows) {
      if (index == 0) {
        browsePath(segs.first);
        return;
      }
      // Windows: C:\ + rest
      final rest = segs.sublist(1, index + 1).join('\\');
      browsePath(rest.isEmpty ? segs.first : '${segs.first}\\$rest');
      return;
    }
    // Unix: '/' + parts
    if (index == 0) {
      browsePath('/');
      return;
    }
    browsePath('/${segs.sublist(1, index + 1).join('/')}');
  }

  // ========== Navigation ==========

  void browsePath(String path, {bool pushHistory = true}) {
    _openArchivePath = null;
    _archiveResult = null;
    _archiveInnerPath = '';
    _browse(path, pushHistory: pushHistory);
  }

  void _browse(String path, {bool pushHistory = true}) {
    _currentPath = path;
    _selectedPaths.clear();
    try {
      _allEntries = _fs.listDirectory(path, showHidden: _showHidden);
      _applyFilterAndSort();
      _statusMessage = path;
      _listError = null;
    } catch (e) {
      _allEntries = [];
      _visibleEntries = [];
      _listError = e.toString().contains('Permission') ||
              e.toString().contains('Operation not permitted')
          ? '没有权限访问该目录，请在系统设置中授权'
          : '无法打开目录';
      _statusMessage = _listError;
    }
    if (pushHistory) _pushHistory(path);
    notifyListeners();
  }

  void _pushHistory(String path) {
    if (_historyIndex >= 0 && _historyIndex < _history.length && _history[_historyIndex] == path) {
      return;
    }
    if (_historyIndex < _history.length - 1) {
      _history.removeRange(_historyIndex + 1, _history.length);
    }
    _history.add(path);
    _historyIndex = _history.length - 1;
    if (_history.length > 64) {
      _history.removeAt(0);
      _historyIndex--;
    }
  }

  void goBack() {
    if (!canGoBack) return;
    _historyIndex--;
    final path = _history[_historyIndex];
    _restorePath(path);
  }

  void goForward() {
    if (!canGoForward) return;
    _historyIndex++;
    final path = _history[_historyIndex];
    _restorePath(path);
  }

  void goUp() {
    if (isBrowsingArchive) {
      if (_archiveInnerPath.isEmpty) {
        closeArchive();
        return;
      }
      final idx = _archiveInnerPath.lastIndexOf('/');
      _archiveInnerPath = idx <= 0 ? '' : _archiveInnerPath.substring(0, idx);
      _filterArchiveView();
      notifyListeners();
      return;
    }
    final parent = Directory(_currentPath).parent;
    if (parent.path != _currentPath) {
      browsePath(parent.path);
    }
  }

  void _restorePath(String path) {
    if (ArchiveService.isArchivePath(path) && File(path).existsSync()) {
      openArchive(path);
      return;
    }
    if (path.contains('.zip') || path.contains('.7z')) {
      // 历史里的压缩包内部
      final idx = path.indexOf('#');
      if (idx > 0) {
        final archivePath = path.substring(0, idx);
        final inner = path.substring(idx + 1);
        openArchive(archivePath).then((_) {
          if (inner.isNotEmpty) {
            navigateInner(inner);
          }
        });
        return;
      }
    }
    _openArchivePath = null;
    _archiveResult = null;
    _archiveInnerPath = '';
    _currentPath = path;
    _selectedPaths.clear();
    _allEntries = _fs.listDirectory(path, showHidden: _showHidden);
    _applyFilterAndSort();
    notifyListeners();
  }

  Future<void> openArchive(String path) async {
    try {
      _setBusy(true, '正在打开: ${path.split(RegExp(r'[/\\]')).last}');
      final result = await _archive.open(path);
      _archiveResult = result;
      _openArchivePath = path;
      _archiveInnerPath = '';
      _currentPath = path;
      _allEntries = result.entries;
      _selectedPaths.clear();
      _listError = null;
      _filterArchiveView();
      _pushHistory(path);
      if (!_recentArchives.contains(path)) {
        _recentArchives.insert(0, path);
        if (_recentArchives.length > 12) _recentArchives.removeLast();
      }
      _statusMessage = '已打开压缩包：${result.entries.length} 个项目';
      _setBusy(false);
    } catch (e) {
      _setBusy(false);
      _statusMessage = '打开失败: $e';
      rethrow;
    }
  }

  void closeArchive() {
    _openArchivePath = null;
    _archiveResult = null;
    _archiveInnerPath = '';
    final path = _openArchivePath ?? _currentPath;
    // 回到压缩包所在目录
    final dir = _history.isNotEmpty && _historyIndex >= 0
        ? _history[_historyIndex]
        : path;
    final parent = File(dir).existsSync() ? Directory(dir).parent.path : _fs.homePath;
    _browse(parent);
  }

  void navigateInner(String folderPath) {
    if (!isBrowsingArchive) return;
    _archiveInnerPath = folderPath;
    _filterArchiveView();
    notifyListeners();
  }

  void openEntry(ArchiveEntry entry) {
    if (entry.isFolder) {
      if (isBrowsingArchive) {
        navigateInner(entry.fullPath.replaceAll(RegExp(r'/$'), ''));
      } else {
        browsePath(entry.fullPath);
      }
      return;
    }
    if (isBrowsingArchive) {
      _statusMessage = '双击文件将解压并打开: ${entry.name}';
      notifyListeners();
      return;
    }
    // 磁盘文件：是压缩包则打开
    if (ArchiveService.isArchivePath(entry.fullPath)) {
      openArchive(entry.fullPath);
      return;
    }
    openWithSystem(entry.fullPath);
  }

  /// 用系统默认程序打开文件。
  Future<void> openWithSystem(String path) async {
    try {
      final result = await OpenFilex.open(path);
      if (result.type == ResultType.done) {
        _statusMessage = '已打开: ${path.split(RegExp(r'[/\\]')).last}';
      } else {
        _statusMessage = '无法打开: ${result.message}';
      }
    } catch (e) {
      _statusMessage = '打开失败: $e';
    }
    notifyListeners();
  }

  /// 在 Finder / 资源管理器中显示。
  Future<void> revealInFinder(String path) async {
    try {
      if (Platform.isMacOS) {
        await Process.run('open', ['-R', path]);
      } else if (Platform.isWindows) {
        await Process.run('explorer', ['/select,', path]);
      } else {
        final dir = File(path).existsSync()
            ? File(path).parent.path
            : path;
        await Process.run('xdg-open', [dir]);
      }
      _statusMessage = '已在系统中显示';
    } catch (e) {
      _statusMessage = '定位失败: $e';
    }
    notifyListeners();
  }

  String get defaultExtractDir {
    final archive = _openArchivePath;
    if (archive != null) return _fs.defaultExtractDir(archive);
    return _fs.downloadsPath;
  }

  String get defaultCompressDir => _fs.defaultCompressDir();

  String get systemDesktopPath => _fs.desktopPath;
  String get systemDownloadsPath => _fs.downloadsPath;
  String get systemHomePath => _fs.homePath;

  // ========== Selection ==========

  void select(String path, {bool additive = false, bool range = false}) {
    if (!additive && !range) {
      _selectedPaths
        ..clear()
        ..add(path);
    } else if (additive) {
      if (!_selectedPaths.remove(path)) {
        _selectedPaths.add(path);
      }
    } else if (range && _selectedPaths.isNotEmpty) {
      final last = _selectedPaths.last;
      final list = _visibleEntries.map((e) => e.fullPath).toList();
      final i1 = list.indexOf(last);
      final i2 = list.indexOf(path);
      if (i1 >= 0 && i2 >= 0) {
        final start = i1 < i2 ? i1 : i2;
        final end = i1 < i2 ? i2 : i1;
        _selectedPaths.addAll(list.sublist(start, end + 1));
      }
    } else {
      _selectedPaths.add(path);
    }
    _emitSelection();
  }

  void selectAll() {
    _selectedPaths
      ..clear()
      ..addAll(_visibleEntries.map((e) => e.fullPath));
    _emitSelection();
  }

  void clearSelection() {
    _selectedPaths.clear();
    _emitSelection();
  }

  void invertSelection() {
    final all = _visibleEntries.map((e) => e.fullPath).toSet();
    _selectedPaths.clear();
    _selectedPaths.addAll(all.difference(_selectedPaths));
    _emitSelection();
  }

  // ========== Sort / Filter ==========

  void sortBy(SortColumn column) {
    if (_sortColumn == column) {
      _sortOrder = _sortOrder == SortOrder.asc ? SortOrder.desc : SortOrder.asc;
    } else {
      _sortColumn = column;
      _sortOrder = SortOrder.asc;
    }
    _applyFilterAndSort();
    notifyListeners();
  }

  void _applyFilterAndSort() {
    final list = [..._allEntries];
    list.sort((a, b) {
      // 文件夹始终在前
      if (a.isFolder != b.isFolder) return a.isFolder ? -1 : 1;
      int cmp;
      switch (_sortColumn) {
        case SortColumn.name:
          cmp = a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case SortColumn.size:
          cmp = a.size.compareTo(b.size);
        case SortColumn.type:
          cmp = fileTypeLabel(a.name, isDir: a.isFolder)
              .compareTo(fileTypeLabel(b.name, isDir: b.isFolder));
        case SortColumn.modified:
          cmp = (a.modified ?? DateTime(1970)).compareTo(b.modified ?? DateTime(1970));
        case SortColumn.compressed:
          cmp = (a.compressedSize ?? a.size).compareTo(b.compressedSize ?? b.size);
        case SortColumn.rate:
          cmp = a.compressionRate.compareTo(b.compressionRate);
        case SortColumn.crc:
          cmp = (a.crc32 ?? 0).compareTo(b.crc32 ?? 0);
        case SortColumn.path:
          cmp = a.fullPath.compareTo(b.fullPath);
        case SortColumn.attr:
          cmp = (a.isFolder ? 0 : 1).compareTo(b.isFolder ? 0 : 1);
      }
      return _sortOrder == SortOrder.asc ? cmp : -cmp;
    });
    _visibleEntries = list;
  }

  void _filterArchiveView() {
    if (_archiveResult == null) return;
    final prefix = _archiveInnerPath.isEmpty ? '' : '$_archiveInnerPath/';
    final folders = <String, ArchiveEntry>{};
    final files = <ArchiveEntry>[];
    for (final e in _archiveResult!.entries) {
      final p = e.fullPath.replaceAll(RegExp(r'/$'), '');
      if (prefix.isNotEmpty && !p.startsWith(prefix)) continue;
      final rel = prefix.isEmpty ? p : p.substring(prefix.length);
      if (rel.isEmpty) continue;
      if (rel.contains('/')) {
        final folderName = rel.split('/').first;
        final folderPath = prefix.isEmpty ? folderName : '$prefix$folderName';
        folders.putIfAbsent(
          folderPath,
          () => ArchiveEntry(
            name: folderName,
            fullPath: folderPath,
            isDir: true,
          ),
        );
      } else {
        files.add(e);
      }
    }
    _allEntries = [...folders.values, ...files];
    _applyFilterAndSort();
  }

  // ========== Archive operations ==========

  Future<void> extractSelected({
    required String destDir,
    bool keepFullPath = true,
  }) async {
    if (_openArchivePath == null) return;
    try {
      _setBusy(true, '正在解压...');
      final names = selectedEntries.isEmpty
          ? null
          : selectedEntries
              .map((e) => isBrowsingArchive && _archiveInnerPath.isNotEmpty
                  ? e.fullPath
                  : e.fullPath)
              .toList();
      await _archive.extract(
        archivePath: _openArchivePath!,
        destDir: destDir,
        entryPaths: names,
        options: ExtractOptions(keepFullPath: keepFullPath),
        onProgress: _onProgress,
      );
      _setBusy(false);
      _statusMessage = '解压完成: $destDir';
      notifyListeners();
    } catch (e) {
      _setBusy(false);
      _statusMessage = '解压失败: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> compressPaths({
    required List<String> paths,
    required String outputPath,
    CompressOptions options = const CompressOptions(),
  }) async {
    try {
      _setBusy(true, '正在压缩...');
      await _archive.compress(
        sourcePaths: paths,
        outputPath: outputPath,
        options: options,
        onProgress: _onProgress,
      );
      _setBusy(false);
      _statusMessage = '压缩完成: $outputPath';
      notifyListeners();
    } catch (e) {
      _setBusy(false);
      _statusMessage = '压缩失败: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteSelectedFromArchive() async {
    if (_openArchivePath == null || selectedEntries.isEmpty) return;
    try {
      _setBusy(true, '正在删除...');
      final tmp = '${_openArchivePath!}.tmp.zip';
      await _archive.removeEntries(
        archivePath: _openArchivePath!,
        entryPaths: selectedEntries.map((e) => e.fullPath).toList(),
        outputPath: tmp,
        onProgress: _onProgress,
      );
      // 覆盖回写
      final src = File(tmp);
      await src.copy(_openArchivePath!);
      await src.delete();
      await openArchive(_openArchivePath!);
      _setBusy(false);
      _statusMessage = '已删除';
      notifyListeners();
    } catch (e) {
      _setBusy(false);
      _statusMessage = '删除失败: $e';
      notifyListeners();
    }
  }

  Future<void> testCurrentArchive() async {
    if (_openArchivePath == null) return;
    try {
      _setBusy(true, '正在测试...');
      await _archive.testArchive(_openArchivePath!, _onProgress);
      _setBusy(false);
      _statusMessage = '测试通过，压缩包完好';
      notifyListeners();
    } catch (e) {
      _setBusy(false);
      _statusMessage = '测试失败: $e';
      notifyListeners();
    }
  }

  /// 测试磁盘上的压缩包。
  Future<void> testArchivePath(String path) async {
    try {
      _setBusy(true, '正在测试...');
      await _archive.testArchive(path, _onProgress);
      _setBusy(false);
      _statusMessage = '测试通过：${path.split(RegExp(r'[/\\]')).last}';
      notifyListeners();
    } catch (e) {
      _setBusy(false);
      _statusMessage = '测试失败: $e';
      notifyListeners();
    }
  }

  /// 解压指定磁盘压缩包到目录。
  Future<void> extractArchivePath({
    required String archivePath,
    required String destDir,
    List<String>? entryPaths,
    bool keepFullPath = true,
  }) async {
    try {
      _setBusy(true, '正在解压...');
      await _archive.extract(
        archivePath: archivePath,
        destDir: destDir,
        entryPaths: entryPaths,
        options: ExtractOptions(keepFullPath: keepFullPath),
        onProgress: _onProgress,
      );
      _setBusy(false);
      _statusMessage = '解压完成: $destDir';
      notifyListeners();
    } catch (e) {
      _setBusy(false);
      _statusMessage = '解压失败: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// 修复压缩包（ZIP 重写校验；其它格式调用系统工具）。
  Future<void> repairArchive(String path) async {
    try {
      _setBusy(true, '正在修复...');
      final format = ArchiveService.formatFromPath(path);
      if (format == ArchiveFormat.zip) {
        final tmp = '$path.repair.tmp.zip';
        await _archive.removeEntries(
          archivePath: path,
          entryPaths: const [],
          outputPath: tmp,
          onProgress: _onProgress,
        );
        final tmpFile = File(tmp);
        if (tmpFile.existsSync()) {
          await tmpFile.copy(path);
          await tmpFile.delete();
        }
        _setBusy(false);
        _statusMessage = '修复完成：${path.split(RegExp(r'[/\\]')).last}';
      } else {
        final tool = format == ArchiveFormat.sevenZip ? '7z' : 'unrar';
        final r = await Process.run(tool, ['r', path]);
        _setBusy(false);
        if (r.exitCode == 0) {
          _statusMessage = '修复完成：${path.split(RegExp(r'[/\\]')).last}';
        } else {
          _statusMessage = '修复失败：请安装 $tool 或改用 ZIP';
        }
      }
      notifyListeners();
    } catch (e) {
      _setBusy(false);
      _statusMessage = '修复失败: $e';
      notifyListeners();
    }
  }

  /// 重命名（磁盘文件；压缩包内提示另存）。
  Future<void> renameEntry(ArchiveEntry entry, String newName) async {
    try {
      if (isBrowsingArchive) {
        _statusMessage = '压缩包内重命名请解压后修改，或使用「删除 + 添加」';
        notifyListeners();
        return;
      }
      final src = File(entry.fullPath);
      final parent = src.parent.path;
      final dest = '$parent/$newName';
      if (File(dest).existsSync() || Directory(dest).existsSync()) {
        _statusMessage = '目标名称已存在: $newName';
        notifyListeners();
        return;
      }
      if (entry.isFolder) {
        await Directory(entry.fullPath).rename(dest);
      } else {
        await src.rename(dest);
      }
      refresh();
      _statusMessage = '已重命名为 $newName';
      notifyListeners();
    } catch (e) {
      _statusMessage = '重命名失败: $e';
      notifyListeners();
    }
  }

  /// 删除磁盘文件/文件夹。
  Future<void> deletePaths(List<String> paths) async {
    try {
      _setBusy(true, '正在删除...');
      for (final p in paths) {
        final type = FileSystemEntity.typeSync(p);
        if (type == FileSystemEntityType.directory) {
          await Directory(p).delete(recursive: true);
        } else {
          await File(p).delete();
        }
      }
      _setBusy(false);
      _statusMessage = '已删除 ${paths.length} 项';
      refresh();
      notifyListeners();
    } catch (e) {
      _setBusy(false);
      _statusMessage = '删除失败: $e';
      notifyListeners();
    }
  }

  // ========== UI toggles ==========

  void toggleToolbar() {
    _showToolbar = !_showToolbar;
    notifyListeners();
  }

  void toggleStatusBar() {
    _showStatusBar = !_showStatusBar;
    notifyListeners();
  }

  void toggleDetailsView() {
    _showDetailsView = !_showDetailsView;
    notifyListeners();
  }

  void togglePreview() {
    _previewVisible = !_previewVisible;
    notifyListeners();
  }

  void toggleFolderTree() {
    _folderTreeVisible = !_folderTreeVisible;
    notifyListeners();
  }

  void toggleHidden() {
    _showHidden = !_showHidden;
    if (!isBrowsingArchive) {
      _allEntries = _fs.listDirectory(_currentPath, showHidden: _showHidden);
      _applyFilterAndSort();
    }
    notifyListeners();
  }

  void refresh() {
    if (isBrowsingArchive && _openArchivePath != null) {
      openArchive(_openArchivePath!);
    } else {
      _browse(_currentPath, pushHistory: false);
      if (_listError == null) {
        _statusMessage = '已刷新';
      }
      notifyListeners();
    }
  }

  void setStatus(String message) {
    _statusMessage = message;
    notifyListeners();
  }

  void _onProgress(double value, String current) {
    _progress = value.clamp(0, 1);
    _statusMessage = current;
    notifyListeners();
  }

  void _setBusy(bool value, [String? message]) {
    _busy = value;
    _progress = value ? 0 : 0;
    if (message != null) _statusMessage = message;
    notifyListeners();
  }

  // ========== Pickers ==========

  Future<List<String>?> pickFilesForCompress() async {
    final result = await FilePicker.pickFiles(
      initialDirectory: _fs.homeOrDesktop,
    );
    final paths = result.map((f) => f.path).whereType<String>().toList();
    return paths.isEmpty ? null : paths;
  }

  Future<String?> pickArchiveToOpen() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip', '7z', 'rar', 'tar', 'gz', 'tgz'],
      initialDirectory: _fs.downloadsPath,
    );
    return result.isEmpty ? null : result.first.path;
  }

  Future<String?> pickDirectoryForExtract() async {
    return FilePicker.getDirectoryPath(
      dialogTitle: '解压到',
      initialDirectory: _fs.downloadsPath,
    );
  }

  Future<String?> pickDirectory() async {
    return FilePicker.getDirectoryPath(initialDirectory: _fs.homeOrDesktop);
  }

  /// 打开磁盘文件夹中的压缩包，或浏览目录。
  Future<void> openPathFromAddress(String text) async {
    final t = text.trim();
    if (t.isEmpty) return;
    if (ArchiveService.isArchivePath(t) && File(t).existsSync()) {
      await openArchive(t);
      return;
    }
    if (Directory(t).existsSync()) {
      browsePath(t);
      return;
    }
    _statusMessage = '路径不存在: $t';
    notifyListeners();
  }

  List<ArchiveEntry> get sidebarDrives => _fs.listDriveRoots();

  FileSystemService get fs => _fs;
}
