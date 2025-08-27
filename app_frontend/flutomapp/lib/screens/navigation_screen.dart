import 'package:flutomapp/services/shared_preferences_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'notification_screens/notification_screen.dart';

class NavigationScreen extends StatelessWidget {
  const NavigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(onPressed: (){
            Get.to(()=> const NotificationScreen(),transition: Transition.downToUp,);
          }, icon: Icon(Icons.notifications,),),
        ],
      ),
    );
  }
}
