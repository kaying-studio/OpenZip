import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// 菜单项定义。
class MenuAction {
  const MenuAction({
    required this.id,
    required this.label,
    this.icon,
    this.shortcut,
    this.primary = false,
    this.danger = false,
    this.enabled = true,
    this.isDivider = false,
    this.section,
  });

  final String id;
  final String label;
  final IconData? icon;
  final String? shortcut;
  final bool primary;
  final bool danger;
  final bool enabled;
  final bool isDivider;
  final String? section;

  const MenuAction.divider({this.section})
      : id = '',
        label = '',
        icon = null,
        shortcut = null,
        primary = false,
        danger = false,
        enabled = false,
        isDivider = true;
}

/// Overlay 菜单：不走 Navigator 路由，悬停仅更新单行，避免整卡闪烁。
Future<String?> showPolishedContextMenu({
  required BuildContext context,
  required Offset position,
  required List<MenuAction> items,
  double width = 248,
}) {
  final overlay = Overlay.maybeOf(context);
  if (overlay == null) return Future.value(null);

  final done = Completer<String?>();
  late OverlayEntry entry;
  void close(String? id) {
    if (!done.isCompleted) {
      entry.remove();
      done.complete(id);
    }
  }

  entry = OverlayEntry(
    builder: (ctx) {
      final media = MediaQuery.of(ctx).size;
      double left = position.dx;
      double top = position.dy;
      final estimatedHeight = items.where((e) => !e.isDivider).length * 36.0 +
          items.where((e) => e.isDivider).length * 12.0 +
          16;
      if (left + width > media.width - 8) left = media.width - width - 8;
      if (top + estimatedHeight > media.height - 8) {
        top = (media.height - estimatedHeight - 8).clamp(8.0, media.height - 40);
      }

      return Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => close(null),
              onSecondaryTap: () => close(null),
            ),
          ),
          Positioned(
            left: left,
            top: top,
            child: RepaintBoundary(
              child: _MenuSurface(
                width: width,
                items: items,
                onSelected: close,
              ),
            ),
          ),
        ],
      );
    },
  );

  overlay.insert(entry);
  return done.future;
}

/// 静态菜单卡：高度/宽度固定，避免动画重建。
class _MenuSurface extends StatelessWidget {
  const _MenuSurface({
    required this.width,
    required this.items,
    required this.onSelected,
  });

  final double width;
  final List<MenuAction> items;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 12,
      shadowColor: const Color(0x28000000),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: width,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final item in items)
                if (item.isDivider)
                  _MenuDivider(section: item.section)
                else
                  _MenuRow(
                    item: item,
                    onSelected: onSelected,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuDivider extends StatelessWidget {
  const _MenuDivider({this.section});
  final String? section;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (section != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4, left: 8),
              child: Text(
                section!,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          Container(height: 1, color: AppColors.border),
        ],
      ),
    );
  }
}

/// 单行自管悬停，父级不 setState。
class _MenuRow extends StatefulWidget {
  const _MenuRow({
    required this.item,
    required this.onSelected,
  });

  final MenuAction item;
  final ValueChanged<String> onSelected;

  @override
  State<_MenuRow> createState() => _MenuRowState();
}

class _MenuRowState extends State<_MenuRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final enabled = item.enabled;

    final Color fg = !enabled
        ? AppColors.textMuted
        : item.danger
            ? AppColors.danger
            : item.primary
                ? AppColors.zhihuBlueDark
                : AppColors.textPrimary;

    final iconColor = !enabled
        ? AppColors.textMuted
        : item.danger
            ? AppColors.danger
            : item.primary
                ? AppColors.zhihuBlue
                : AppColors.textSecondary;

    return MouseRegion(
      onEnter: enabled ? (_) => setState(() => _hovered = true) : null,
      onExit: enabled ? (_) => setState(() => _hovered = false) : null,
      cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? () => widget.onSelected(item.id) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 70),
          curve: Curves.linear,
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: _hovered && enabled
                ? (item.danger
                    ? AppColors.danger.withValues(alpha: 0.08)
                    : AppColors.zhihuBlueSoft)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                child: item.icon != null
                    ? Icon(item.icon, size: 16, color: iconColor)
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.label,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  softWrap: false,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.15,
                    color: fg,
                    fontWeight:
                        item.primary ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              if (item.shortcut != null)
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Text(
                    item.shortcut!,
                    style: TextStyle(
                      fontSize: 11,
                      color: enabled
                          ? AppColors.textMuted
                          : AppColors.textMuted.withValues(alpha: 0.6),
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
