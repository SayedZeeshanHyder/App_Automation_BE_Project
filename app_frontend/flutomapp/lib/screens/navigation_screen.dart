import 'dart:ui';

import 'package:flutomapp/screens/home_screens/home_screen.dart';
import 'package:flutomapp/screens/profile_screens/profile_screen.dart';
import 'package:flutomapp/screens/search_screens/search_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'build_screens/list_all_build_screen.dart';

class NavigationScreen extends StatefulWidget {
  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  // Professional Glassmorphism color scheme
  static const Color _primaryColor = Color(0xFF2D3FE7);
  static const Color _backgroundColor = Color(0xFFF8F9FD);
  static const Color _glassBackground = Color(0xFFFEFEFF);
  static const Color _inactiveColor = Color(0xFF9CA3AF);
  static const Color _glassBorder = Color(0xFFE1E7F0);

  List<Widget> pages = [
    HomeScreen(),
    BuildsScreen(),
    SearchScreen(),
    ProfileScreen(),
  ];

  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      extendBody: true,
      body: pages[_selectedIndex],
      bottomNavigationBar: _buildGlassBottomBar(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildGlassBottomBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            decoration: BoxDecoration(
              color: _glassBackground.withOpacity(0.75),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: _glassBorder.withOpacity(0.6),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.6),
                  blurRadius: 2,
                  offset: const Offset(-2, -2),
                ),
                BoxShadow(
                  color: _primaryColor.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(
                      icon: Icons.home_rounded,
                      label: 'Home',
                      index: 0,
                    ),
                    _buildNavItem(
                      icon: Icons.build_rounded,
                      label: "Builds",
                      index: 1,
                    ),
                    _buildNavItem(
                      icon: Icons.search_rounded,
                      label: 'Search',
                      index: 2,
                    ),
                    _buildNavItem(
                      icon: Icons.person_rounded,
                      label: 'Profile',
                      index: 3,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Glass effect icon container with enhanced blur
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOutCubic,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: isSelected ? 8 : 0,
                      sigmaY: isSelected ? 8 : 0,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOutCubic,
                      padding: EdgeInsets.all(isSelected ? 12 : 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _primaryColor.withOpacity(0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: isSelected
                            ? Border.all(
                          color: _primaryColor.withOpacity(0.25),
                          width: 1.5,
                        )
                            : null,
                        boxShadow: isSelected
                            ? [
                          BoxShadow(
                            color: _primaryColor.withOpacity(0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                          BoxShadow(
                            color: _primaryColor.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ]
                            : null,
                      ),
                      child: Icon(
                        icon,
                        color: isSelected ? _primaryColor : _inactiveColor,
                        size: isSelected ? 26 : 23,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              // Label with fade animation
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutCubic,
                style: TextStyle(
                  color: isSelected ? _primaryColor : _inactiveColor,
                  fontSize: isSelected ? 12 : 10.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: 0.3,
                  height: 1.2,
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 5),
              // Active indicator dot with glow
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutCubic,
                width: isSelected ? 6 : 0,
                height: isSelected ? 6 : 0,
                decoration: BoxDecoration(
                  color: _primaryColor,
                  shape: BoxShape.circle,
                  boxShadow: isSelected
                      ? [
                    BoxShadow(
                      color: _primaryColor.withOpacity(0.6),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: _primaryColor.withOpacity(0.3),
                      blurRadius: 16,
                      spreadRadius: 3,
                    ),
                  ]
                      : [],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}