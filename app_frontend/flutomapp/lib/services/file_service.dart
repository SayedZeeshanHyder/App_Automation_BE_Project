import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive_io.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class FileService {
  static late Directory _externalDirectory;

  static Future<void> init() async {
    _externalDirectory = await getApplicationDocumentsDirectory();
  }

  static Future<void> downloadEncryptAndStoreZip({
    required String url,
    required String encryptedFileName,
    required String subDirectory,
  }) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) throw Exception('Download failed');
    final dirPath = p.join(_externalDirectory.path, subDirectory);
    final encryptedFilePath = p.join(dirPath, '$encryptedFileName.zhsp');
    await Directory(dirPath).create(recursive: true);
    final key = encrypt.Key.fromUtf8(dotenv.env['ENCRYPTION_KEY']!);
    final iv = encrypt.IV.fromLength(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    final encrypted = encrypter.encryptBytes(response.bodyBytes, iv: iv);
    final file = File(encryptedFilePath);
    await file.writeAsBytes(encrypted.bytes);
  }

  static Future<void> decryptAndUnzip({
    required String encryptedFileName,
    required String subDirectory,
    required String extractFolderName,
  }) async {
    final encryptedFilePath = p.join(_externalDirectory.path, subDirectory, '$encryptedFileName.zhsp');
    final encryptedBytes = await File(encryptedFilePath).readAsBytes();
    final key = encrypt.Key.fromUtf8(dotenv.env['ENCRYPTION_KEY']!);
    final iv = encrypt.IV.fromLength(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    final decrypted = encrypter.decryptBytes(encrypt.Encrypted(encryptedBytes), iv: iv);
    final zipFilePath = p.join(_externalDirectory.path, subDirectory, '$extractFolderName.zip');
    final zipFile = File(zipFilePath);
    await zipFile.writeAsBytes(decrypted);
    final archive = ZipDecoder().decodeBytes(decrypted);
    for (final file in archive) {
      final filePath = p.join(_externalDirectory.path, subDirectory, extractFolderName, file.name);
      if (file.isFile) {
        final outFile = File(filePath);
        await outFile.create(recursive: true);
        await outFile.writeAsBytes(file.content as List<int>);
      } else {
        await Directory(filePath).create(recursive: true);
      }
    }
  }

  static Future<void> reencryptFolderToZhsp({
    required String folderPath,
    required String encryptedFileName,
    required String subDirectory,
  }) async {
    final encoder = ZipFileEncoder();
    final zipPath = p.join(_externalDirectory.path, subDirectory, '$encryptedFileName.zip');
    encoder.create(zipPath);
    encoder.addDirectory(Directory(folderPath));
    encoder.close();
    final zipBytes = await File(zipPath).readAsBytes();
    final key = encrypt.Key.fromUtf8(dotenv.env['ENCRYPTION_KEY']!);
    final iv = encrypt.IV.fromLength(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    final encrypted = encrypter.encryptBytes(zipBytes, iv: iv);
    final encryptedPath = p.join(_externalDirectory.path, subDirectory, '$encryptedFileName.zhsp');
    await File(encryptedPath).writeAsBytes(encrypted.bytes);
    await File(zipPath).delete();
  }

  static Future<void> decryptAndSendZipToApi({
    required String encryptedFileName,
    required String subDirectory,
    required String apiUrl,
  }) async {
    final encryptedPath = p.join(_externalDirectory.path, subDirectory, '$encryptedFileName.zhsp');
    final encryptedBytes = await File(encryptedPath).readAsBytes();
    final key = encrypt.Key.fromUtf8(dotenv.env['ENCRYPTION_KEY']!);
    final iv = encrypt.IV.fromLength(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    final decrypted = encrypter.decryptBytes(encrypt.Encrypted(encryptedBytes), iv: iv);
    final zipPath = p.join(_externalDirectory.path, subDirectory, '$encryptedFileName.zip');
    final zipFile = File(zipPath);
    await zipFile.writeAsBytes(decrypted);
    final request = http.MultipartRequest('POST', Uri.parse(apiUrl));
    request.files.add(await http.MultipartFile.fromPath('file', zipPath));
    final response = await request.send();
    if (response.statusCode != 200) throw Exception('Failed to upload');
    await zipFile.delete();
  }
}
