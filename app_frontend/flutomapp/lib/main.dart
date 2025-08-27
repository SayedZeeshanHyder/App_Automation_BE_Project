
import 'package:flutomapp/screens/auth_screens/on_boarding_screen.dart';
import 'package:flutomapp/screens/auth_screens/sign_up_screen.dart';
import 'package:flutomapp/screens/navigation_screen.dart';
import 'package:flutomapp/services/permission_service.dart';
import 'package:flutomapp/services/shared_preferences_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';

void main() async {

  await dotenv.load(fileName: ".env");
  await PermissionService.getAllPermissions();
  await SharedPreferencesService.initializePrefs();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    String authToken = SharedPreferencesService.getToken();
    bool isOnboardingVisited = SharedPreferencesService.isOnboardingVisited();
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: authToken.isEmpty ? isOnboardingVisited ? SignUpScreen() :OnBoardingScreen() : NavigationScreen()
    );
  }
}