import 'dart:ui';

import 'package:flutomapp/bindings/dynamic_rendering_binding.dart';
import 'package:flutomapp/screens/home_screens/prompt_screen.dart';
import 'package:flutomapp/screens/home_screens/view_developer_code.dart';
import 'package:flutomapp/screens/rendering_screens/dynamic_rendering.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../controller/dynamic_render_prompt_controller.dart';
import '../../models/project_model.dart';
import '../../services/build_service.dart';
import 'build_confirmation_dialog.dart';

class ProjectDetailsScreen extends StatelessWidget {
  final Project project;
  const ProjectDetailsScreen({super.key, required this.project});

  // Professional Glassmorphism color scheme
  static const Color _primaryColor = Color(0xFF2D3FE7);
  static const Color _accentColor = Color(0xFF6C5DD3);
  static const Color _backgroundColor = Color(0xFFF8F9FD);
  static const Color _primaryTextColor = Color(0xFF0F1419);
  static const Color _secondaryTextColor = Color(0xFF536471);
  static const Color _errorColor = Color(0xFFEF4444);
  static const Color _glassBackground = Color(0xFFFEFEFF);
  static const Color _successColor = Color(0xFF10B981);
  static const Color _warningColor = Color(0xFFF59E0B);
  static const Color _glassBorder = Color(0xFFE1E7F0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: _buildGlassFloatingButton(),
      backgroundColor: _backgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(90),
        child: _buildGlassAppBar(context),
      ),
      body: Stack(
        children: [
          // Background glassmorphism circles
          _buildBackgroundCircles(),

          // Main content
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
            children: [
              _buildProjectOverviewCard(),
              const SizedBox(height: 20),
              _buildScreensSection(context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundCircles() {
    return Stack(
      children: [
        // Large top-right circle with glow
        Positioned(
          top: -120,
          right: -120,
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _primaryColor.withOpacity(0.06),
              border: Border.all(
                color: _primaryColor.withOpacity(0.12),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: _primaryColor.withOpacity(0.08),
                  blurRadius: 80,
                  spreadRadius: 20,
                ),
              ],
            ),
          ),
        ),

        // Medium left circle
        Positioned(
          top: 280,
          left: -100,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _accentColor.withOpacity(0.05),
              border: Border.all(
                color: _accentColor.withOpacity(0.1),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: _accentColor.withOpacity(0.06),
                  blurRadius: 60,
                  spreadRadius: 15,
                ),
              ],
            ),
          ),
        ),

        // Small floating circle with subtle glow
        Positioned(
          top: 180,
          right: 60,
          child: Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _primaryColor.withOpacity(0.04),
              border: Border.all(
                color: _primaryColor.withOpacity(0.08),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: _primaryColor.withOpacity(0.05),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
          ),
        ),

        // Bottom-right large circle with strong glow
        Positioned(
          bottom: -150,
          right: -100,
          child: Container(
            width: 380,
            height: 380,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _accentColor.withOpacity(0.06),
              border: Border.all(
                color: _accentColor.withOpacity(0.12),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: _accentColor.withOpacity(0.08),
                  blurRadius: 90,
                  spreadRadius: 25,
                ),
              ],
            ),
          ),
        ),

        // Small center-left circle
        Positioned(
          top: 500,
          left: 30,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _primaryColor.withOpacity(0.04),
              border: Border.all(
                color: _primaryColor.withOpacity(0.08),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: _primaryColor.withOpacity(0.05),
                  blurRadius: 35,
                  spreadRadius: 8,
                ),
              ],
            ),
          ),
        ),

        // Tiny accent circle
        Positioned(
          bottom: 300,
          right: 40,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _successColor.withOpacity(0.04),
              border: Border.all(
                color: _successColor.withOpacity(0.08),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: _successColor.withOpacity(0.05),
                  blurRadius: 30,
                  spreadRadius: 8,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGlassAppBar(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: _glassBackground.withOpacity(0.7),
            border: Border(
              bottom: BorderSide(
                color: _glassBorder.withOpacity(0.3),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  _buildGlassBackButton(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          project.projectName,
                          style: const TextStyle(
                            color: _primaryTextColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                            letterSpacing: -0.3,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${project.listOfScreens.length} screen${project.listOfScreens.length != 1 ? 's' : ''}',
                          style: const TextStyle(
                            color: _secondaryTextColor,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildGlassBuildButton(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassBackButton() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _glassBackground.withOpacity(0.5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _glassBorder.withOpacity(0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _primaryTextColor.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Get.back(),
              borderRadius: BorderRadius.circular(14),
              child: const Center(
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: _primaryTextColor,
                  size: 22,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassBuildButton(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: _primaryColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _primaryColor.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _primaryColor.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showBuildDialog(context),
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.build_rounded, color: _primaryColor, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Build',
                      style: TextStyle(
                        color: _primaryColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        letterSpacing: 0.2,
                      ),
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

  Widget _buildGlassFloatingButton() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            color: _primaryColor.withOpacity(0.95),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _primaryColor.withOpacity(0.4),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: _primaryColor.withOpacity(0.2),
                blurRadius: 48,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Get.to(() => PromptScreen(projectId: project.id));
              },
              borderRadius: BorderRadius.circular(18),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.add_rounded, color: Colors.white, size: 22),
                    SizedBox(width: 10),
                    Text(
                      "New Screen",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        letterSpacing: 0.3,
                      ),
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

  Widget _buildProjectOverviewCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: _glassBackground.withOpacity(0.7),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _glassBorder.withOpacity(0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _primaryTextColor.withOpacity(0.06),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.6),
                blurRadius: 2,
                offset: const Offset(-2, -2),
              ),
              BoxShadow(
                color: _primaryColor.withOpacity(0.05),
                blurRadius: 40,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _primaryColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _primaryColor.withOpacity(0.2),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.folder_rounded,
                        color: _primaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text(
                        'Project Overview',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: _primaryTextColor,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _glassBorder.withOpacity(0),
                        _glassBorder.withOpacity(0.5),
                        _glassBorder.withOpacity(0),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildInfoRow(
                  Icons.business_outlined,
                  'Organisation',
                  project.organisationId,
                  _accentColor,
                ),
                const SizedBox(height: 14),
                _buildInfoRow(
                  Icons.calendar_today_rounded,
                  'Created',
                  DateFormat.yMMMd().format(project.createdAt),
                  _successColor,
                ),
                const SizedBox(height: 14),
                _buildInfoRow(
                  Icons.build_circle_rounded,
                  'Last Build',
                  DateFormat.yMMMd().add_jm().format(project.lastBuildAt),
                  _warningColor,
                ),
                const SizedBox(height: 14),
                _buildFirebaseStatusRow(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScreensSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _primaryColor.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.layers_rounded,
                  color: _primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Screens',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _primaryTextColor,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (project.listOfScreens.isEmpty)
          _buildEmptyState()
        else
          ...project.listOfScreens.map((screen) => _buildScreenCard(context, screen)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: _glassBackground.withOpacity(0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _glassBorder.withOpacity(0.5),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _primaryColor.withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.phone_android_rounded,
                  size: 48,
                  color: _primaryColor.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'No screens yet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _primaryTextColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add your first screen to get started',
                style: TextStyle(
                  fontSize: 14,
                  color: _secondaryTextColor.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScreenCard(BuildContext context, ProjectScreen screen) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: _glassBackground.withOpacity(0.65),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _glassBorder.withOpacity(0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: _primaryTextColor.withOpacity(0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.6),
                  blurRadius: 1,
                  offset: const Offset(-1, -1),
                ),
              ],
            ),
            child: Theme(
              data: ThemeData(
                dividerColor: Colors.transparent,
                splashColor: _primaryColor.withOpacity(0.05),
                highlightColor: _primaryColor.withOpacity(0.03),
              ),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                childrenPadding: const EdgeInsets.only(bottom: 12),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _primaryColor.withOpacity(0.2),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.phone_android_rounded,
                    color: _primaryColor,
                    size: 20,
                  ),
                ),
                title: Text(
                  screen.screenName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _primaryTextColor,
                    fontSize: 16,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    screen.screenPrompt,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _secondaryTextColor.withOpacity(0.8),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
                collapsedIconColor: _secondaryTextColor,
                iconColor: _primaryColor,
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _backgroundColor.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _glassBorder.withOpacity(0.4),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              _buildActionListItem(
                                context,
                                icon: Icons.visibility_rounded,
                                label: 'View Screen',
                                color: _primaryColor,
                                onTap: () {
                                  Get.to(
                                        () => const DynamicRenderingScreen(),
                                    binding: DynamicRenderingBinding(),
                                    arguments: {
                                      'widgetData': screen.screenUI,
                                      'mode': ScreenMode.view,
                                      'project': project,
                                      'screen': screen,
                                    },
                                  );
                                },
                              ),
                              _buildActionListItem(
                                context,
                                icon: Icons.code_rounded,
                                label: 'View Code',
                                color: _accentColor,
                                onTap: () {
                                  Get.to(() => CodeViewerScreen(
                                      code: screen.screenCode,
                                      title: screen.screenName));
                                },
                              ),
                              _buildActionListItem(
                                context,
                                icon: Icons.edit_rounded,
                                label: 'Update Screen',
                                color: _successColor,
                                onTap: () {
                                  Get.to(
                                        () => const DynamicRenderingScreen(),
                                    binding: DynamicRenderingBinding(),
                                    arguments: {
                                      'widgetData': screen.screenUI,
                                      'mode': ScreenMode.update,
                                      'project': project,
                                      'screen': screen,
                                    },
                                  );
                                },
                              ),
                              _buildActionListItem(
                                context,
                                icon: Icons.delete_rounded,
                                label: 'Delete Screen',
                                color: _errorColor,
                                onTap: () {
                                  // TODO: Implement delete functionality
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionListItem(
      BuildContext context, {
        required IconData icon,
        required String label,
        required VoidCallback onTap,
        required Color color,
      }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: color.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: color,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: color.withOpacity(0.4),
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
      IconData icon, String label, String value, Color iconColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: iconColor.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Row(
            children: [
              Text(
                '$label: ',
                style: TextStyle(
                  color: _secondaryTextColor.withOpacity(0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    color: _primaryTextColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFirebaseStatusRow() {
    final bool isConfigured = project.firebaseConfigured;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _warningColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _warningColor.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Icon(
            Icons.cloud_rounded,
            color: _warningColor,
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          'Firebase',
          style: TextStyle(
            color: _secondaryTextColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: isConfigured
                      ? _successColor.withOpacity(0.12)
                      : _errorColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isConfigured
                        ? _successColor.withOpacity(0.3)
                        : _errorColor.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isConfigured
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded,
                      color: isConfigured ? _successColor : _errorColor,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        isConfigured ? 'Configured' : 'Not Configured',
                        style: TextStyle(
                          color: isConfigured ? _successColor : _errorColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showBuildDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) => BuildConfirmationDialog(
        onConfirmed: () => _handleBuildProject(context),
      ),
    );
  }

  Future<void> _handleBuildProject(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) => _buildLoadingDialog(),
    );

    try {
      final response = await BuildService.buildProject(
        projectId: project.id,
        instructions: '',
        initialScreenIndex: 0,
      );

      if (context.mounted) {
        Navigator.of(context).pop();
        _showSuccessDialog(context, response);
      }
    } on BuildException catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        _showErrorDialog(context, e.message);
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        _showErrorDialog(context, 'An unexpected error occurred');
      }
    }
  }

  Widget _buildLoadingDialog() {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(36),
            decoration: BoxDecoration(
              color: _glassBackground.withOpacity(0.8),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: _glassBorder.withOpacity(0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: _primaryTextColor.withOpacity(0.1),
                  blurRadius: 40,
                  offset: const Offset(0, 16),
                ),
                BoxShadow(
                  color: _primaryColor.withOpacity(0.1),
                  blurRadius: 60,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _primaryColor.withOpacity(0.2),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _primaryColor.withOpacity(0.2),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      strokeWidth: 3.5,
                      valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Building Project',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: _primaryTextColor,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Please wait while we compile your project...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: _secondaryTextColor.withOpacity(0.9),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, dynamic response) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: _glassBackground.withOpacity(0.8),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: _glassBorder.withOpacity(0.5),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _successColor.withOpacity(0.15),
                    blurRadius: 50,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _successColor.withOpacity(0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _successColor.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: _successColor,
                      size: 56,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Build Successful!',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: _primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your project has been built successfully',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: _secondaryTextColor.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildDialogButton(
                    'Close',
                        () => Navigator.of(context).pop(),
                    _successColor,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: _glassBackground.withOpacity(0.8),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: _glassBorder.withOpacity(0.5),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _errorColor.withOpacity(0.15),
                    blurRadius: 50,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _errorColor.withOpacity(0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _errorColor.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.error_rounded,
                      color: _errorColor,
                      size: 56,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Build Failed',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: _primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: _secondaryTextColor.withOpacity(0.9),
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 24),
                  _buildDialogButton(
                    'Close',
                        () => Navigator.of(context).pop(),
                    _errorColor,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDialogButton(String label, VoidCallback onTap, Color color) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}