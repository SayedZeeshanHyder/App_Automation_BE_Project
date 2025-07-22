import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/project_creation_controller.dart';

class ProjectCreationScreen extends StatelessWidget {
  final _formKey = GlobalKey<FormState>();
  final _projectNameController = TextEditingController();
  final _organizationController = TextEditingController(text: 'com.example');
  final _descriptionController = TextEditingController(text: 'A new Flutter project');
  final ProjectCreationController controller = Get.put(ProjectCreationController());

  ProjectCreationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value) {
            return _buildLoadingScreen();
          }
          return _buildMainContent();
        }),
      ),
    );
  }

  Widget _buildMainContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;
        final isTablet = screenWidth > 600;
        final isSmall = screenWidth < 360;

        return Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 40 : (isSmall ? 8 : 16),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: screenHeight - 100,
                      maxWidth: 650,
                    ),
                    child: Column(
                      children: [
                        SizedBox(height: screenHeight > 700 ? 24 : 16),
                        _buildWelcomeSection(screenWidth, screenHeight),
                        SizedBox(height: screenHeight > 700 ? 32 : 20),
                        _buildFormSection(screenWidth, screenHeight),
                        SizedBox(height: screenHeight > 700 ? 32 : 20),
                        _buildCreateButton(screenWidth),
                        SizedBox(height: screenHeight > 700 ? 24 : 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAppBar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 360;
        return Container(
          padding: EdgeInsets.symmetric(horizontal: isSmall ? 10 : 16, vertical: 14),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 1,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  width: isSmall ? 36 : 40,
                  height: isSmall ? 36 : 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    size: isSmall ? 16 : 18,
                    color: const Color(0xFF333333),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'New Project',
                  style: TextStyle(
                    fontSize: isSmall ? 18 : 20,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1A1A),
                    letterSpacing: -0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWelcomeSection(double screenWidth, double screenHeight) {
    final isSmall = screenWidth < 360;
    final isVerySmall = screenWidth < 320;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isVerySmall ? 10 : (isSmall ? 12 : 18)),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF4F46E5),
            Color(0xFF7C3AED),
          ],
        ),
        borderRadius: BorderRadius.circular(isSmall ? 16 : 20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withOpacity(0.18),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flex(
            direction: isSmall ? Axis.vertical : Axis.horizontal,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: isSmall ? 36 : 44,
                height: isSmall ? 36 : 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(isSmall ? 12 : 14),
                ),
                child: Icon(
                  Icons.rocket_launch_rounded,
                  color: Colors.white,
                  size: isSmall ? 20 : 24,
                ),
              ),
              SizedBox(width: isSmall ? 0 : 14, height: isSmall ? 8 : 0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create Project',
                      style: TextStyle(
                        fontSize: isVerySmall ? 16 : (isSmall ? 18 : 20),
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.4,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Set up your Flutter application',
                      style: TextStyle(
                        fontSize: isVerySmall ? 12 : (isSmall ? 13 : 14),
                        color: Colors.white,
                        fontWeight: FontWeight.w400,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormSection(double screenWidth, double screenHeight) {
    final isSmall = screenWidth < 360;
    final isVerySmall = screenWidth < 320;

    return Container(
      padding: EdgeInsets.all(isVerySmall ? 10 : (isSmall ? 12 : 18)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isSmall ? 14 : 20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Project Details',
              style: TextStyle(
                fontSize: isVerySmall ? 15 : (isSmall ? 16 : 18),
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1A1A),
                letterSpacing: -0.3,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: isSmall ? 12 : 18),
            _buildInputField(
              controller: _projectNameController,
              label: 'Project Name',
              hint: 'my_awesome_app',
              icon: Icons.folder_outlined,
              screenWidth: screenWidth,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Project name is required';
                }
                if (!RegExp(r'^[a-z_][a-z0-9_]*$').hasMatch(value)) {
                  return 'Use lowercase letters, numbers, and underscores only';
                }
                return null;
              },
            ),
            SizedBox(height: isSmall ? 10 : 16),
            _buildInputField(
              controller: _organizationController,
              label: 'Organization',
              hint: 'com.yourcompany.app',
              icon: Icons.business_outlined,
              screenWidth: screenWidth,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Organization is required';
                }
                return null;
              },
            ),
            SizedBox(height: isSmall ? 10 : 16),
            _buildInputField(
              controller: _descriptionController,
              label: 'Description',
              hint: 'A brief description of your project',
              icon: Icons.description_outlined,
              maxLines: 3,
              screenWidth: screenWidth,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Description is required';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required double screenWidth,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    final isSmall = screenWidth < 360;
    final isVerySmall = screenWidth < 320;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isVerySmall ? 12 : (isSmall ? 13 : 14),
            fontWeight: FontWeight.w600,
            color: const Color(0xFF374151),
            letterSpacing: -0.1,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          maxLines: maxLines,
          style: TextStyle(
            fontSize: isVerySmall ? 14 : (isSmall ? 15 : 16),
            fontWeight: FontWeight.w500,
            color: const Color(0xFF111827),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: const Color(0xFF9CA3AF),
              fontWeight: FontWeight.w400,
              fontSize: isVerySmall ? 13 : (isSmall ? 14 : 16),
            ),
            prefixIcon: Icon(
              icon,
              color: const Color(0xFF6B7280),
              size: isVerySmall ? 16 : (isSmall ? 18 : 20),
            ),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            contentPadding: EdgeInsets.symmetric(
              horizontal: isVerySmall ? 10 : (isSmall ? 12 : 15),
              vertical: isVerySmall ? 10 : (isSmall ? 12 : 15),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFE5E7EB),
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFE5E7EB),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF4F46E5),
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFEF4444),
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFEF4444),
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCreateButton(double screenWidth) {
    final isSmall = screenWidth < 360;
    final isVerySmall = screenWidth < 320;

    return SizedBox(
      width: double.infinity,
      height: isVerySmall ? 42 : (isSmall ? 46 : 50),
      child: ElevatedButton(
        onPressed: _createProject,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4F46E5),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          shadowColor: const Color(0xFF4F46E5).withOpacity(0.15),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_circle_outline,
              size: isVerySmall ? 16 : (isSmall ? 18 : 20),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Create Project',
                style: TextStyle(
                  fontSize: isVerySmall ? 13 : (isSmall ? 14 : 15),
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;
        final isTablet = screenWidth > 600;
        final isSmall = screenWidth < 360;

        return Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.all(isTablet ? 32 : (isSmall ? 8 : 16)),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: screenHeight - 120,
                      maxWidth: 650,
                    ),
                    child: Column(
                      children: [
                        SizedBox(height: screenHeight > 700 ? 24 : 12),
                        _buildStatusCard(screenWidth, screenHeight),
                        const SizedBox(height: 20),
                        _buildProgressSection(),
                        SizedBox(height: screenHeight > 700 ? 32 : 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusCard(double screenWidth, double screenHeight) {
    final isSmall = screenWidth < 360;
    final isVerySmall = screenWidth < 320;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isVerySmall ? 10 : (isSmall ? 12 : 18)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isSmall ? 14 : 20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildStatusHeader(screenWidth),
          SizedBox(height: isSmall ? 14 : 22),
          _buildStatusItems(screenWidth),
        ],
      ),
    );
  }

  Widget _buildStatusHeader(double screenWidth) {
    final isSmall = screenWidth < 360;
    final isVerySmall = screenWidth < 320;

    return Flex(
      direction: isSmall ? Axis.vertical : Axis.horizontal,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: isSmall ? 36 : 44,
          height: isSmall ? 36 : 44,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
            ),
            borderRadius: BorderRadius.circular(isSmall ? 12 : 14),
          ),
          child: Icon(
            Icons.construction_rounded,
            color: Colors.white,
            size: isSmall ? 20 : 24,
          ),
        ),
        SizedBox(width: isSmall ? 0 : 14, height: isSmall ? 8 : 0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Creating Project',
                style: TextStyle(
                  fontSize: isVerySmall ? 15 : (isSmall ? 16 : 18),
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1A1A),
                  letterSpacing: -0.3,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                'Please wait while we set up your project',
                style: TextStyle(
                  fontSize: isVerySmall ? 11 : (isSmall ? 12 : 13),
                  color: const Color(0xFF6B7280),
                  fontWeight: FontWeight.w400,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusItems(double screenWidth) {
    return Obx(() {
      final statuses = controller.statusList;
      final currentIndex = controller.currentStatusIndex.value;

      return Column(
        children: statuses.asMap().entries.map((entry) {
          final index = entry.key;
          final status = entry.value;
          final isActive = index == currentIndex;
          final isCompleted = index < currentIndex;

          return Container(
            margin: EdgeInsets.only(bottom: screenWidth < 360 ? 7 : 10),
            child: _buildStatusRow(
              status: status,
              isActive: isActive,
              isCompleted: isCompleted,
              screenWidth: screenWidth,
            ),
          );
        }).toList(),
      );
    });
  }

  Widget _buildStatusRow({
    required StatusItem status,
    required bool isActive,
    required bool isCompleted,
    required double screenWidth,
  }) {
    final isSmall = screenWidth < 360;
    final isVerySmall = screenWidth < 320;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: EdgeInsets.all(isVerySmall ? 8 : (isSmall ? 9 : 11)),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF4F46E5).withOpacity(0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isActive ? Border.all(color: const Color(0xFF4F46E5).withOpacity(0.15)) : null,
      ),
      child: Row(
        children: [
          _buildStatusIcon(isActive, isCompleted, status.icon, screenWidth),
          SizedBox(width: isVerySmall ? 8 : (isSmall ? 9 : 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.title,
                  style: TextStyle(
                    fontSize: isVerySmall ? 12 : (isSmall ? 13 : 15),
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    color: isActive || isCompleted
                        ? const Color(0xFF1A1A1A)
                        : const Color(0xFF9CA3AF),
                    letterSpacing: -0.1,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (status.subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    status.subtitle!,
                    style: TextStyle(
                      fontSize: isVerySmall ? 10 : (isSmall ? 11 : 12),
                      color: isActive || isCompleted
                          ? const Color(0xFF6B7280)
                          : const Color(0xFFD1D5DB),
                      fontWeight: FontWeight.w400,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(bool isActive, bool isCompleted, IconData defaultIcon, double screenWidth) {
    final isSmall = screenWidth < 360;
    final isVerySmall = screenWidth < 320;
    final iconSize = isVerySmall ? 22.0 : (isSmall ? 24.0 : 28.0);
    final innerIconSize = isVerySmall ? 11.0 : (isSmall ? 13.0 : 15.0);

    if (isCompleted) {
      return Container(
        width: iconSize,
        height: iconSize,
        decoration: BoxDecoration(
          color: const Color(0xFF10B981),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Icon(
          Icons.check_rounded,
          color: Colors.white,
          size: innerIconSize,
        ),
      );
    }

    if (isActive) {
      return Container(
        width: iconSize,
        height: iconSize,
        decoration: BoxDecoration(
          color: const Color(0xFF4F46E5),
          borderRadius: BorderRadius.circular(7),
        ),
        child: SizedBox(
          width: innerIconSize,
          height: innerIconSize,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: const CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
      );
    }

    return Container(
      width: iconSize,
      height: iconSize,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Icon(
        defaultIcon,
        color: const Color(0xFF9CA3AF),
        size: innerIconSize,
      ),
    );
  }

  Widget _buildProgressSection() {
    return Obx(() {
      final progress = controller.currentStatusIndex.value >= 0
          ? (controller.currentStatusIndex.value + 1) / controller.statusList.length
          : 0.0;

      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: Text(
                  'Progress',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF374151),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4F46E5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: const Color(0xFFE5E7EB),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
            borderRadius: BorderRadius.circular(4),
            minHeight: 5,
          ),
        ],
      );
    });
  }

  void _createProject() {
    if (_formKey.currentState!.validate()) {
      controller.createProject(
        projectName: _projectNameController.text.trim(),
        organization: _organizationController.text.trim(),
        description: _descriptionController.text.trim(),
      );
    }
  }
}
