import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/archive_service.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import 'dialogs/compress_dialog.dart';
import 'dialogs/extract_dialog.dart';
import 'widgets/file_list.dart';
import 'widgets/left_panel.dart';
import 'widgets/menu_bar.dart';
import 'widgets/preview_panel.dart';
import 'widgets/status_bar.dart';
import 'widgets/toolbar.dart';

/// 主窗口：菜单栏 + 工具栏 + 左侧栏 + 文件列表 + 状态栏
class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppController>();

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.f5): app.refresh,
        const SingleActivator(LogicalKeyboardKey.keyA, control: true): app.selectAll,
        const SingleActivator(LogicalKeyboardKey.backspace): app.goUp,
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): () => _onNew(context),
        const SingleActivator(LogicalKeyboardKey.keyO, control: true): () => _onOpen(context),
        const SingleActivator(LogicalKeyboardKey.keyE, control: true): () => _onExtract(context),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: Column(
            children: [
              AppMenuBar(
                onNew: () => _onNew(context),
                onOpen: () => _onOpen(context),
                onExtract: () => _onExtract(context),
                onAdd: () => _onAdd(context),
                onDelete: () => _onDelete(context),
                onTest: () => _onTest(context),
                onAbout: () => showDialog(
                  context: context,
                  builder: (_) => const AboutAppDialog(),
                ),
                onComment: () => _onComment(context),
                onOptions: () => _onOptions(context),
              ),
              if (app.showToolbar)
                AppToolbar(
                  onNew: () => _onNew(context),
                  onOpen: () => _onOpen(context),
                  onExtract: () => _onExtract(context),
                  onAdd: () => _onAdd(context),
                  onDelete: () => _onDelete(context),
                  onTest: () => _onTest(context),
                  onComment: () => _onComment(context),
                  onFind: () => _onFind(context),
                ),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const LeftPanel(),
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(child: FileListView()),
                          if (app.busy)
                            const LinearProgressIndicator(
                              minHeight: 2,
                              color: AppColors.accentGreen,
                            ),
                        ],
                      ),
                    ),
                    if (app.previewVisible) const PreviewPanel(),
                  ],
                ),
              ),
              if (app.showStatusBar) const StatusBar(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onNew(BuildContext context) async {
    final app = context.read<AppController>();
    final paths = await app.pickFilesForCompress();
    if (paths == null || paths.isEmpty || !context.mounted) return;

    final defaultName = paths.length == 1
        ? (paths.first.split(RegExp(r'[/\\]')).last.split('.').first)
        : '新建压缩文件';
    final result = await showDialog<CompressDialogResult>(
      context: context,
      builder: (_) => CompressDialog(
        sourceNames: paths.map((p) => p.split(RegExp(r'[/\\]')).last).toList(),
        defaultName: defaultName,
        defaultDir: app.defaultCompressDir,
      ),
    );
    if (result == null || !context.mounted) return;

    // 对接到系统默认输出目录（下载/源文件目录）
    final outPath = result.outputPath.contains('/')
        ? result.outputPath
        : '${app.defaultCompressDir}/${result.outputPath}';

    try {
      await app.compressPaths(
        paths: paths,
        outputPath: outPath,
        options: CompressOptions(
          format: result.format,
          level: result.level,
          password: result.password,
          includeBaseFolder: result.includeBaseFolder,
          splitVolumeSize: result.splitVolumeSize,
        ),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('压缩完成：$outPath'),
            action: SnackBarAction(
              label: '打开位置',
              onPressed: () => app.revealInFinder(outPath),
            ),
          ),
        );
        app.refresh();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('压缩失败：$e')),
        );
      }
    }
  }

  Future<void> _onOpen(BuildContext context) async {
    final app = context.read<AppController>();
    try {
      final path = await app.pickArchiveToOpen();
      if (path != null) {
        await app.openArchive(path);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('打开失败：$e')),
        );
      }
    }
  }

  Future<void> _onExtract(BuildContext context) async {
    final app = context.read<AppController>();
    if (!app.isBrowsingArchive || app.openArchivePath == null) return;

    final archiveName = app.openArchivePath!.split(RegExp(r'[/\\]')).last;
    // 默认解压到压缩包旁同名目录（系统路径）
    final defaultDest = app.defaultExtractDir;

    final result = await showDialog<ExtractDialogResult>(
      context: context,
      builder: (_) => ExtractDialog(
        archiveName: archiveName,
        defaultDest: defaultDest,
        selectedCount: app.selectedPaths.length,
      ),
    );
    if (result == null || !context.mounted) return;

    try {
      await app.extractSelected(
        destDir: result.destDir,
        keepFullPath: result.keepFullPath,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('解压完成：${result.destDir}'),
            action: SnackBarAction(
              label: '打开位置',
              onPressed: () => app.revealInFinder(result.destDir),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('解压失败：$e')),
        );
      }
    }
  }

  Future<void> _onAdd(BuildContext context) async {
    final app = context.read<AppController>();
    if (app.isBrowsingArchive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请关闭压缩包后，使用「新建」创建或合并压缩文件')),
      );
      return;
    }
    await _onNew(context);
  }

  Future<void> _onDelete(BuildContext context) async {
    final app = context.read<AppController>();
    final selected = app.selectedEntries;
    if (selected.isEmpty) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除选中的 ${selected.length} 个项目吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    if (app.isBrowsingArchive) {
      try {
        await app.deleteSelectedFromArchive();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('已从压缩包删除')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('删除失败：$e')),
          );
        }
      }
    } else {
      // 磁盘删除
      for (final e in selected) {
        try {
          if (e.isFolder) {
            await Directory(e.fullPath).delete(recursive: true);
          } else {
            await File(e.fullPath).delete();
          }
        } catch (e2) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('删除失败：$e2')),
            );
          }
        }
      }
      app.refresh();
    }
  }

  Future<void> _onTest(BuildContext context) async {
    final app = context.read<AppController>();
    try {
      await app.testCurrentArchive();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(app.statusMessage ?? '测试完成')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('测试失败：$e')),
        );
      }
    }
  }

  Future<void> _onComment(BuildContext context) async {
    final app = context.read<AppController>();
    final initial = app.archiveResult?.comment ?? '';
    await showDialog(
      context: context,
      builder: (_) => CommentDialog(initial: initial),
    );
  }

  Future<void> _onFind(BuildContext context) async {
    final app = context.read<AppController>();
    await showDialog(
      context: context,
      builder: (_) => FindDialog(
        onSearch: (keyword) {
          if (keyword.isEmpty) {
            app.refresh();
            return;
          }
          app.setStatus('查找：$keyword');
          // 简单客户端过滤由状态提示 + 未来扩展
        },
      ),
    );
  }

  Future<void> _onOptions(BuildContext context) async {
    showDialog(
      context: context,
      builder: (_) => const AboutAppDialog(),
    );
  }
}
