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

  // Refined professional color scheme
  static const Color _primaryColor = Color(0xFF2D3FE7);
  static const Color _accentColor = Color(0xFF6C5DD3);
  static const Color _backgroundColor = Color(0xFFFAFAFC);
  static const Color _primaryTextColor = Color(0xFF0F1419);
  static const Color _secondaryTextColor = Color(0xFF536471);
  static const Color _errorColor = Color(0xFFEF4444);
  static const Color _cardBackgroundColor = Colors.white;
  static const Color _successColor = Color(0xFF10B981);
  static const Color _warningColor = Color(0xFFF59E0B);
  static const Color _borderColor = Color(0xFFE8ECF4);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _primaryColor.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () {
            Get.to(() => PromptScreen(projectId: project.id));
          },
          backgroundColor: _primaryColor,
          elevation: 0,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text(
            'New Screen',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
      ),
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _cardBackgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _primaryTextColor),
          onPressed: () => Get.back(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              project.projectName,
              style: const TextStyle(
                color: _primaryTextColor,
                fontWeight: FontWeight.w700,
                fontSize: 20,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              '${project.listOfScreens.length} screen${project.listOfScreens.length != 1 ? 's' : ''}',
              style: const TextStyle(
                color: _secondaryTextColor,
                fontWeight: FontWeight.w400,
                fontSize: 13,
              ),
            ),
          ],
        ),
        actions: [
          // Build Button in AppBar
          Container(
            margin: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: () => _showBuildDialog(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                backgroundColor: _primaryColor.withOpacity(0.1),
                foregroundColor: _primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.build_rounded, size: 20),
              label: const Text(
                'Build',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: _borderColor,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          _buildProjectOverviewCard(),
          const SizedBox(height: 24),
          _buildScreensSection(context),
          const SizedBox(height: 80), // Space for FAB
        ],
      ),
    );
  }

  void _showBuildDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BuildConfirmationDialog(
        onConfirmed: () => _handleBuildProject(context),
      ),
    );
  }

  Future<void> _handleBuildProject(BuildContext context) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildLoadingDialog(),
    );

    try {
      final response = await BuildService.buildProject(
        projectId: project.id,
        instructions: '',
        initialScreenIndex: 0,
      );

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
        _showSuccessDialog(context, response);
      }
    } on BuildException catch (e) {
      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
        _showErrorDialog(context, e.message);
      }
    } catch (e) {
      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
        _showErrorDialog(context, 'An unexpected error occurred');
      }
    }
  }

  Widget _buildLoadingDialog() {
    return Dialog(
      backgroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: _primaryTextColor.withOpacity(0.08),
              blurRadius: 32,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Building Project',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
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
                color: _secondaryTextColor,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, BuildResponse response) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: _primaryTextColor.withOpacity(0.08),
                blurRadius: 32,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _successColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: _successColor,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Build Started!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: _primaryTextColor,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                response.message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: _secondaryTextColor,
                  height: 1.5,
                ),
              ),
              if (response.buildId != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _borderColor, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.fingerprint_rounded,
                            color: _accentColor,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Build ID',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        response.buildId!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _primaryTextColor,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: _successColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String errorMessage) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: _primaryTextColor.withOpacity(0.08),
                blurRadius: 32,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _errorColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_rounded,
                  color: _errorColor,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Build Failed',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: _primaryTextColor,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: _secondaryTextColor,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: _backgroundColor,
                        foregroundColor: _secondaryTextColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _showBuildDialog(context);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Retry',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProjectOverviewCard() {
    return Container(
      decoration: BoxDecoration(
        color: _cardBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _primaryTextColor.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.folder_rounded,
                    color: _primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Project Overview',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: _primaryTextColor,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              height: 1,
              color: _borderColor,
            ),
            const SizedBox(height: 20),
            _buildInfoRow(
              Icons.fingerprint_rounded,
              'Project ID',
              project.id,
              _accentColor,
            ),
            const SizedBox(height: 16),
            _buildStatusChip(),
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.calendar_today_rounded,
              'Created',
              DateFormat.yMMMd().format(project.createdAt),
              _secondaryTextColor,
            ),
            const SizedBox(height: 16),
            _buildFirebaseStatusRow(),
            const SizedBox(height: 20),
            Container(
              height: 1,
              color: _borderColor,
            ),
            const SizedBox(height: 20),
            _buildEnvVariablesSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    Color statusColor;
    IconData statusIcon;

    switch (project.status.toLowerCase()) {
      case 'active':
        statusColor = _successColor;
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'pending':
        statusColor = _warningColor;
        statusIcon = Icons.pending_rounded;
        break;
      default:
        statusColor = _secondaryTextColor;
        statusIcon = Icons.info_rounded;
    }

    return Row(
      children: [
        Icon(Icons.flag_rounded, color: _secondaryTextColor, size: 18),
        const SizedBox(width: 10),
        const Text(
          'Status',
          style: TextStyle(
            color: _secondaryTextColor,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: statusColor.withOpacity(0.3), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(statusIcon, color: statusColor, size: 14),
              const SizedBox(width: 6),
              Text(
                project.status,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEnvVariablesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.code_rounded, color: _secondaryTextColor, size: 18),
            const SizedBox(width: 10),
            const Text(
              'Environment Variables',
              style: TextStyle(
                color: _primaryTextColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (project.envVariables.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _borderColor, width: 1),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: _secondaryTextColor.withOpacity(0.6),
                  size: 18,
                ),
                const SizedBox(width: 10),
                Text(
                  'No environment variables configured',
                  style: TextStyle(
                    color: _secondaryTextColor.withOpacity(0.8),
                    fontStyle: FontStyle.italic,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          )
        else
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: project.envVariables.map((variable) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _accentColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _accentColor.withOpacity(0.2), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.data_object_rounded,
                      color: _accentColor,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      variable.toString(),
                      style: TextStyle(
                        color: _accentColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          )
      ],
    );
  }

  Widget _buildScreensSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.layers_rounded,
                color: _accentColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Screens',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: _primaryTextColor,
                letterSpacing: -0.3,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _backgroundColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _borderColor, width: 1),
              ),
              child: Text(
                '${project.listOfScreens.length}',
                style: const TextStyle(
                  color: _primaryTextColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (project.listOfScreens.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: _cardBackgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _borderColor, width: 1.5),
            ),
            child: Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _backgroundColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: _borderColor, width: 2),
                    ),
                    child: Icon(
                      Icons.phone_android_rounded,
                      color: _secondaryTextColor.withOpacity(0.6),
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No screens yet',
                    style: TextStyle(
                      color: _primaryTextColor,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the button below to create your first screen',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _secondaryTextColor.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Column(
            children: project.listOfScreens
                .map((screen) => _buildScreenTile(context, screen))
                .toList(),
          ),
      ],
    );
  }

  Widget _buildScreenTile(BuildContext context, ProjectScreen screen) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _cardBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _primaryTextColor.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: ValueKey(screen.screenId),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.only(bottom: 8),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
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
              fontWeight: FontWeight.w600,
              color: _primaryTextColor,
              fontSize: 16,
              letterSpacing: -0.2,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              screen.screenPrompt,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _secondaryTextColor.withOpacity(0.8),
                fontSize: 13,
              ),
            ),
          ),
          collapsedIconColor: _secondaryTextColor,
          iconColor: _primaryColor,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _backgroundColor,
                borderRadius: BorderRadius.circular(12),
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
                          code: screen.screenCode, title: screen.screenName));
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
          ],
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
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: color,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
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
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: const TextStyle(
            color: _secondaryTextColor,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: _primaryTextColor,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildFirebaseStatusRow() {
    final bool isConfigured = project.firebaseConfigured;
    return Row(
      children: [
        Icon(
          Icons.cloud_rounded,
          color: _secondaryTextColor,
          size: 18,
        ),
        const SizedBox(width: 10),
        const Text(
          'Firebase',
          style: TextStyle(
            color: _secondaryTextColor,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isConfigured
                ? _successColor.withOpacity(0.1)
                : _errorColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isConfigured
                  ? _successColor.withOpacity(0.3)
                  : _errorColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isConfigured ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: isConfigured ? _successColor : _errorColor,
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                isConfigured ? 'Configured' : 'Not Configured',
                style: TextStyle(
                  color: isConfigured ? _successColor : _errorColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}