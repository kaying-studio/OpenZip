import 'package:flutter/material.dart';

/// 知乎蓝主色 + 干净白底；图标用渐变/阴影做立体感。
class AppColors {
  // 知乎蓝
  static const Color zhihuBlue = Color(0xFF0084FF);
  static const Color zhihuBlueDark = Color(0xFF0066CC);
  static const Color zhihuBlueLight = Color(0xFF339DFF);
  static const Color zhihuBlueSoft = Color(0xFFE8F3FF);
  static const Color zhihuBlueDeep = Color(0xFF004E99);

  // 别名（兼容现有引用）
  static const Color accentBlue = zhihuBlue;
  static const Color accentBlueDark = zhihuBlueDark;
  static const Color accentBlueSoft = zhihuBlueLight;
  static const Color accentBlueDeep = zhihuBlueDeep;
  static const Color accentGreen = Color(0xFF00A870);
  static const Color accentGreenDark = Color(0xFF00855A);

  static const Color brandGreen = Color(0xFF58BC23);
  static const Color brandOrange = Color(0xFFF08050);
  static const Color brandBlue = zhihuBlue;
  static const Color brandGold = Color(0xFFD97706);

  static const Color toolbarTop = Color(0xFFFFFFFF);
  static const Color toolbarMid = Color(0xFFFFFFFF);
  static const Color toolbarBottom = Color(0xFFFFFFFF);

  static const Color windowBg = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE8EAED);
  static const Color borderStrong = Color(0xFFD0D5DD);
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF4B5563);
  static const Color textMuted = Color(0xFF9CA3AF);

  static const Color selection = Color(0xFFE6F2FF);
  static const Color selectionBorder = zhihuBlue;
  static const Color hover = Color(0xFFF5F8FC);
  static const Color danger = Color(0xFFE5484D);
  static const Color warning = Color(0xFFF5A623);
  static const Color folder = Color(0xFFF5B942);

  static const Color sidebarBg = Color(0xFFFFFFFF);
  static const Color sidebarHeader = Color(0xFFFFFFFF);
  static const Color sidebarSelected = Color(0xFFE6F2FF);
  static const Color statusBg = Color(0xFFFFFFFF);

  static const Color colHeader = Color(0xFFFFFFFF);
  static const Color colHeaderActive = Color(0xFFE6F2FF);

  // 立体图标渐变
  static const List<Color> gradBlue = [Color(0xFF339DFF), Color(0xFF0084FF)];
  static const List<Color> gradGreen = [Color(0xFF2ED8A3), Color(0xFF00A870)];
  static const List<Color> gradRed = [Color(0xFFFF7A7E), Color(0xFFE5484D)];
  static const List<Color> gradPurple = [Color(0xFF8B7CFF), Color(0xFF5B5BD6)];
  static const List<Color> gradOrange = [Color(0xFFFFB35C), Color(0xFFF5A623)];
  static const List<Color> gradCyan = [Color(0xFF3DC8FF), Color(0xFF0099CC)];
  static const List<Color> gradGray = [Color(0xFF9AA4B2), Color(0xFF6B7280)];
}

class AppTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.zhihuBlue,
        primary: AppColors.zhihuBlue,
        secondary: AppColors.accentGreen,
        surface: AppColors.surface,
        error: AppColors.danger,
      ),
      fontFamily: 'PingFang SC',
      scaffoldBackgroundColor: AppColors.windowBg,
      splashFactory: NoSplash.splashFactory,
      hoverColor: AppColors.hover,
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      scrollbarTheme: const ScrollbarThemeData(
        thickness: WidgetStatePropertyAll(8),
        radius: Radius.circular(4),
        thumbColor: WidgetStatePropertyAll(Color(0xFFC5CAD3)),
      ),
      menuTheme: const MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(AppColors.surface),
          surfaceTintColor: WidgetStatePropertyAll(Colors.transparent),
          elevation: WidgetStatePropertyAll(4),
          padding: WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 4)),
        ),
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          side: BorderSide(color: AppColors.border),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          side: BorderSide(color: AppColors.border),
        ),
      ),
    );
  }
}

class BrandAssets {
  static const book128 = 'assets/brand/icon_128.png';
  static const book48 = 'assets/brand/icon_48.png';
  static const book32 = 'assets/brand/icon_32.png';
  static const book24 = 'assets/brand/icon_24.png';
  static const book16 = 'assets/brand/icon_16.png';
}
