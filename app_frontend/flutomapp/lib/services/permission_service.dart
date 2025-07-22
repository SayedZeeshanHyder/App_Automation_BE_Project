import 'package:permission_handler/permission_handler.dart';

class PermissionService{

  static Future<void> getAllPermissions() async {
    await Permission.storage.request();
    await Permission.manageExternalStorage.request();
  }

}