import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:openzip/services/archive_service.dart';

void main() {
  late Directory tempDir;
  late ArchiveService service;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('openzip_test_');
    service = ArchiveService();
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('compress and open zip', () async {
    final src = File('${tempDir.path}/hello.txt')
      ..writeAsStringSync('Hello OpenZip!');
    final out = '${tempDir.path}/out.zip';

    await service.compress(
      sourcePaths: [src.path],
      outputPath: out,
      options: const CompressOptions(format: ArchiveFormat.zip),
    );

    expect(File(out).existsSync(), isTrue);
    final result = await service.open(out);
    expect(result.format, ArchiveFormat.zip);
    expect(result.entries.any((e) => e.name.contains('hello')), isTrue);
  });

  test('extract zip contents', () async {
    final src = File('${tempDir.path}/a.txt')..writeAsStringSync('AAA');
    final out = '${tempDir.path}/pack.zip';
    await service.compress(sourcePaths: [src.path], outputPath: out);

    final dest = Directory('${tempDir.path}/extract')..createSync();
    await service.extract(
      archivePath: out,
      destDir: dest.path,
      options: const ExtractOptions(keepFullPath: true),
    );

    final extracted = File('${dest.path}/a.txt');
    expect(extracted.existsSync(), isTrue);
    expect(extracted.readAsStringSync(), 'AAA');
  });

  test('format detection', () {
    expect(ArchiveService.formatFromPath('a.zip'), ArchiveFormat.zip);
    expect(ArchiveService.formatFromPath('a.7z'), ArchiveFormat.sevenZip);
    expect(ArchiveService.isArchivePath('x/y.ZIP'), isTrue);
  });
}
