import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive_io.dart';

import '../models/project_entity.dart';

class FileService {
  static Future<String> get _appFilesPath async {
    final directory = await getExternalStorageDirectory();
    final appDir = Directory(directory!.path);
    if (!await appDir.exists()) {
      await appDir.create(recursive: true);
    }
    return appDir.path;
  }

  static Future<void> saveZhspFile(String projectName, Uint8List zhspData) async {
    try {
      final path = await _appFilesPath;
      final file = File(p.join(path, '$projectName.zhsp'));
      await file.writeAsBytes(zhspData);
    } catch (e) {
      throw Exception('Failed to save file: $e');
    }
  }

  static Future<List<String>> getProjectFiles() async {
    try {
      final path = await _appFilesPath;
      final directory = Directory(path);

      if (!await directory.exists()) {
        return [];
      }

      final files = await directory
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.zhsp'))
          .cast<File>()
          .toList();

      return files
          .map((file) => p.basenameWithoutExtension(file.path))
          .toList();
    } catch (e) {
      throw Exception('Failed to get project files: $e');
    }
  }

  static Future<Uint8List> readZhspFile(String projectName) async {
    try {
      final path = await _appFilesPath;
      final file = File(p.join(path, '$projectName.zhsp'));
      return await file.readAsBytes();
    } catch (e) {
      throw Exception('Failed to read file: $e');
    }
  }

  static Future<List<String>> extractAndListFolders(Uint8List zipData) async {
    final tempParentDir = await getTemporaryDirectory();
    final extractDir = Directory(p.join(tempParentDir.path, 'extraction_${DateTime.now().millisecondsSinceEpoch}'));

    try {
      await extractDir.create(recursive: true);

      final archive = ZipDecoder().decodeBytes(zipData);
      extractArchiveToDisk(archive, extractDir.path);

       final firstLevelEntity = await extractDir.list().firstWhere(
            (entity) => entity is Directory,
        orElse: () => throw Exception("No root project directory found in archive."),
      );

      if (firstLevelEntity is! Directory) {
        throw Exception("Extracted content does not contain a root directory.");
      }
      final projectRootDir = firstLevelEntity;

      final folders = <String>[];
      await for (final entity in projectRootDir.list()) {
        if (entity is Directory) {
          folders.add(p.basename(entity.path));
        }
      }
      return folders;
    } catch (e) {
      throw Exception('Failed to extract and list folders: $e');
    } finally {
      if (await extractDir.exists()) {
        await extractDir.delete(recursive: true);
      }
    }
  }

  static Future<List<ProjectEntity>> getProjectRootContents(Uint8List zipData) async {
    final tempParentDir = await getTemporaryDirectory();
    final extractDir = Directory(p.join(tempParentDir.path, 'extraction_${DateTime.now().millisecondsSinceEpoch}'));

    try {
      await extractDir.create(recursive: true);

      final archive = ZipDecoder().decodeBytes(zipData);

      for (final file in archive) {
        final filename = file.name;
        final filePath = p.join(extractDir.path, filename);

        if (file.isFile) {
          final dir = Directory(p.dirname(filePath));
          if (!await dir.exists()) {
            await dir.create(recursive: true);
          }
          final data = file.content as List<int>;
          await File(filePath).writeAsBytes(data);
        } else {
          final directory = Directory(filePath);
          if (!await directory.exists()) {
            await directory.create(recursive: true);
          }
        }
      }
      final firstLevelEntity = await extractDir.list().firstWhere(
            (entity) => entity is Directory,
        orElse: () => throw Exception("No root project directory found in archive."),
      );

      final projectRootDir = firstLevelEntity as Directory;
      final List<ProjectEntity> contents = [];

      await for (final entity in projectRootDir.list()) {
        final name = p.basename(entity.path);

        if (entity is Directory) {
          contents.add(ProjectEntity(
            name: name,
            type: ProjectEntityType.directory,
            relativePath: name,
          ));
        } else if (entity is File) {
          final extension = ProjectEntity.getExtension(name);
          final stats = await entity.stat();
          contents.add(ProjectEntity(
            name: name,
            type: ProjectEntityType.file,
            extension: extension,
            relativePath: name,
            size: stats.size,
            modifiedDate: stats.modified,
          ));
        }
      }
      contents.sort((a, b) {
        if (a.type == b.type) {
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        }
        return a.type == ProjectEntityType.directory ? -1 : 1;
      });

      return contents;
    } catch (e) {
      print('❌ Error in getProjectRootContents: $e');
      throw Exception('Failed to get project contents: $e');
    } finally {
      if (await extractDir.exists()) {
        await extractDir.delete(recursive: true);
      }
    }
  }

