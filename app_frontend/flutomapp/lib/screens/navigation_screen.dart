import 'package:flutomapp/screens/home_screens/home_screen.dart';
import 'package:flutomapp/screens/profile_screens/profile_screen.dart';
import 'package:flutomapp/services/shared_preferences_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'notification_screens/notification_screen.dart';

class NavigationScreen extends StatefulWidget {

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {

  List<Widget> pages = [
    HomeScreen(),
    Center(child: Text("Search Screen"),),
    ProfileScreen(),
  ];

  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(currentIndex: _selectedIndex,onTap: (index){
        setState(() {
          _selectedIndex = index;
        });
      },items: [
        BottomNavigationBarItem(icon: Icon(Icons.home,),label: "Home"),
        BottomNavigationBarItem(icon: Icon(Icons.search,),label: "Search"),
        BottomNavigationBarItem(icon: Icon(Icons.person,),label: "Profile"),
      ],),
    );
  }
}
