enum ProjectEntityType { file, directory }

class ProjectEntity {
  final String name;
  final ProjectEntityType type;
  final String? extension;
  final String relativePath;
  final int? size;
  final DateTime? modifiedDate;

  ProjectEntity({
    required this.name,
    required this.type,
    this.extension,
    required this.relativePath,
    this.size,
    this.modifiedDate,
  });

  static String? getExtension(String fileName) {
    final lastDot = fileName.lastIndexOf('.');
    if (lastDot != -1 && lastDot < fileName.length - 1) {
      return fileName.substring(lastDot + 1).toLowerCase();
    }
    return null;
  }

  String get formattedSize {
    if (size == null) return '';
    if (size! < 1024) return '${size!} B';
    if (size! < 1024 * 1024) return '${(size! / 1024).toStringAsFixed(1)} KB';
    if (size! < 1024 * 1024 * 1024) return '${(size! / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(size! / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