  static Future<void> deleteProject(String projectName) async {
    try {
      final path = await _appFilesPath;
      final file = File(p.join(path, '$projectName.zhsp'));
      if (await file.exists()) {
        await file.delete();
      } else {
        print('Deletion skipped: Project file not found at ${file.path}');
      }
    } catch (e) {
      throw Exception('Failed to delete project "$projectName": $e');
    }
  }

  static Future<List<ProjectEntity>> getProjectFolderContents(
      Uint8List zipData,
      String folderPath,
      ) async {
    final tempParentDir = await getTemporaryDirectory();
    final extractDir = Directory(p.join(tempParentDir.path, 'extraction_${DateTime.now().millisecondsSinceEpoch}'));

    try {
      await extractDir.create(recursive: true);
      final archive = ZipDecoder().decodeBytes(zipData);

      // Manual extraction
      for (final file in archive) {
        final filename = file.name;
        final filePath = p.join(extractDir.path, filename);

        if (file.isFile) {
          final dir = Directory(p.dirname(filePath));
          if (!await dir.exists()) {
            await dir.create(recursive: true);
          }
          final data = file.content as List<int>;
          await File(filePath).writeAsBytes(data);
        } else {
          final directory = Directory(filePath);
          if (!await directory.exists()) {
            await directory.create(recursive: true);
          }
        }
      }

      final firstLevelEntity = await extractDir.list().firstWhere(
            (entity) => entity is Directory,
        orElse: () => throw Exception("No root project directory found in archive."),
      );

      final projectRootDir = firstLevelEntity as Directory;
      final targetDir = Directory(p.join(projectRootDir.path, folderPath));

      if (!await targetDir.exists()) {
        throw Exception('Folder not found: $folderPath');
      }

      return await _getDirectoryContents(targetDir.path, folderPath);
    } catch (e) {
      throw Exception('Failed to get folder contents: $e');
    } finally {
      if (await extractDir.exists()) {
        await extractDir.delete(recursive: true);
      }
    }
  }

  static Future<List<ProjectEntity>> _getDirectoryContents(String directoryPath, String relativePath) async {
    final directory = Directory(directoryPath);
    final List<ProjectEntity> contents = [];

    await for (final entity in directory.list()) {
      final name = p.basename(entity.path);
      final entityRelativePath = relativePath.isEmpty ? name : p.join(relativePath, name);

      if (entity is Directory) {
        contents.add(ProjectEntity(
          name: name,
          type: ProjectEntityType.directory,
          relativePath: entityRelativePath,
        ));
      } else if (entity is File) {
        final extension = ProjectEntity.getExtension(name);
        final stats = await entity.stat();
        contents.add(ProjectEntity(
          name: name,
          type: ProjectEntityType.file,
          extension: extension,
          relativePath: entityRelativePath,
          size: stats.size,
          modifiedDate: stats.modified,
        ));
      }
    }

    contents.sort((a, b) {
      if (a.type == b.type) {
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      }
      return a.type == ProjectEntityType.directory ? -1 : 1;
    });

    return contents;
  }

  static Future<String> getFileContent(Uint8List zipData, String filePath) async {
    final tempParentDir = await getTemporaryDirectory();
    final extractDir = Directory(p.join(tempParentDir.path, 'file_read_${DateTime.now().millisecondsSinceEpoch}'));

    try {
      await extractDir.create(recursive: true);
      final archive = ZipDecoder().decodeBytes(zipData);

      // Find the specific file in the archive
      final archiveFile = archive.firstWhere(
            (file) => file.name == filePath || file.name.endsWith('/$filePath'),
        orElse: () => throw Exception('File not found in archive: $filePath'),
      );

      if (!archiveFile.isFile) {
        throw Exception('Path is not a file: $filePath');
      }

      final content = archiveFile.content as List<int>;
      final contentString = String.fromCharCodes(content);

      return contentString;
    } catch (e) {
      throw Exception('Failed to read file content: $e');
    } finally {
      if (await extractDir.exists()) {
        await extractDir.delete(recursive: true);
      }
    }
  }

  static bool isTextFile(String? extension) {
    if (extension == null) return false;

    final textExtensions = {
      'dart', 'yaml', 'yml', 'json', 'xml', 'md', 'txt', 'gradle', 'kts',
      'properties', 'gitignore', 'lock', 'html', 'css', 'js', 'ts', 'java',
      'kt', 'swift', 'py', 'rb', 'php', 'cpp', 'c', 'h', 'hpp', 'sh',
      'bat', 'cmd', 'ps1', 'sql', 'ini', 'conf', 'config', 'log'
    };
    print('Checking if "$extension" is a text file: ${textExtensions.contains(extension.toLowerCase())}');
    return textExtensions.contains(extension.toLowerCase());
  }

}
