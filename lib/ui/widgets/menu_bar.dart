import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../state/app_controller.dart';
import '../../theme/app_theme.dart';
import '../../utils/format_utils.dart';

/// 菜单栏：紧凑左对齐。
class AppMenuBar extends StatelessWidget {
  const AppMenuBar({
    super.key,
    required this.onNew,
    required this.onOpen,
    required this.onExtract,
    required this.onAdd,
    required this.onDelete,
    required this.onTest,
    required this.onAbout,
    required this.onComment,
    required this.onOptions,
  });

  final VoidCallback onNew;
  final VoidCallback onOpen;
  final VoidCallback onExtract;
  final VoidCallback onAdd;
  final VoidCallback onDelete;
  final VoidCallback onTest;
  final VoidCallback onAbout;
  final VoidCallback onComment;
  final VoidCallback onOptions;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppController>();
    return Container(
      height: 32,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(left: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _MenuButton(
                label: '文件(F)',
                items: [
                  _MenuItem('新建压缩文件...', Icons.note_add_outlined, onNew,
                      shortcut:
                          const SingleActivator(LogicalKeyboardKey.keyN, control: true)),
                  _MenuItem('打开压缩文件...', Icons.folder_open_outlined, onOpen,
                      shortcut:
                          const SingleActivator(LogicalKeyboardKey.keyO, control: true)),
                  const _MenuDivider(),
                  _MenuItem(
                      '添加到压缩文件...',
                      Icons.add_box_outlined,
                      onAdd,
                      shortcut: const SingleActivator(LogicalKeyboardKey.keyA,
                          control: true)),
                  _MenuItem(
                      '解压到指定文件夹...',
                      Icons.unarchive_outlined,
                      app.isBrowsingArchive ? onExtract : null,
                      shortcut: const SingleActivator(LogicalKeyboardKey.keyE,
                          control: true)),
                  _MenuItem('解压到当前文件夹', Icons.drive_folder_upload_outlined,
                      app.isBrowsingArchive ? onExtract : null),
                  const _MenuDivider(),
                  _MenuItem('测试压缩文件', Icons.verified_outlined,
                      app.isBrowsingArchive ? onTest : null,
                      shortcut: const SingleActivator(LogicalKeyboardKey.keyT,
                          control: true)),
                  _MenuItem('修复压缩文件', Icons.build_circle_outlined, onComment),
                  _MenuItem('压缩文件注释', Icons.notes_outlined, onComment),
                  const _MenuDivider(),
                  _MenuItem('删除', Icons.delete_outline,
                      app.selectedPaths.isNotEmpty ? onDelete : null,
                      shortcut: const SingleActivator(LogicalKeyboardKey.delete)),
                  _MenuItem('重命名', Icons.drive_file_rename_outline, () {
                    final e = app.firstSelected;
                    if (e != null) {
                      app.setStatus('请在列表右键「重命名」: ${e.name}');
                    }
                  }, shortcut: const SingleActivator(LogicalKeyboardKey.f2)),
                  _MenuItem('属性', Icons.info_outline, () {
                    final e = app.firstSelected;
                    if (e != null) {
                      app.setStatus(
                          '${e.name}  ${formatBytes(e.size)}  ${fileTypeLabel(e.name, isDir: e.isFolder)}');
                    }
                  }, shortcut: const SingleActivator(LogicalKeyboardKey.enter,
                      alt: true)),
                  const _MenuDivider(),
                  _MenuItem('退出', Icons.exit_to_app, () => SystemNavigator.pop(),
                      shortcut: const SingleActivator(LogicalKeyboardKey.keyQ,
                          control: true)),
                ],
              ),
              _MenuButton(
                label: '编辑(E)',
                items: [
                  _MenuItem('全选', Icons.select_all, app.selectAll,
                      shortcut: const SingleActivator(LogicalKeyboardKey.keyA,
                          control: true)),
                  _MenuItem('反选', Icons.flip, app.invertSelection),
                  _MenuItem('取消选择', Icons.block, app.clearSelection),
                ],
              ),
              _MenuButton(
                label: '视图(V)',
                items: [
                  _MenuItem(
                      app.showToolbar ? '隐藏工具栏' : '显示工具栏',
                      Icons.view_day_outlined,
                      app.toggleToolbar),
                  _MenuItem(
                      app.showStatusBar ? '隐藏状态栏' : '显示状态栏',
                      Icons.view_week_outlined,
                      app.toggleStatusBar),
                  _MenuItem(
                      app.folderTreeVisible ? '隐藏文件夹树' : '显示文件夹树',
                      Icons.account_tree_outlined,
                      app.toggleFolderTree),
                  const _MenuDivider(),
                  _MenuItem(
                      app.showDetailsView ? '大图标' : '详细信息',
                      Icons.view_list_outlined,
                      app.toggleDetailsView),
                  _MenuItem(
                      app.previewVisible ? '隐藏预览面板' : '显示预览面板',
                      Icons.preview_outlined,
                      app.togglePreview),
                  _MenuItem(
                      app.showHidden ? '不显示隐藏文件' : '显示隐藏文件',
                      Icons.visibility_outlined,
                      app.toggleHidden),
                  const _MenuDivider(),
                  _MenuItem('刷新', Icons.refresh, app.refresh,
                      shortcut: const SingleActivator(LogicalKeyboardKey.f5)),
                ],
              ),
              _MenuButton(
                label: '收藏(A)',
                items: [
                  for (final b in app.bookmarks)
                    _MenuItem(b.title, b.icon, () => app.browsePath(b.path)),
                  const _MenuDivider(),
                  ...app.recentArchives.take(6).map(
                        (p) => _MenuItem(
                          p.split(RegExp(r'[/\\]')).last,
                          Icons.archive_outlined,
                          () => app.openArchive(p),
                        ),
                      ),
                ],
              ),
              _MenuButton(
                label: '工具(T)',
                items: [
                  _MenuItem('测试当前压缩包', Icons.health_and_safety_outlined,
                      app.isBrowsingArchive ? onTest : null),
                  _MenuItem('压缩包注释', Icons.notes_outlined, onComment),
                  const _MenuDivider(),
                  _MenuItem('选项...', Icons.settings_outlined, onOptions),
                ],
              ),
              _MenuButton(
                label: '帮助(H)',
                items: [
                  _MenuItem('关于 OpenZip', Icons.info_outline, onAbout),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuItem {
  const _MenuItem(this.label, this.icon, this.onPressed, {this.shortcut});
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final SingleActivator? shortcut;
}

class _MenuDivider {
  const _MenuDivider();
}

class _MenuButton extends StatefulWidget {
  const _MenuButton({required this.label, required this.items});
  final String label;
  final List<Object> items;

  @override
  State<_MenuButton> createState() => _MenuButtonState();
}

class _MenuButtonState extends State<_MenuButton> {
  OverlayEntry? _entry;
  final _layerLink = LayerLink();
  bool _open = false;

  void _toggle() {
    if (_open) {
      _close();
    } else {
      _openMenu();
    }
  }

  void _openMenu() {
    _close();
    _open = true;
    final overlay = Overlay.of(context);
    final box = context.findRenderObject() as RenderBox;
    final pos = box.localToGlobal(Offset.zero);
    _entry = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _close,
              child: const ColoredBox(color: Colors.transparent),
            ),
          ),
          Positioned(
            left: pos.dx,
            top: pos.dy + box.size.height,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              child: Material(
                elevation: 4,
                shadowColor: Colors.black26,
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 180, maxWidth: 280),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final item in widget.items)
                        if (item is _MenuDivider) ...[
                          const Divider(height: 1, thickness: 1)
                        ] else if (item is _MenuItem) ...[
                          _MenuTile(item: item, onDismiss: _close),
                        ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    overlay.insert(_entry!);
  }

  void _close() {
    _entry?.remove();
    _entry = null;
    if (_open) {
      setState(() => _open = false);
    }
  }

  @override
  void dispose() {
    _entry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: InkWell(
        onTap: _toggle,
        onHover: (_) {
          if (_open) _openMenu();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: _open ? AppColors.selection : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 12.5,
              color: AppColors.textPrimary,
              fontWeight: _open ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.item, required this.onDismiss});
  final _MenuItem item;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final enabled = item.onPressed != null;
    return InkWell(
      onTap: enabled
          ? () {
              onDismiss();
              item.onPressed?.call();
            }
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(item.icon,
                size: 16,
                color: enabled ? AppColors.textSecondary : AppColors.textMuted),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(
                  fontSize: 13,
                  color: enabled ? AppColors.textPrimary : AppColors.textMuted,
                ),
              ),
            ),
            if (item.shortcut != null)
              Text(
                _shortcutLabel(item.shortcut!),
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
          ],
        ),
      ),
    );
  }

  String _shortcutLabel(SingleActivator s) {
    final parts = <String>[];
    if (s.control) parts.add('Ctrl');
    if (s.meta) parts.add('Cmd');
    if (s.shift) parts.add('Shift');
    if (s.alt) parts.add('Alt');
    final key = s.trigger.keyLabel;
    parts.add(key.length == 1 ? key.toUpperCase() : key);
    return parts.join('+');
  }
}
