import 'package:flutter/material.dart';

import '../../services/archive_service.dart';
import '../../theme/app_theme.dart';

class CompressDialogResult {
  CompressDialogResult({
    required this.outputPath,
    required this.format,
    required this.level,
    this.password,
    this.includeBaseFolder = true,
    this.splitVolumeSize = 0,
  });

  final String outputPath;
  final ArchiveFormat format;
  final int level;
  final String? password;
  final bool includeBaseFolder;
  final int splitVolumeSize;
}

/// 新建 / 添加到压缩文件 对话框。
class CompressDialog extends StatefulWidget {
  const CompressDialog({
    super.key,
    required this.sourceNames,
    this.defaultName = '新建压缩文件',
    this.defaultDir = '',
  });

  final List<String> sourceNames;
  final String defaultName;
  final String defaultDir;

  @override
  State<CompressDialog> createState() => _CompressDialogState();
}

class _CompressDialogState extends State<CompressDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _dirCtrl;
  late final TextEditingController _pwdCtrl;
  ArchiveFormat _format = ArchiveFormat.zip;
  int _level = 6;
  bool _includeBase = true;
  bool _encrypt = false;
  bool _split = false;
  final _splitCtrl = TextEditingController(text: '100');

  static const _levelLabels = {
    0: '仅存储',
    1: '最快',
    3: '较快',
    6: '标准',
    9: '最好',
  };

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.defaultName);
    _dirCtrl = TextEditingController(text: widget.defaultDir);
    _pwdCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _dirCtrl.dispose();
    _pwdCtrl.dispose();
    _splitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.archive_rounded, color: AppColors.accentBlue),
          SizedBox(width: 10),
          Text('压缩文件', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('要压缩的项目'),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  widget.sourceNames.take(8).join('\n') +
                      (widget.sourceNames.length > 8
                          ? '\n... 等 ${widget.sourceNames.length} 项'
                          : ''),
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('压缩文件名'),
                        TextField(
                          controller: _nameCtrl,
                          style: const TextStyle(fontSize: 13),
                          decoration: const InputDecoration(
                            isDense: true,
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 140,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('格式'),
                        DropdownButtonFormField<ArchiveFormat>(
                          initialValue: _format,
                          decoration: const InputDecoration(
                            isDense: true,
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          ),
                          items: const [
                            DropdownMenuItem(value: ArchiveFormat.zip, child: Text('ZIP')),
                            DropdownMenuItem(value: ArchiveFormat.tarGz, child: Text('TAR.GZ')),
                            DropdownMenuItem(value: ArchiveFormat.tar, child: Text('TAR')),
                            DropdownMenuItem(value: ArchiveFormat.sevenZip, child: Text('7Z')),
                          ],
                          onChanged: (v) => setState(() => _format = v ?? ArchiveFormat.zip),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _label('压缩目录'),
              TextField(
                controller: _dirCtrl,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  isDense: true,
                  border: const OutlineInputBorder(),
                  hintText: '默认与源文件相同目录',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.folder_open, size: 18),
                    onPressed: () async {
                      // 由调用方注入目录选择更佳，这里保留占位
                    },
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _label('压缩级别'),
              Slider(
                value: _level.toDouble(),
                min: 0,
                max: 9,
                divisions: 9,
                label: _levelLabels[_level] ?? '$_level',
                onChanged: (v) => setState(() => _level = v.round()),
              ),
              Text(
                _levelLabels[_level] ?? '自定义 $_level',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                value: _includeBase,
                onChanged: (v) => setState(() => _includeBase = v ?? true),
                title: const Text('包含根文件夹', style: TextStyle(fontSize: 13)),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
              CheckboxListTile(
                value: _encrypt,
                onChanged: (v) => setState(() => _encrypt = v ?? false),
                title: const Text('设置密码', style: TextStyle(fontSize: 13)),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
              if (_encrypt)
                TextField(
                  controller: _pwdCtrl,
                  obscureText: true,
                  style: const TextStyle(fontSize: 13),
                  decoration: const InputDecoration(
                    isDense: true,
                    labelText: '密码',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  ),
                ),
              CheckboxListTile(
                value: _split,
                onChanged: (v) => setState(() => _split = v ?? false),
                title: const Text('分卷压缩', style: TextStyle(fontSize: 13)),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
              if (_split)
                TextField(
                  controller: _splitCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 13),
                  decoration: const InputDecoration(
                    isDense: true,
                    labelText: '分卷大小 (MB)',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  ),
                ),
            ],
          ),
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
            final name = _nameCtrl.text.trim();
            if (name.isEmpty) return;
            final ext = switch (_format) {
              ArchiveFormat.zip => 'zip',
              ArchiveFormat.tar => 'tar',
              ArchiveFormat.tarGz => 'tar.gz',
              ArchiveFormat.sevenZip => '7z',
              _ => 'zip',
            };
            final dir = _dirCtrl.text.trim();
            final fileName = name.contains('.') ? name : '$name.$ext';
            final out = dir.isEmpty ? fileName : '${dir.replaceAll(RegExp(r'[/\\]$'), '')}/$fileName';
            Navigator.pop(
              context,
              CompressDialogResult(
                outputPath: out,
                format: _format,
                level: _level,
                password: _encrypt && _pwdCtrl.text.isNotEmpty ? _pwdCtrl.text : null,
                includeBaseFolder: _includeBase,
                splitVolumeSize: _split ? (int.tryParse(_splitCtrl.text) ?? 100) * 1024 * 1024 : 0,
              ),
            );
          },
          child: const Text('立即压缩'),
        ),
      ],
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      );
}
