import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/gestures.dart' show kSecondaryMouseButton;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/archive_entry.dart';
import '../../services/archive_service.dart';
import '../../state/app_controller.dart';
import '../../theme/app_theme.dart';
import '../../utils/format_utils.dart';
import 'archive_context_menu.dart';
import 'polished_menu.dart';

/// 详细信息文件列表（可排序表头）。
class FileListView extends StatefulWidget {
  const FileListView({super.key});

  @override
  State<FileListView> createState() => _FileListViewState();
}

class _FileListViewState extends State<FileListView> {
  final _scroll = ScrollController();
  final _hScroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    _hScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppController>();
    final isArchive = app.isBrowsingArchive;
    // 选中变化单独听，减少全表重建
    return ValueListenableBuilder<Set<String>>(
      valueListenable: app.selectionListenable,
      builder: (context, selectedPaths, _) {
        return _buildBody(context, app, isArchive, selectedPaths);
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppController app,
    bool isArchive,
    Set<String> selectedPaths,
  ) {

    final columns = <_Col>[
      _Col('名称', 220, SortColumn.name, leading: true),
      _Col('大小', 80, SortColumn.size),
      _Col('类型', 110, SortColumn.type),
      _Col('修改时间', 130, SortColumn.modified),
      if (isArchive) ...[
        _Col('压缩后', 80, SortColumn.compressed),
        _Col('压缩率', 70, SortColumn.rate),
        _Col('CRC', 80, SortColumn.crc),
      ],
      _Col('路径', 160, SortColumn.path),
      _Col('属性', 50, SortColumn.attr),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          // 表头（与列表共享横向滚动）
          SizedBox(
            height: 32,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  controller: _hScroll,
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: constraints.maxWidth < 1100 ? 1100 : constraints.maxWidth,
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        color: AppColors.colHeader,
                        border: Border(bottom: BorderSide(color: AppColors.borderStrong)),
                      ),
                      child: Row(
                        children: [
                          for (final c in columns)
                            _HeaderCell(
                              col: c,
                              active: app.sortColumn == c.sort,
                              order: app.sortOrder,
                              onTap: () => app.sortBy(c.sort),
                            ),
                          Expanded(
                            child: Container(
                              decoration: const BoxDecoration(
                                border:
                                    Border(left: BorderSide(color: AppColors.border)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // 列表
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onSecondaryTapUp: (details) {
                _showBackgroundMenu(context, app, details.globalPosition);
              },
              child: app.visibleEntries.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F8FC),
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Icon(
                            app.listError != null
                                ? Icons.lock_outline
                                : Icons.archive_rounded,
                            size: 56,
                            color: app.listError != null
                                ? AppColors.warning
                                : AppColors.zhihuBlue,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          app.listError ?? (app.isBrowsingArchive ? '压缩包内没有条目' : '此文件夹为空'),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          app.listError != null
                              ? '可尝试「系统设置 → 隐私与安全性 → 完全磁盘访问」授权本应用'
                              : (app.isBrowsingArchive
                                  ? '可返回上级目录或打开其他压缩包'
                                  : '点击工具栏「新建」或「打开」开始'),
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (app.listError != null) ...[
                          const SizedBox(height: 14),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.zhihuBlue,
                            ),
                            onPressed: () async {
                              final dir = await app.pickDirectory();
                              if (dir != null) app.browsePath(dir);
                            },
                            icon: const Icon(Icons.folder_open, size: 16),
                            label: const Text('选择文件夹以打开'),
                          ),
                        ],
                      ],
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth < 1100 ? 1100.0 : constraints.maxWidth;
                      return Scrollbar(
                        controller: _scroll,
                        thumbVisibility: true,
                        child: ListView.builder(
                          controller: _scroll,
                          itemExtent: 28,
                          itemCount: app.visibleEntries.length,
                          itemBuilder: (context, index) {
                            final entry = app.visibleEntries[index];
                            final selected =
                                selectedPaths.contains(entry.fullPath);
                            return SingleChildScrollView(
                              controller: _hScroll,
                              scrollDirection: Axis.horizontal,
                              child: SizedBox(
                                width: width,
                                child: _FileRow(
                                  entry: entry,
                                  selected: selected,
                                  columns: columns,
                                  isArchive: isArchive,
                                  onTap: (additive, range) {
                                    app.select(entry.fullPath,
                                        additive: additive, range: range);
                                  },
                                  onDoubleTap: () {
                                    if (entry.isFolder ||
                                        ArchiveService.isArchivePath(entry.fullPath)) {
                                      app.openEntry(entry);
                                    } else if (app.isBrowsingArchive) {
                                      app.setStatus('请使用「解压」提取 ${entry.name}');
                                    } else {
                                      app.openEntry(entry);
                                    }
                                  },
                                  onSecondaryTap: (pos) {
                                    if (!selected) {
                                      app.select(entry.fullPath);
                                    }
                                    _showContextMenu(context, app, entry, pos);
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
            ),
          ),
          if (app.busy && app.progress > 0)
            LinearProgressIndicator(
              value: app.progress,
              minHeight: 3,
              backgroundColor: AppColors.border,
              color: AppColors.accentGreen,
            ),
          // 当前压缩包信息条
          if (app.isBrowsingArchive && app.archiveResult != null)
            Container(
              color: AppColors.accentBlue.withValues(alpha: 0.06),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              child: Row(
                children: [
                  const Icon(Icons.archive_outlined, size: 14, color: AppColors.accentBlue),
                  const SizedBox(width: 6),
                  Text(
                    '${app.archiveResult!.formatLabel}  ·  ${app.archiveResult!.entries.length} 个项目  ·  '
                    '${formatBytes(app.archiveResult!.entries.fold<int>(0, (a, e) => a + e.size))}',
                    style: const TextStyle(fontSize: 11.5, color: AppColors.accentBlueDark),
                  ),
                  const Spacer(),
                  if (app.archiveResult!.comment.isNotEmpty)
                    Expanded(
                      flex: 2,
                      child: Text(
                        '注释: ${app.archiveResult!.comment}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showContextMenu(
    BuildContext context,
    AppController app,
    ArchiveEntry entry,
    Offset pos,
  ) {
    showArchiveContextMenu(
      context: context,
      app: app,
      entry: entry,
      position: pos,
    );
  }

  void _showBackgroundMenu(BuildContext context, AppController app, Offset pos) {
    final items = <MenuAction>[
      if (!app.isBrowsingArchive) ...[
        const MenuAction(id: 'refresh', label: '刷新', icon: Icons.refresh_rounded, shortcut: 'F5'),
        const MenuAction(id: 'up', label: '向上一级', icon: Icons.arrow_upward_rounded),
        const MenuAction.divider(),
        const MenuAction(
          id: 'compress_here',
          label: '压缩当前文件夹...',
          icon: Icons.archive_outlined,
          primary: true,
        ),
        const MenuAction(
          id: 'extract_here_dir',
          label: '解压到当前文件夹',
          icon: Icons.unarchive_outlined,
        ),
      ] else ...[
        const MenuAction(id: 'refresh', label: '刷新', icon: Icons.refresh_rounded, shortcut: 'F5'),
        const MenuAction(id: 'up', label: '向上一级', icon: Icons.arrow_upward_rounded),
        const MenuAction.divider(),
        const MenuAction(
          id: 'extract_all_here',
          label: '全部解压到当前文件夹',
          icon: Icons.drive_folder_upload_outlined,
          primary: true,
        ),
      ],
      const MenuAction.divider(),
      const MenuAction(id: 'select_all', label: '全选', icon: Icons.select_all_rounded, shortcut: 'Ctrl+A'),
      const MenuAction(id: 'copy_path', label: '复制当前路径', icon: Icons.link_outlined),
      const MenuAction(id: 'prop', label: '属性', icon: Icons.info_outline),
    ];

    showPolishedContextMenu(
      context: context,
      position: pos,
      items: items,
      width: 240,
    ).then((value) {
      if (value == null) return;
      switch (value) {
        case 'refresh':
          app.refresh();
        case 'up':
          app.goUp();
        case 'select_all':
          app.selectAll();
        case 'copy_path':
          Clipboard.setData(ClipboardData(text: app.currentPath));
          app.setStatus('已复制当前路径');
        case 'compress_here':
          app.setStatus('请选中文件后右键「添加到压缩文件」');
        case 'extract_here_dir':
        case 'extract_all_here':
          if (app.isBrowsingArchive) {
            app.extractSelected(destDir: app.currentPath);
          } else {
            app.setStatus('请选中压缩包后右键解压');
          }
        case 'prop':
          app.setStatus('目录：${app.currentPath}  共 ${app.visibleEntries.length} 项');
      }
    });
  }
}

class _Col {
  const _Col(this.title, this.width, this.sort, {this.leading = false});
  final String title;
  final double width;
  final SortColumn sort;
  final bool leading;
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({
    required this.col,
    required this.active,
    required this.order,
    required this.onTap,
  });

  final _Col col;
  final bool active;
  final SortOrder order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AppColors.colHeaderActive : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: col.width,
          height: 32,
          padding: EdgeInsets.symmetric(horizontal: col.leading ? 10 : 8),
          decoration: BoxDecoration(
            border: const Border(right: BorderSide(color: AppColors.border)),
            color: active ? AppColors.colHeaderActive : AppColors.colHeader,
          ),
          child: Row(
            children: [
              if (col.leading) ...[
                Icon(Icons.folder_copy_outlined,
                    size: 14,
                    color: active ? AppColors.accentBlue : AppColors.textMuted),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  col.title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: active ? AppColors.accentBlueDark : AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (active)
                Icon(
                  order == SortOrder.asc
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: AppColors.accentBlue,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FileRow extends StatelessWidget {
  const _FileRow({
    required this.entry,
    required this.selected,
    required this.columns,
    required this.isArchive,
    required this.onTap,
    required this.onDoubleTap,
    required this.onSecondaryTap,
  });

  final ArchiveEntry entry;
  final bool selected;
  final List<_Col> columns;
  final bool isArchive;
  final void Function(bool additive, bool range) onTap;
  final VoidCallback onDoubleTap;
  final void Function(Offset pos) onSecondaryTap;

  @override
  Widget build(BuildContext context) {
    final values = <String>[
      entry.name,
      entry.isFolder ? '' : formatBytes(entry.size),
      fileTypeLabel(entry.name, isDir: entry.isFolder),
      formatDateTime(entry.modified),
      if (isArchive) ...[
        entry.isFolder ? '' : formatBytes(entry.compressedSize ?? entry.size),
        entry.isFolder ? '' : formatCompression(entry.size, entry.compressedSize ?? entry.size),
        entry.isFolder ? '' : crc32Hex(entry.crc32),
      ],
      entry.fullPath,
      formatAttr(isDir: entry.isFolder),
    ];

    return Listener(
      onPointerDown: (e) {
        if (e.kind == PointerDeviceKind.mouse && e.buttons == kSecondaryMouseButton) {
          onSecondaryTap(e.position);
        }
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            final shift = HardwareKeyboard.instance.isShiftPressed;
            final ctrl = HardwareKeyboard.instance.isControlPressed ||
                HardwareKeyboard.instance.isMetaPressed;
            onTap(ctrl, shift);
          },
          onDoubleTap: onDoubleTap,
          onSecondaryTapUp: (details) => onSecondaryTap(details.globalPosition),
            child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOut,
            height: 28,
            decoration: BoxDecoration(
              color: selected ? AppColors.selection : Colors.transparent,
              border: Border(
                bottom: BorderSide(
                  color: AppColors.border.withValues(alpha: 0.7),
                ),
                left: selected
                    ? const BorderSide(color: AppColors.selectionBorder, width: 2)
                    : BorderSide.none,
              ),
            ),
            child: Row(
            children: [
              for (var i = 0; i < columns.length; i++)
                SizedBox(
                  width: columns[i].width,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: columns[i].leading ? 10 : 8),
                    child: columns[i].leading
                        ? Row(
                            children: [
                              Icon(
                                entry.icon,
                                size: 18,
                                color: entry.iconColor,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  values[i],
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: selected
                                        ? AppColors.accentBlueDark
                                        : AppColors.textPrimary,
                                    fontWeight:
                                        selected ? FontWeight.w600 : FontWeight.w400,
                                  ),
                                ),
                              ),
                              if (entry.encrypted)
                                const Padding(
                                  padding: EdgeInsets.only(left: 4),
                                  child: Icon(Icons.lock_outline,
                                      size: 12, color: AppColors.warning),
                                ),
                            ],
                          )
                        : Align(
                            alignment: columns[i].sort == SortColumn.size ||
                                    columns[i].sort == SortColumn.compressed ||
                                    columns[i].sort == SortColumn.rate ||
                                    columns[i].sort == SortColumn.crc ||
                                    columns[i].sort == SortColumn.attr
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Text(
                              values[i],
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: selected
                                    ? AppColors.accentBlueDark
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                  ),
                ),
              Expanded(child: Container()),
            ],
            ),
          ),
        ),
      ),
    );
  }
}
