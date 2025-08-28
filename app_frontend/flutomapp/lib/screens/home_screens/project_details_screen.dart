import 'package:flutomapp/bindings/dynamic_rendering_binding.dart';
import 'package:flutomapp/screens/home_screens/prompt_screen.dart';
import 'package:flutomapp/screens/home_screens/view_developer_code.dart';
import 'package:flutomapp/screens/rendering_screens/dynamic_rendering.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../controller/dynamic_render_prompt_controller.dart';
import '../../models/project_model.dart';

class ProjectDetailsScreen extends StatelessWidget {
  final Project project;
  const ProjectDetailsScreen({super.key, required this.project});

  // A consistent color scheme for the screen
  static const Color _primaryColor = Color(0xFF5E72EB);
  static const Color _backgroundColor = Color(0xFFF7F8FC);
  static const Color _primaryTextColor = Color(0xFF1D2939);
  static const Color _secondaryTextColor = Color(0xFF667085);
  static const Color _errorColor = Color(0xFFD92D20);
  static const Color _cardBackgroundColor = Colors.white;
  static const Color _successColor = Color(0xFF039855);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.to(() => PromptScreen(projectId: project.id));
        },
        tooltip: 'Create New Screen',
        child: const Icon(Icons.add),
      ),
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _cardBackgroundColor,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: _primaryTextColor),
        title: Text(
          project.projectName,
          style: const TextStyle(color: _primaryTextColor, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildProjectOverviewCard(),
          const SizedBox(height: 24),
          _buildScreensSection(context),
        ],
      ),
    );
  }

  Widget _buildProjectOverviewCard() {
    return Card(
      elevation: 2,
      shadowColor: _primaryColor.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Project Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _primaryTextColor)),
            const Divider(height: 20),
            _buildInfoRow(Icons.tag, 'Project ID', project.id),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.flag_outlined, 'Status', project.status),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.calendar_today_outlined, 'Created On', DateFormat.yMMMd().format(project.createdAt)),
            const SizedBox(height: 12),
            _buildFirebaseStatusRow(),
            const Divider(height: 20),
            _buildEnvVariablesSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildEnvVariablesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow(Icons.data_object, 'Environment Variables', ''),
        const SizedBox(height: 8),
        if (project.envVariables.isEmpty)
          const Padding(
            padding: EdgeInsets.only(left: 32.0),
            child: Text('None', style: TextStyle(color: _secondaryTextColor, fontStyle: FontStyle.italic)),
          )
        else
          Padding(
            padding: const EdgeInsets.only(left: 24.0),
            child: Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: project.envVariables.map((variable) {
                return Chip(
                  label: Text(variable.toString()),
                  backgroundColor: _primaryColor.withOpacity(0.1),
                  labelStyle: const TextStyle(color: _primaryColor, fontWeight: FontWeight.w500),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
          )
      ],
    );
  }

  Widget _buildScreensSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text('Screens', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _primaryTextColor)),
        ),
        if (project.listOfScreens.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32.0),
              child: Text('No screens yet. Tap the + button to create one!', style: TextStyle(color: _secondaryTextColor)),
            ),
          )
        else
          Column(
            children: project.listOfScreens.map((screen) => _buildScreenTile(context, screen)).toList(),
          ),
      ],
    );
  }

  Widget _buildScreenTile(BuildContext context, ProjectScreen screen) {
    return Card(
      elevation: 2,
      shadowColor: _primaryColor.withOpacity(0.08),
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: ValueKey(screen.screenId),
          leading: const Icon(Icons.phone_android_outlined, color: _primaryColor),
          title: Text(screen.screenName, style: const TextStyle(fontWeight: FontWeight.w600, color: _primaryTextColor)),
          subtitle: Text(screen.screenPrompt, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _secondaryTextColor)),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          collapsedIconColor: _primaryColor,
          iconColor: _primaryColor,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Column(
                children: [
                  _buildActionListItem(context, icon: Icons.visibility_outlined, label: 'View Screen', onTap: () {
                    Get.to(
                          () => const DynamicRenderingScreen(),
                      binding: DynamicRenderingBinding(), // Add the binding
                      arguments: {
                        'widgetData': screen.screenUI,
                        'mode': ScreenMode.view,
                        'project': project,
                        'screen': screen,
                      },
                    );
                  }),
                  _buildActionListItem(context, icon: Icons.code_outlined, label: 'View Code', onTap: () {
                    Get.to(() => CodeViewerScreen(code: screen.screenCode, title: screen.screenName));
                  }),
                  _buildActionListItem(context, icon: Icons.edit_outlined, label: 'Update Screen', onTap: () {
                    Get.to(
                          () => const DynamicRenderingScreen(),
                      binding: DynamicRenderingBinding(), // Add the binding
                      arguments: {
                        'widgetData': screen.screenUI,
                        'mode': ScreenMode.update,
                        'project': project,
                        'screen': screen,
                      },
                    );
                  }),
                  _buildActionListItem(context, icon: Icons.delete_outline, label: 'Delete Screen', color: _errorColor, onTap: () {
                    // TODO: Implement delete functionality
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionListItem(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap, Color? color}) {
    final actionColor = color ?? _secondaryTextColor;
    return ListTile(
      leading: Icon(icon, color: actionColor),
      title: Text(label, style: TextStyle(fontWeight: FontWeight.w500, color: actionColor)),
      onTap: onTap,
      dense: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(children: [
      Icon(icon, color: _secondaryTextColor, size: 16),
      const SizedBox(width: 8),
      Text('$label: ', style: const TextStyle(color: _secondaryTextColor)),
      Expanded(
        child: Text(value, style: const TextStyle(color: _primaryTextColor, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
      ),
    ]);
  }

  Widget _buildFirebaseStatusRow() {
    final bool isConfigured = project.firebaseConfigured;
    return Row(children: [
      Icon(isConfigured ? Icons.check_circle : Icons.cancel_outlined, color: isConfigured ? _successColor : _errorColor, size: 16),
      const SizedBox(width: 8),
      Text('Firebase Configured: ', style: const TextStyle(color: _secondaryTextColor)),
      Text(isConfigured ? 'Yes' : 'No', style: TextStyle(color: isConfigured ? _successColor : _errorColor, fontWeight: FontWeight.w500)),
    ]);
  }
}