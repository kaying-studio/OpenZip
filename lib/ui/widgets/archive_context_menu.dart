import 'dart:io' show File;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/archive_entry.dart';
import '../../services/archive_service.dart';
import '../../state/app_controller.dart';
import '../../theme/app_theme.dart';
import '../../utils/format_utils.dart';
import '../dialogs/compress_dialog.dart';
import '../dialogs/extract_dialog.dart';
import 'polished_menu.dart';

/// 右键菜单：压缩 / 解压 / 测试 / 管理。
Future<void> showArchiveContextMenu({
  required BuildContext context,
  required AppController app,
  required ArchiveEntry entry,
  required Offset position,
}) async {
  final isArchiveMode = app.isBrowsingArchive;
  final isArchiveFile =
      !entry.isFolder && ArchiveService.isArchivePath(entry.fullPath);
  final selectedCount = app.selectedPaths.length;
  final multi = selectedCount > 1;
  final nameNoExt = entry.name.contains('.')
      ? entry.name.substring(0, entry.name.lastIndexOf('.'))
      : entry.name;

  final items = <MenuAction>[
    // —— 压缩 ——
    if (!isArchiveMode) ...[
      MenuAction(
        id: 'compress_dialog',
        label: multi ? '添加到压缩文件...（$selectedCount 项）' : '添加到压缩文件...',
        icon: Icons.archive_outlined,
        primary: true,
        shortcut: 'Ctrl+N',
      ),
      MenuAction(
        id: 'compress_quick',
        label: '添加到 "${_zipName(entry, multi, selectedCount)}"',
        icon: Icons.bolt_outlined,
        primary: true,
      ),
      const MenuAction(
        id: 'compress_email',
        label: '压缩并邮寄...',
        icon: Icons.mail_outline,
      ),
      const MenuAction.divider(),
    ],

    // —— 解压 ——
    if (isArchiveFile && !isArchiveMode) ...[
      const MenuAction(
        id: 'extract_here',
        label: '解压到当前文件夹',
        icon: Icons.drive_folder_upload_outlined,
        primary: true,
      ),
      MenuAction(
        id: 'extract_named',
        label: '解压到 "$nameNoExt\\"',
        icon: Icons.create_new_folder_outlined,
        primary: true,
      ),
      const MenuAction(
        id: 'extract_dialog',
        label: '解压到指定文件夹...',
        icon: Icons.unarchive_outlined,
        shortcut: 'Ctrl+E',
      ),
      const MenuAction.divider(),
    ],
    if (isArchiveMode) ...[
      const MenuAction(
        id: 'extract_dialog',
        label: '解压到指定文件夹...',
        icon: Icons.unarchive_outlined,
        primary: true,
        shortcut: 'Ctrl+E',
      ),
      const MenuAction(
        id: 'extract_here',
        label: '解压到当前文件夹',
        icon: Icons.drive_folder_upload_outlined,
        primary: true,
      ),
      const MenuAction(
        id: 'extract_parent',
        label: '解压到压缩包所在目录',
        icon: Icons.folder_copy_outlined,
      ),
      MenuAction(
        id: 'extract_named',
        label: '解压到 "$nameNoExt\\"',
        icon: Icons.create_new_folder_outlined,
      ),
      const MenuAction.divider(),
    ],

    // —— 打开 / 查看 ——
    const MenuAction(id: 'open', label: '打开', icon: Icons.folder_open_outlined, shortcut: 'Enter'),
    if (entry.isFolder && !isArchiveMode)
      const MenuAction(id: 'enter', label: '打开文件夹', icon: Icons.subdirectory_arrow_right),
    if (!entry.isFolder && !isArchiveMode)
      const MenuAction(
        id: 'open_system',
        label: '用系统程序打开',
        icon: Icons.open_in_new_outlined,
      ),
    if (isArchiveFile || isArchiveMode)
      const MenuAction(id: 'view', label: '查看', icon: Icons.visibility_outlined),
    if (!isArchiveMode)
      const MenuAction(
        id: 'reveal',
        label: '在资源管理器中显示',
        icon: Icons.folder_shared_outlined,
        shortcut: 'Ctrl+R',
      ),
    const MenuAction.divider(),

    // —— 测试 / 修复 / 注释 ——
    if (isArchiveFile || isArchiveMode) ...[
      const MenuAction(
        id: 'test',
        label: '测试压缩文件',
        icon: Icons.verified_outlined,
        shortcut: 'Ctrl+T',
      ),
      const MenuAction(
        id: 'repair',
        label: '修复压缩文件',
        icon: Icons.build_outlined,
      ),
      const MenuAction(
        id: 'comment',
        label: '压缩文件注释',
        icon: Icons.notes_outlined,
      ),
      const MenuAction.divider(),
    ],

    // —— 文件管理 ——
    const MenuAction(
      id: 'rename',
      label: '重命名',
      icon: Icons.drive_file_rename_outline,
      shortcut: 'F2',
    ),
    const MenuAction(id: 'copy_name', label: '复制文件名', icon: Icons.copy_all_outlined),
    const MenuAction(
      id: 'copy_path',
      label: '复制完整路径',
      icon: Icons.link_outlined,
      shortcut: 'Ctrl+Shift+C',
    ),
    const MenuAction.divider(),
    MenuAction(
      id: 'delete',
      label: isArchiveMode ? '从压缩包删除' : '删除',
      icon: Icons.delete_outline,
      danger: true,
      shortcut: 'Del',
    ),
    const MenuAction(
      id: 'prop',
      label: '属性',
      icon: Icons.info_outline,
      shortcut: 'Alt+Enter',
    ),
  ];

  final action = await showPolishedContextMenu(
    context: context,
    position: position,
    items: items,
    width: 268,
  );
  if (action == null || !context.mounted) return;

  await handleArchiveAction(
    context: context,
    app: app,
    entry: entry,
    action: action,
  );
}

