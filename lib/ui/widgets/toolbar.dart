import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_controller.dart';
import '../../theme/app_theme.dart';
import 'depth_icon.dart';

class ToolbarAction {
  const ToolbarAction({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.gradient,
    this.enabled = true,
    this.danger = false,
    this.tooltip,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final List<Color>? gradient;
  final bool enabled;
  final bool danger;
  final String? tooltip;
}

/// 工具栏：立体渐变图标 + 知乎蓝主按钮。
class AppToolbar extends StatelessWidget {
  const AppToolbar({
    super.key,
    required this.onNew,
    required this.onOpen,
    required this.onExtract,
    required this.onAdd,
    required this.onDelete,
    required this.onTest,
    required this.onComment,
    required this.onFind,
  });

  final VoidCallback onNew;
  final VoidCallback onOpen;
  final VoidCallback onExtract;
  final VoidCallback onAdd;
  final VoidCallback onDelete;
  final VoidCallback onTest;
  final VoidCallback onComment;
  final VoidCallback onFind;

  @override
  Widget build(BuildContext context) {
    // 只订阅必要字段，避免列表选中导致整条工具栏重建
    final isArchive = context.select<AppController, bool>((a) => a.isBrowsingArchive);
    final hasSelection =
        context.select<AppController, bool>((a) => a.selectedPaths.isNotEmpty);
    final canGoBack = context.select<AppController, bool>((a) => a.canGoBack);
    final canGoForward =
        context.select<AppController, bool>((a) => a.canGoForward);
    final addressText =
        context.select<AppController, String>((a) => a.addressText);
    final segments = context
        .select<AppController, List<String>>((a) => a.addressSegments.toList());
    final app = context.read<AppController>();

    return RepaintBoundary(
      child: Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 72,
            child: Align(
              alignment: Alignment.centerLeft,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const BrandMark(size: 38),
                    const SizedBox(width: 14),
                    const _VLine(),
                    const SizedBox(width: 12),
                    DepthActionButton(
                      label: '新建',
                      icon: Icons.note_add_outlined,
                      colors: AppColors.gradBlue,
                      onTap: onNew,
                      tooltip: '新建压缩文件 (Ctrl+N)',
                    ),
                    DepthActionButton(
                      label: '打开',
                      icon: Icons.folder_open_outlined,
                      colors: AppColors.gradCyan,
                      onTap: onOpen,
                      tooltip: '打开压缩文件 (Ctrl+O)',
                    ),
                    const SizedBox(width: 6),
                    const _VLine(),
                    const SizedBox(width: 6),
                    DepthActionButton(
                      label: '解压',
                      icon: Icons.unarchive_outlined,
                      colors: AppColors.gradGreen,
                      enabled: isArchive,
                      onTap: isArchive ? onExtract : () {},
                      tooltip: '解压到目录 (Ctrl+E)',
                    ),
                    DepthActionButton(
                      label: '添加',
                      icon: Icons.add_box_outlined,
                      colors: AppColors.gradOrange,
                      onTap: onAdd,
                    ),
                    DepthActionButton(
                      label: '删除',
                      icon: Icons.delete_outline_rounded,
                      colors: AppColors.gradRed,
                      enabled: hasSelection,
                      onTap: hasSelection ? onDelete : () {},
                      danger: true,
                    ),
                    DepthActionButton(
                      label: '测试',
                      icon: Icons.verified_outlined,
                      colors: AppColors.gradPurple,
                      enabled: isArchive,
                      onTap: isArchive ? onTest : () {},
                    ),
                    const SizedBox(width: 6),
                    const _VLine(),
                    const SizedBox(width: 6),
                    DepthActionButton(
                      label: '注释',
                      icon: Icons.notes_outlined,
                      colors: AppColors.gradBlue,
                      onTap: onComment,
                    ),
                    DepthActionButton(
                      label: '查找',
                      icon: Icons.search_rounded,
                      colors: AppColors.gradGray,
                      onTap: onFind,
                    ),
                    const SizedBox(width: 14),
                    _ModeText(isArchive: isArchive),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
            child: Row(
              children: [
                _NavIcon(
                  icon: Icons.arrow_back_rounded,
                  tooltip: '后退',
                  enabled: canGoBack,
                  onTap: app.goBack,
                ),
                const SizedBox(width: 6),
                _NavIcon(
                  icon: Icons.arrow_forward_rounded,
                  tooltip: '前进',
                  enabled: canGoForward,
                  onTap: app.goForward,
                ),
                const SizedBox(width: 6),
                _NavIcon(
                  icon: Icons.arrow_upward_rounded,
                  tooltip: '向上',
                  enabled: true,
                  onTap: app.goUp,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _BreadcrumbBar(
                    app: app,
                    addressText: addressText,
                    segments: segments,
                  ),
                ),
                const SizedBox(width: 8),
                _NavIcon(
                  icon: Icons.refresh_rounded,
                  tooltip: '刷新 (F5)',
                  enabled: true,
                  onTap: app.refresh,
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class _VLine extends StatelessWidget {
  const _VLine();
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 34, color: AppColors.border);
  }
}

class DepthActionButton extends StatelessWidget {
  const DepthActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.colors,
    required this.onTap,
    this.enabled = true,
    this.danger = false,
    this.tooltip,
  });

  final String label;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;
  final bool enabled;
  final bool danger;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final child = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DepthIcon(
            icon: icon,
            colors: colors,
            enabled: enabled,
            danger: danger,
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: enabled ? AppColors.textPrimary : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
    final wrapped = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(10),
        child: child,
      ),
    );
    return tooltip == null ? wrapped : Tooltip(message: tooltip!, child: wrapped);
  }
}

class _ModeText extends StatelessWidget {
  const _ModeText({required this.isArchive});
  final bool isArchive;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isArchive ? Icons.archive_outlined : Icons.folder_outlined,
          size: 14,
          color: AppColors.zhihuBlue,
        ),
        const SizedBox(width: 6),
        Text(
          isArchive ? '压缩包' : '文件管理',
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 32,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F8FC),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(
            icon,
            size: 17,
            color: enabled ? AppColors.zhihuBlueDark : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

/// 面包屑地址栏
class _BreadcrumbBar extends StatefulWidget {
  const _BreadcrumbBar({
    required this.app,
    required this.addressText,
    required this.segments,
  });

  final AppController app;
  final String addressText;
  final List<String> segments;

  @override
  State<_BreadcrumbBar> createState() => _BreadcrumbBarState();
}

class _BreadcrumbBarState extends State<_BreadcrumbBar> {
  bool _editing = false;
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.addressText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _BreadcrumbBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_editing) {
      _controller.text = widget.addressText;
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    final segments = widget.segments;
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8FC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: _editing
          ? Row(
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 10),
                  child: Icon(Icons.edit_location_alt_outlined,
                      size: 15, color: AppColors.zhihuBlue),
                ),
                Expanded(
                  child: Focus(
                    onFocusChange: (focused) {
                      if (!focused) {
                        setState(() => _editing = false);
                        _controller.text = widget.addressText;
                      }
                    },
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      style: const TextStyle(fontSize: 12.5),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      ),
                      onSubmitted: (v) async {
                        await app.openPathFromAddress(v);
                        if (mounted) setState(() => _editing = false);
                        _controller.text = widget.addressText;
                      },
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: () => setState(() => _editing = false),
                ),
              ],
            )
          : InkWell(
              onTap: () => setState(() => _editing = true),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    const Icon(Icons.folder_outlined,
                        size: 15, color: AppColors.zhihuBlue),
                    const SizedBox(width: 6),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (var i = 0;
                                i < segments.length;
                                i++) ...[
                              if (i > 0)
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 2),
                                  child: Icon(Icons.chevron_right,
                                      size: 14, color: AppColors.textMuted),
                                ),
                              _Crumb(
                                label: segments[i],
                                onOpen: () => app.navigateToSegment(i),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _Crumb extends StatelessWidget {
  const _Crumb({required this.label, required this.onOpen});
  final String label;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(3),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
