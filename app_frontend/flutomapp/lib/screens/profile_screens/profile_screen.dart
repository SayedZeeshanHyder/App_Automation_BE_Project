import 'package:flutomapp/services/shared_preferences_service.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(onPressed: ()async{
            await SharedPreferencesService.logOut();
          }, icon: Icon(Icons.logout,),),
        ],
      ),
    );
  }
}
