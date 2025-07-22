import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EncryptionService {
  static late final Encrypter _encrypter;

  static void initialize() {
    final key = Key.fromBase64(dotenv.env['ENCRYPTION_KEY']!);
    _encrypter = Encrypter(AES(key));
  }

  static Uint8List encryptZipFile(Uint8List zipData) {
    try {
      final iv = IV.fromSecureRandom(16);
      final encrypted = _encrypter.encryptBytes(zipData, iv: iv);
      final result = Uint8List(16 + encrypted.bytes.length);
      result.setRange(0, 16, iv.bytes);
      result.setRange(16, result.length, encrypted.bytes);

      return result;
    } catch (e) {
      throw Exception('Encryption failed: $e');
    }
  }

  static Uint8List decryptZhspFile(Uint8List zhspData) {
    try {
      final iv = IV(zhspData.sublist(0, 16));
      final encryptedData = zhspData.sublist(16);
      final encrypted = Encrypted(encryptedData);
      final decrypted = _encrypter.decryptBytes(encrypted, iv: iv);

      return Uint8List.fromList(decrypted);
    } catch (e) {
      throw Exception('Decryption failed: $e');
    }
  }
}
