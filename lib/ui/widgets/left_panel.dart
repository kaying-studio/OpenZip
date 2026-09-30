import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/archive_entry.dart';
import '../../state/app_controller.dart';
import '../../theme/app_theme.dart';

/// 干净左侧栏：白底、小标题、细线、轻量选中。
class LeftPanel extends StatelessWidget {
  const LeftPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppController>();
    return Container(
      width: 212,
      decoration: const BoxDecoration(
        color: AppColors.sidebarBg,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionLabel(title: '收藏夹'),
          Expanded(
            flex: 3,
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 2),
              children: [
                for (final b in app.bookmarks)
                  _NavTile(
                    icon: b.icon,
                    title: b.title,
                    selected: !app.isBrowsingArchive && app.currentPath == b.path,
                    onTap: () => app.browsePath(b.path),
                  ),
              ],
            ),
          ),
          const _SectionLabel(title: '最近打开'),
          if (app.recentArchives.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(36, 10, 12, 12),
              child: Text(
                '暂无记录',
                style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 120),
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 2),
                children: [
                  for (final p in app.recentArchives.take(6))
                    _NavTile(
                      icon: Icons.archive_outlined,
                      title: p.split(RegExp(r'[/\\]')).last,
                      selected: app.openArchivePath == p,
                      onTap: () => app.openArchive(p),
                      dense: true,
                    ),
                ],
              ),
            ),
          const _SectionLabel(title: '文件夹'),
          Expanded(
            flex: 4,
            child: app.isBrowsingArchive
                ? _ArchiveTree(archiveEntries: app.archiveResult?.entries ?? [])
                : _DiskTree(app: app),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: AppColors.textMuted,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.selected = false,
    this.dense = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool selected;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.sidebarSelected : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.fromLTRB(12, dense ? 5 : 7, 8, dense ? 5 : 7),
          child: Row(
            children: [
              if (selected)
                Container(
                  width: 3,
                  height: 16,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: AppColors.accentBlue,
                    borderRadius: BorderRadius.circular(2),
                  ),
                )
              else
                const SizedBox(width: 11),
              Icon(
                icon,
                size: dense ? 15 : 16,
                color: selected ? AppColors.accentBlue : AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: dense ? 12 : 12.5,
                    color: selected ? AppColors.accentBlueDark : AppColors.textPrimary,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
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

class _ArchiveTree extends StatelessWidget {
  const _ArchiveTree({required this.archiveEntries});
  final List<ArchiveEntry> archiveEntries;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppController>();
    final folders = archiveEntries
        .where((e) => e.isFolder)
        .map((e) => e.fullPath.replaceAll(RegExp(r'/$'), ''))
        .toSet()
        .toList()
      ..sort((a, b) => a.split('/').length.compareTo(b.split('/').length));

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 2),
      children: [
        _NavTile(
          icon: Icons.archive_outlined,
          title: app.archiveResult?.name ?? '压缩包',
          selected: app.archiveInnerPath.isEmpty,
          onTap: () => app.navigateInner(''),
        ),
        for (final folder in folders)
          if (folder.split('/').length <= 3)
            Padding(
              padding: EdgeInsets.only(left: 10.0 * (folder.split('/').length - 1)),
              child: _NavTile(
                icon: Icons.folder_outlined,
                title: folder.split('/').last,
                selected: app.archiveInnerPath == folder ||
                    app.archiveInnerPath.startsWith('$folder/'),
                onTap: () => app.navigateInner(folder),
                dense: true,
              ),
            ),
      ],
    );
  }
}

class _DiskTree extends StatelessWidget {
  const _DiskTree({required this.app});
  final AppController app;

  @override
  Widget build(BuildContext context) {
    final home = app.fs.homePath;
    final dirs = <String>[];
    try {
      for (final e in app.fs.listDirectory(home)) {
        if (e.isFolder) dirs.add(e.fullPath);
      }
    } catch (_) {}

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 2),
      children: [
        _NavTile(
          icon: Icons.home_outlined,
          title: '主目录',
          selected: app.currentPath == home,
          onTap: () => app.browsePath(home),
        ),
        for (final d in dirs.take(16))
          _NavTile(
            icon: Icons.folder_outlined,
            title: d.split(RegExp(r'[/\\]')).last,
            selected: app.currentPath == d,
            onTap: () => app.browsePath(d),
            dense: true,
          ),
      ],
    );
  }
}
