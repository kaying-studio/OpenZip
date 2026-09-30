import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_controller.dart';
import '../../theme/app_theme.dart';
import '../../utils/format_utils.dart';

/// 状态栏：选中变化只刷新选中统计区域。
class StatusBar extends StatelessWidget {
  const StatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppController>();
    return RepaintBoundary(
      child: ValueListenableBuilder<Set<String>>(
        valueListenable: app.selectionListenable,
        builder: (context, selectedPaths, _) {
          return Container(
            height: 30,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: const BoxDecoration(
              color: AppColors.statusBg,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Icon(
                  app.busy
                      ? Icons.hourglass_top_rounded
                      : (app.isBrowsingArchive
                          ? Icons.archive_outlined
                          : Icons.check_circle_outline_rounded),
                  size: 13,
                  color: app.busy
                      ? AppColors.warning
                      : (app.isBrowsingArchive
                          ? AppColors.accentBlue
                          : AppColors.accentGreen),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    app.busy
                        ? '${app.statusMessage ?? '处理中'}  ${(app.progress * 100).toStringAsFixed(0)}%'
                        : (app.statusMessage ?? '就绪'),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    selectedPaths.isEmpty
                        ? '${app.visibleEntries.length} 个项目'
                        : '已选择 ${selectedPaths.length} 个项目',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Container(width: 1, height: 12, color: AppColors.border),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    app.isBrowsingArchive
                        ? (app.archiveResult?.formatLabel ?? '-')
                        : '文件夹',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.accentBlueDark,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (selectedPaths.isNotEmpty) ...[
                  Container(width: 1, height: 12, color: AppColors.border),
                  Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Text(
                      '选中 ${formatBytes(
                        app.selectedEntries
                            .fold<int>(0, (a, e) => a + e.size),
                      )}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.accentBlueDark,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
