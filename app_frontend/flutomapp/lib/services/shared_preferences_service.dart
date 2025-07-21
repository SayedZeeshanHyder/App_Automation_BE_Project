import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesService{

  static late SharedPreferences prefs;

  static Future<void> initializePrefs()async{
    prefs = await SharedPreferences.getInstance();
    if (kDebugMode) {
      print("Initialized SharedPreferences Successfully");
    }
  }

  static Future<void> storeAuthInfo(Map<String,dynamic> authInfo)async{
    await prefs.setString("token", authInfo['token']);
    await prefs.setString("userId", authInfo['userId']);
  }

  static Future<String> getToken()async{
    return prefs.getString("token") ?? "";
  }

  static Future<String> getUserId()async{
    return prefs.getString("userId") ?? "";
  }

}