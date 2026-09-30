import 'package:flutter/material.dart';

import '../../models/archive_entry.dart';
import '../../theme/app_theme.dart';

/// 立体渐变图标：圆角块 + 纵向渐变 + 内高光 + 外阴影。
class DepthIcon extends StatelessWidget {
  const DepthIcon({
    super.key,
    required this.icon,
    required this.colors,
    this.size = 38,
    this.iconSize = 22,
    this.enabled = true,
    this.danger = false,
  });

  final IconData icon;
  final List<Color> colors;
  final double size;
  final double iconSize;
  final bool enabled;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final base = enabled
        ? (danger ? const [Color(0xFFFF8A8E), Color(0xFFE5484D)] : colors)
        : const [Color(0xFFD7DCE3), Color(0xFFB7BEC8)];
    final top = base.first;
    final bottom = base.last;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.lerp(top, Colors.white, 0.18)!, bottom],
        ),
        boxShadow: [
          BoxShadow(
            color: bottom.withValues(alpha: enabled ? 0.35 : 0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.55),
          width: 1,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 顶部高光
          Positioned(
            left: size * 0.12,
            right: size * 0.12,
            top: size * 0.08,
            height: size * 0.34,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(size * 0.18),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.45),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: Icon(
              icon,
              size: iconSize,
              color: enabled ? Colors.white : Colors.white.withValues(alpha: 0.85),
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 扁平图标（侧栏/列表）：轻微渐变色 + 可选阴影。
class SoftIcon extends StatelessWidget {
  const SoftIcon({
    super.key,
    required this.icon,
    required this.color,
    this.size = 16,
    this.shadow = false,
  });

  final IconData icon;
  final Color color;
  final double size;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      size: size,
      color: color,
      shadows: shadow
          ? [
              Shadow(
                color: color.withValues(alpha: 0.35),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ]
          : null,
    );
  }
}

/// 品牌标：沿用书堆构图，尺寸与工具栏按钮一致。
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 38});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        'assets/brand/icon_128.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}

class AppColorsShadow {
  static const Color card = Color(0x14000000);
}

/// 文件列表图标：统一光学大小与风格。
class FileGlyph extends StatelessWidget {
  const FileGlyph({
    super.key,
    required this.kind,
    this.size = 18,
  });

  final FileGlyphKind kind;
  final double size;

  @override
  Widget build(BuildContext context) {
    final (icon, colors) = switch (kind) {
      FileGlyphKind.folder => (Icons.folder_rounded, AppColors.gradOrange),
      FileGlyphKind.archive => (Icons.archive_rounded, AppColors.gradPurple),
      FileGlyphKind.image => (Icons.image_rounded, AppColors.gradGreen),
      FileGlyphKind.video => (Icons.movie_rounded, AppColors.gradRed),
      FileGlyphKind.audio => (Icons.music_note_rounded, AppColors.gradOrange),
      FileGlyphKind.code => (Icons.code_rounded, AppColors.gradCyan),
      FileGlyphKind.doc => (Icons.description_rounded, AppColors.gradBlue),
      FileGlyphKind.app => (Icons.apps_rounded, AppColors.gradGray),
      FileGlyphKind.file => (Icons.insert_drive_file_rounded, AppColors.gradGray),
    };

    // 小圆角立体块，保证与工具栏图标同一视觉语言
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(colors.first, Colors.white, 0.12)!,
            colors.last,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: colors.last.withValues(alpha: 0.22),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Icon(icon, size: size * 0.62, color: Colors.white),
    );
  }
}