String _zipName(ArchiveEntry entry, bool multi, int count) {
  if (multi) return '新建压缩文件.zip';
  if (entry.isFolder) return '${entry.name}.zip';
  final base = entry.name.contains('.')
      ? entry.name.substring(0, entry.name.lastIndexOf('.'))
      : entry.name;
  return '$base.zip';
}

Future<void> handleArchiveAction({
  required BuildContext context,
  required AppController app,
  required ArchiveEntry entry,
  required String action,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final nameNoExt = entry.name.contains('.')
      ? entry.name.substring(0, entry.name.lastIndexOf('.'))
      : entry.name;

  switch (action) {
    case 'open':
    case 'enter':
    case 'view':
      if (action == 'view' && !entry.isFolder &&
          !ArchiveService.isArchivePath(entry.fullPath) &&
          !app.isBrowsingArchive) {
        await app.openWithSystem(entry.fullPath);
      } else {
        app.openEntry(entry);
      }

    case 'open_system':
      await app.openWithSystem(entry.fullPath);

    case 'reveal':
      await app.revealInFinder(entry.fullPath);

    case 'compress_dialog':
      final paths = app.selectedPaths.isNotEmpty
          ? app.selectedEntries.map((e) => e.fullPath).toList()
          : [entry.fullPath];
      final result = await showDialog<CompressDialogResult>(
        context: context,
        builder: (_) => CompressDialog(
          sourceNames: paths.map((p) => p.split(RegExp(r'[/\\]')).last).toList(),
          defaultName: _zipName(entry, paths.length > 1, paths.length)
              .replaceAll(RegExp(r'\.zip$'), ''),
          defaultDir: app.defaultCompressDir,
        ),
      );
      if (result == null) return;
      final out = result.outputPath.contains('/')
          ? result.outputPath
          : '${app.defaultCompressDir}/${result.outputPath}';
      await app.compressPaths(
        paths: paths,
        outputPath: out,
        options: CompressOptions(
          format: result.format,
          level: result.level,
          password: result.password,
          includeBaseFolder: result.includeBaseFolder,
        ),
      );
      messenger.showSnackBar(
        SnackBar(
          content: Text('压缩完成：$out'),
          action: SnackBarAction(
            label: '打开位置',
            onPressed: () => app.revealInFinder(out),
          ),
        ),
      );

    case 'compress_quick':
      final paths = app.selectedPaths.isNotEmpty
          ? app.selectedEntries.map((e) => e.fullPath).toList()
          : [entry.fullPath];
      final zipName = _zipName(entry, paths.length > 1, paths.length);
      final out = '${app.currentPath}/$zipName';
      await app.compressPaths(
        paths: paths,
        outputPath: out,
        options: const CompressOptions(format: ArchiveFormat.zip, level: 6),
      );
      messenger.showSnackBar(
        SnackBar(
          content: Text('已创建：$out'),
          action: SnackBarAction(
            label: '打开位置',
            onPressed: () => app.revealInFinder(out),
          ),
        ),
      );

    case 'compress_email':
      final paths = app.selectedPaths.isNotEmpty
          ? app.selectedEntries.map((e) => e.fullPath).toList()
          : [entry.fullPath];
      final zipName = _zipName(entry, paths.length > 1, paths.length);
      final out = '${app.defaultCompressDir}/$zipName';
      await app.compressPaths(
        paths: paths,
        outputPath: out,
        options: const CompressOptions(format: ArchiveFormat.zip, level: 6),
      );
      messenger.showSnackBar(
        SnackBar(content: Text('已压缩：$out\n（当前版本未集成邮件客户端，可手动发送该附件）')),
      );

    case 'extract_dialog':
      final archivePath = app.openArchivePath ?? entry.fullPath;
      final dest = await showDialog<ExtractDialogResult>(
        context: context,
        builder: (_) => ExtractDialog(
          archiveName: archivePath.split(RegExp(r'[/\\]')).last,
          defaultDest: app.defaultExtractDir,
          selectedCount: app.selectedPaths.length,
        ),
      );
      if (dest == null) return;
      if (app.isBrowsingArchive) {
        await app.extractSelected(destDir: dest.destDir);
      } else {
        await app.extractArchivePath(
          archivePath: entry.fullPath,
          destDir: dest.destDir,
          keepFullPath: dest.keepFullPath,
        );
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text('解压完成：${dest.destDir}'),
          action: SnackBarAction(
            label: '打开位置',
            onPressed: () => app.revealInFinder(dest.destDir),
          ),
        ),
      );

    case 'extract_here':
      final dest = app.isBrowsingArchive
          ? app.currentPath
          : File(entry.fullPath).parent.path;
      if (app.isBrowsingArchive) {
        await app.extractSelected(destDir: dest);
      } else {
        await app.extractArchivePath(archivePath: entry.fullPath, destDir: dest);
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text('已解压到当前文件夹：$dest'),
          action: SnackBarAction(
            label: '打开位置',
            onPressed: () => app.revealInFinder(dest),
          ),
        ),
      );

    case 'extract_parent':
      final archivePath = app.openArchivePath!;
      final dest = File(archivePath).parent.path;
      await app.extractSelected(destDir: dest);
      messenger.showSnackBar(
        SnackBar(
          content: Text('已解压到：$dest'),
          action: SnackBarAction(
            label: '打开位置',
            onPressed: () => app.revealInFinder(dest),
          ),
        ),
      );

    case 'extract_named':
      final base = app.isBrowsingArchive
          ? app.currentPath
          : File(entry.fullPath).parent.path;
      final dest = '$base/$nameNoExt';
      if (app.isBrowsingArchive) {
        await app.extractSelected(destDir: dest);
      } else {
        await app.extractArchivePath(archivePath: entry.fullPath, destDir: dest);
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text('已解压到：$dest'),
          action: SnackBarAction(
            label: '打开位置',
            onPressed: () => app.revealInFinder(dest),
          ),
        ),
      );

    case 'test':
      if (app.isBrowsingArchive) {
        await app.testCurrentArchive();
      } else {
        await app.testArchivePath(entry.fullPath);
      }
      messenger.showSnackBar(
        SnackBar(content: Text(app.statusMessage ?? '测试完成')),
      );

    case 'repair':
      await app.repairArchive(entry.fullPath);
      messenger.showSnackBar(
        SnackBar(content: Text(app.statusMessage ?? '修复完成')),
      );

    case 'comment':
      app.setStatus('注释：${entry.name}');

    case 'rename':
      final newName = await showDialog<String>(
        context: context,
        builder: (_) => RenameDialog(initial: entry.name),
      );
      if (newName == null || newName.isEmpty || newName == entry.name) return;
      await app.renameEntry(entry, newName);
      messenger.showSnackBar(
        SnackBar(content: Text(app.statusMessage ?? '已重命名')),
      );

    case 'copy_name':
      await Clipboard.setData(ClipboardData(text: entry.name));
      app.setStatus('已复制文件名');

    case 'copy_path':
      await Clipboard.setData(ClipboardData(text: entry.fullPath));
      app.setStatus('已复制完整路径');

    case 'delete':
      if (app.isBrowsingArchive) {
        await app.deleteSelectedFromArchive();
      } else {
        await app.deletePaths(
          app.selectedPaths.isNotEmpty
              ? app.selectedEntries.map((e) => e.fullPath).toList()
              : [entry.fullPath],
        );
      }
      messenger.showSnackBar(
        SnackBar(content: Text(app.statusMessage ?? '已删除')),
      );

    case 'prop':
      await showDialog(
        context: context,
        builder: (_) => PropertiesDialog(entry: entry, app: app),
      );
  }
}

