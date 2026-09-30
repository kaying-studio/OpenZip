import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/archive_entry.dart';
import '../../state/app_controller.dart';
import '../../theme/app_theme.dart';
import '../../utils/format_utils.dart';

/// 右侧预览面板：文件信息 + 图片/文本预览。
class PreviewPanel extends StatelessWidget {
  const PreviewPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppController>();
    return Container(
      width: 280,
      decoration: const BoxDecoration(
        color: Color(0xFFFAFBFC),
        border: Border(left: BorderSide(color: AppColors.border)),
      ),
      child: ValueListenableBuilder<Set<String>>(
        valueListenable: app.selectionListenable,
        builder: (context, selectedPaths, _) {
          if (app.selectedEntries.isEmpty) {
            return const _EmptyPreview();
          }
          final e = app.selectedEntries.first;
          return _PreviewBody(
            entry: e,
            app: app,
            multi: selectedPaths.length > 1,
            count: selectedPaths.length,
          );
        },
      ),
    );
  }
}

class _EmptyPreview extends StatelessWidget {
  const _EmptyPreview();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.touch_app_outlined, size: 36, color: AppColors.textMuted),
          SizedBox(height: 10),
          Text(
            '选择文件以预览',
            style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _PreviewBody extends StatelessWidget {
  const _PreviewBody({
    required this.entry,
    required this.app,
    required this.multi,
    required this.count,
  });

  final ArchiveEntry entry;
  final AppController app;
  final bool multi;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 头部图标 + 名称
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            children: [
              Icon(entry.icon, size: 48, color: entry.iconColor),
              const SizedBox(height: 8),
              Text(
                entry.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                fileTypeLabel(entry.name, isDir: entry.isFolder),
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.textSecondary,
                ),
              ),
              if (multi)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.zhihuBlueSoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '已选择 $count 项',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.zhihuBlueDark,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              if (!entry.isFolder) _previewArea(entry),
              const SizedBox(height: 8),
              _infoRow('大小', entry.isFolder ? '-' : formatBytes(entry.size)),
              if (!entry.isFolder) ...[
                _infoRow('压缩后', formatBytes(entry.compressedSize ?? entry.size)),
                _infoRow(
                  '压缩率',
                  formatCompression(entry.size, entry.compressedSize ?? entry.size),
                ),
                if (entry.crc32 != null)
                  _infoRow('CRC', crc32Hex(entry.crc32)),
              ],
              _infoRow('修改时间', formatDateTime(entry.modified)),
              _infoRow('属性', formatAttr(isDir: entry.isFolder)),
              const SizedBox(height: 8),
              const Text(
                '路径',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              SelectableText(
                entry.fullPath,
                style: const TextStyle(
                  fontSize: 11.5,
                  height: 1.4,
                  color: AppColors.textSecondary,
                ),
              ),
              if (app.isBrowsingArchive && app.openArchivePath != null) ...[
                const SizedBox(height: 10),
                const Text(
                  '所在压缩包',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  app.openArchivePath!,
                  style: const TextStyle(
                    fontSize: 11.5,
                    height: 1.4,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _previewArea(ArchiveEntry entry) {
    final isImage = [
      'png',
      'jpg',
      'jpeg',
      'gif',
      'webp',
      'bmp',
    ].contains(entry.ext);
    final isText = [
      'txt',
      'md',
      'log',
      'json',
      'xml',
      'yml',
      'yaml',
      'csv',
      'dart',
      'js',
      'ts',
      'html',
      'css',
      'py',
      'sh',
    ].contains(entry.ext);

    if (isImage && !app.isBrowsingArchive) {
      final file = File(entry.fullPath);
      if (file.existsSync() && entry.size < 30 * 1024 * 1024) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 160),
            color: const Color(0xFFF0F2F5),
            child: Image.file(
              file,
              fit: BoxFit.contain,
              cacheWidth: 480,
              errorBuilder: (_, error, stack) => const _PreviewFallback(
                icon: Icons.broken_image_outlined,
                label: '无法预览',
              ),
            ),
          ),
        );
      }
      return const _PreviewFallback(
        icon: Icons.image_outlined,
        label: '图片文件',
      );
    }

    if (isText && !app.isBrowsingArchive && entry.size < 64 * 1024) {
      try {
        final content = File(entry.fullPath).readAsStringSync();
        final preview = content.length > 400
            ? '${content.substring(0, 400)}…'
            : content;
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F8FA),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            preview,
            maxLines: 10,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              height: 1.45,
              color: AppColors.textSecondary,
              fontFamily: 'Menlo',
            ),
          ),
        );
      } catch (_) {
        return const _PreviewFallback(
          icon: Icons.description_outlined,
          label: '文本文件',
        );
      }
    }

    return _PreviewFallback(
      icon: entry.icon,
      label: entry.isFolder ? '文件夹' : '文件',
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 64,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11.5,
                color: AppColors.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(
                fontSize: 11.5,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewFallback extends StatelessWidget {
  const _PreviewFallback({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 28, color: AppColors.textMuted),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
