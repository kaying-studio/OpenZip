import 'package:intl/intl.dart';

final NumberFormat _sizeFmt = NumberFormat('#,##0.##');
final NumberFormat _percentFmt = NumberFormat('0.#');

String formatBytes(int? bytes) {
  if (bytes == null) return '';
  if (bytes < 0) return '';
  if (bytes < 1024) return '$bytes B';
  const units = ['KB', 'MB', 'GB', 'TB'];
  var value = bytes / 1024.0;
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024.0;
    unit++;
  }
  return '${_sizeFmt.format(value)} ${units[unit]}';
}

String formatPercent(num ratio) {
  if (ratio.isNaN || ratio.isInfinite) return '';
  return '${_percentFmt.format(ratio)}%';
}

String formatDateTime(DateTime? time) {
  if (time == null) return '';
  return DateFormat('yyyy-MM-dd HH:mm').format(time);
}

String fileTypeLabel(String name, {bool isDir = false}) {
  if (isDir) return '文件夹';
  final dot = name.lastIndexOf('.');
  if (dot <= 0 || dot == name.length - 1) return '文件';
  final ext = name.substring(dot + 1).toUpperCase();
  switch (ext) {
    case 'ZIP':
    case '7Z':
    case 'RAR':
    case 'TAR':
    case 'GZ':
    case 'TGZ':
    case 'BZ2':
    case 'XZ':
    case 'ISO':
      return '$ext 压缩文件';
    case 'EXE':
    case 'MSI':
    case 'DMG':
    case 'APP':
      return '$ext 可执行文件';
    case 'TXT':
    case 'MD':
    case 'LOG':
      return '$ext 文本文件';
    case 'PDF':
      return 'PDF 文档';
    case 'DOC':
    case 'DOCX':
      return 'Word 文档';
    case 'XLS':
    case 'XLSX':
      return 'Excel 表格';
    case 'PPT':
    case 'PPTX':
      return 'PowerPoint 演示';
    case 'PNG':
    case 'JPG':
    case 'JPEG':
    case 'GIF':
    case 'BMP':
    case 'WEBP':
    case 'SVG':
      return '$ext 图片';
    case 'MP3':
    case 'WAV':
    case 'FLAC':
    case 'AAC':
    case 'M4A':
      return '$ext 音频';
    case 'MP4':
    case 'MOV':
    case 'AVI':
    case 'MKV':
    case 'WEBM':
      return '$ext 视频';
    case 'DART':
    case 'JS':
    case 'TS':
    case 'PY':
    case 'JAVA':
    case 'CPP':
    case 'C':
    case 'H':
    case 'CS':
    case 'GO':
    case 'RS':
    case 'HTML':
    case 'CSS':
    case 'JSON':
    case 'XML':
    case 'YAML':
    case 'YML':
    case 'SQL':
    case 'SH':
    case 'BAT':
      return '$ext 源代码';
    default:
      return '$ext 文件';
  }
}

String crc32Hex(int? crc) {
  if (crc == null) return '';
  return crc.toRadixString(16).toUpperCase().padLeft(8, '0');
}

String formatAttr({bool isDir = false}) => isDir ? 'D' : 'A';

String formatCompression(int? uncompressed, int? compressed) {
  if (uncompressed == null || compressed == null || uncompressed <= 0) return '';
  if (compressed <= 0) return '0%';
  final ratio = (1 - compressed / uncompressed) * 100;
  return formatPercent(ratio.clamp(-9999, 9999));
}

String compressionRatioLabel(int? uncompressed, int? compressed) {
  if (uncompressed == null || compressed == null) return '';
  if (uncompressed == 0) return '';
  return formatCompression(uncompressed, compressed);
}