/// 重命名对话框。
class RenameDialog extends StatefulWidget {
  const RenameDialog({super.key, required this.initial});
  final String initial;

  @override
  State<RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<RenameDialog> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('重命名'),
      content: SizedBox(
        width: 360,
        child: TextField(
          controller: _ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: '新名称',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          onSubmitted: (v) => Navigator.pop(context, v.trim()),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _ctrl.text.trim()),
          child: const Text('确定'),
        ),
      ],
    );
  }
}

/// 属性对话框。
class PropertiesDialog extends StatelessWidget {
  const PropertiesDialog({super.key, required this.entry, required this.app});

  final ArchiveEntry entry;
  final AppController app;

  @override
  Widget build(BuildContext context) {
    final rows = <MapEntry<String, String>>[
      MapEntry('名称', entry.name),
      MapEntry('类型', fileTypeLabel(entry.name, isDir: entry.isFolder)),
      MapEntry('大小', entry.isFolder ? '-' : formatBytes(entry.size)),
      if (!entry.isFolder) ...[
        MapEntry('压缩后', formatBytes(entry.compressedSize ?? entry.size)),
        MapEntry(
          '压缩率',
          formatCompression(entry.size, entry.compressedSize ?? entry.size),
        ),
        MapEntry('CRC', crc32Hex(entry.crc32)),
      ],
      MapEntry('修改时间', formatDateTime(entry.modified)),
      MapEntry('属性', formatAttr(isDir: entry.isFolder)),
      MapEntry('完整路径', entry.fullPath),
      if (app.isBrowsingArchive)
        MapEntry('所在压缩包', app.openArchivePath ?? '-'),
    ];

    return AlertDialog(
      title: const Text('属性'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final r in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 88,
                      child: Text(
                        r.key,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      child: SelectableText(
                        r.value,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('确定'),
        ),
      ],
    );
  }
}
