import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/auth_screens/sign_up_screen.dart';

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
    debugPrint("Stored Auth Info: Token = ${authInfo['token']} and UserId = ${authInfo['userId']}");
  }

  static Future<void> storeOrganizationInfo(String organizationId)async{
    await prefs.setString("organizationId", organizationId);
  }

  static String getToken(){
    return prefs.getString("token") ?? "";
  }

  static String getUserId(){
    return prefs.getString("userId") ?? "";
  }

  static bool isOnboardingVisited(){
    return prefs.getBool("onboardingVisited") ?? false;
  }

  static Future<void> visitOnboarding()async {
    await prefs.setBool("onboardingVisited", true);
  }

  static Future<void> logOut()async{
    await prefs.remove("token");
    await prefs.remove("userId");
    await prefs.remove("organizationId");
    Get.offAll(()=> SignUpScreen(),transition: Transition.leftToRight);
  }

}