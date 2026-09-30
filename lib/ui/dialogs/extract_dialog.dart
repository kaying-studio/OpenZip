import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../widgets/depth_icon.dart';

class ExtractDialogResult {
  ExtractDialogResult({
    required this.destDir,
    required this.keepFullPath,
    required this.overwrite,
  });

  final String destDir;
  final bool keepFullPath;
  final bool overwrite;
}

/// 解压文件对话框。
class ExtractDialog extends StatefulWidget {
  const ExtractDialog({
    super.key,
    required this.archiveName,
    required this.defaultDest,
    this.selectedCount = 0,
  });

  final String archiveName;
  final String defaultDest;
  final int selectedCount;

  @override
  State<ExtractDialog> createState() => _ExtractDialogState();
}

class _ExtractDialogState extends State<ExtractDialog> {
  late final TextEditingController _destCtrl;
  bool _keepFullPath = true;
  bool _overwrite = true;

  @override
  void initState() {
    super.initState();
    _destCtrl = TextEditingController(text: widget.defaultDest);
  }

  @override
  void dispose() {
    _destCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.unarchive_rounded, color: AppColors.accentGreen),
          SizedBox(width: 10),
          Text('解压文件', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '压缩包：${widget.archiveName}',
              style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            ),
            if (widget.selectedCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '将解压选中的 ${widget.selectedCount} 个项目',
                  style: const TextStyle(fontSize: 12, color: AppColors.accentBlue),
                ),
              ),
            const SizedBox(height: 14),
            const Text(
              '目标路径',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _destCtrl,
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              ),
            ),
            const SizedBox(height: 10),
            CheckboxListTile(
              value: _keepFullPath,
              onChanged: (v) => setState(() => _keepFullPath = v ?? true),
              title: const Text('保留完整路径', style: TextStyle(fontSize: 13)),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
            CheckboxListTile(
              value: _overwrite,
              onChanged: (v) => setState(() => _overwrite = v ?? true),
              title: const Text('覆盖已存在的文件', style: TextStyle(fontSize: 13)),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accentGreen,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            final dest = _destCtrl.text.trim();
            if (dest.isEmpty) return;
            Navigator.pop(
              context,
              ExtractDialogResult(
                destDir: dest,
                keepFullPath: _keepFullPath,
                overwrite: _overwrite,
              ),
            );
          },
          child: const Text('立即解压'),
        ),
      ],
    );
  }
}

/// 简单查找对话框（筛选当前列表）。
class FindDialog extends StatelessWidget {
  const FindDialog({super.key, required this.onSearch});

  final void Function(String keyword) onSearch;

  @override
  Widget build(BuildContext context) {
    final ctrl = TextEditingController();
    return AlertDialog(
      title: const Text('查找', style: TextStyle(fontSize: 16)),
      content: SizedBox(
        width: 360,
        child: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: '文件名关键字',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          onSubmitted: (v) {
            Navigator.pop(context);
            onSearch(v);
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context);
            onSearch(ctrl.text);
          },
          child: const Text('查找'),
        ),
      ],
    );
  }
}

/// 注释对话框。
class CommentDialog extends StatelessWidget {
  const CommentDialog({super.key, required this.initial});

  final String initial;

  @override
  Widget build(BuildContext context) {
    final ctrl = TextEditingController(text: initial);
    return AlertDialog(
      title: const Text('压缩包注释'),
      content: SizedBox(
        width: 420,
        height: 160,
        child: TextField(
          controller: ctrl,
          maxLines: 6,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: '输入压缩包注释...',
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('关闭')),
        FilledButton(
          onPressed: () => Navigator.pop(context, ctrl.text),
          child: const Text('保存注释'),
        ),
      ],
    );
  }
}

/// 关于对话框。
class AboutAppDialog extends StatelessWidget {
  const AboutAppDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          BrandMark(size: 36),
          SizedBox(width: 12),
          Text('OpenZip'),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '多平台压缩 / 解压缩工具',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            const Text(
              '支持 ZIP / TAR / TAR.GZ（内置），7Z / RAR（系统解压器）。\n'
              '基于 Flutter，可运行于 Windows / macOS / Linux / Web。',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.55,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            const _InfoRow(label: '作者', value: 'kayingai.com'),
            const SizedBox(height: 6),
            const _InfoRow(
              label: '联系我们',
              value: 'service@kayingai.com',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _swatch(AppColors.accentBlueDeep),
                _swatch(AppColors.accentBlue),
                _swatch(AppColors.accentBlueSoft),
                _swatch(AppColors.accentGreen),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              '版本 0.1.0',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
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

  Widget _swatch(Color c) => Container(
        width: 28,
        height: 10,
        margin: const EdgeInsets.only(right: 6),
        decoration: BoxDecoration(
          color: c,
          borderRadius: BorderRadius.circular(3),
        ),
      );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 64,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: SelectableText(
            value,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
