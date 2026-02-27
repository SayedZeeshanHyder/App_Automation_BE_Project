import 'dart:math';
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

// ─────────────────────────────────────────────────────────────────────────────
// Colour tokens  (light / white theme)
// ─────────────────────────────────────────────────────────────────────────────
class _C {
  static const primary     = Color(0xFF3B5BF6);
  static const accent      = Color(0xFF7C3AED);
  static const bg          = Color(0xFFF5F7FF);
  static const surface     = Color(0xFFFFFFFF);
  static const card        = Color(0xFFFFFFFF);
  static const border      = Color(0xFFE4E8F5);
  static const textPri     = Color(0xFF0F1535);
  static const textSec     = Color(0xFF6B7280);
  static const success     = Color(0xFF059669);
  static const error       = Color(0xFFDC2626);
  static const warning     = Color(0xFFD97706);
  static const active      = Color(0xFF2563EB);
}

// ─────────────────────────────────────────────────────────────────────────────
// Build‑status helpers
// ─────────────────────────────────────────────────────────────────────────────
enum _StepState { done, active, pending, failed }

class _BuildStep {
  final String status;   // the API status value that makes this step "active"
  final String label;
  final String desc;
  final IconData icon;

  const _BuildStep({
    required this.status,
    required this.label,
    required this.desc,
    required this.icon,
  });
}

const _kSteps = [
  _BuildStep(
    status: 'CONFIGURING_ENV',
    label: 'Environment',
    desc: 'Setting up env variables',
    icon: Icons.settings_ethernet_rounded,
  ),
  _BuildStep(
    status: 'CONFIGURING_PERMISSIONS',
    label: 'Permissions',
    desc: 'Configuring Android permissions',
    icon: Icons.security_rounded,
  ),
  _BuildStep(
    status: 'CONFIGURING_APP_ICON',
    label: 'App Icon',
    desc: 'Generating app icon',
    icon: Icons.image_rounded,
  ),
  _BuildStep(
    status: 'CONFIGURING_FIREBASE',
    label: 'Firebase',
    desc: 'Linking Firebase project',
    icon: Icons.cloud_rounded,
  ),
  _BuildStep(
    status: 'FINALIZING',
    label: 'Finalizing',
    desc: 'Bundling & optimising',
    icon: Icons.rocket_launch_rounded,
  ),
  _BuildStep(
    status: 'COMPLETED',
    label: 'Completed',
    desc: 'Your app is ready',
    icon: Icons.check_circle_rounded,
  ),
];

// Order index of each status string
const _kStatusOrder = {
  'CONFIGURING_ENV':         0,
  'CONFIGURING_PERMISSIONS': 1,
  'CONFIGURING_APP_ICON':    2,
  'CONFIGURING_FIREBASE':    3,
  'FINALIZING':              4,
  'COMPLETED':               5,
  'FAILED':                  6,
};

_StepState _stepState(String projectStatus, int stepIndex) {
  final currentOrder = _kStatusOrder[projectStatus] ?? 0;
  if (projectStatus == 'FAILED') {
    if (stepIndex < currentOrder) return _StepState.done;
    if (stepIndex == currentOrder) return _StepState.failed;
    return _StepState.pending;
  }
  if (stepIndex < currentOrder) return _StepState.done;
  if (stepIndex == currentOrder) return _StepState.active;
  return _StepState.pending;
}

// ─────────────────────────────────────────────────────────────────────────────
// Blinking dot widget
// ─────────────────────────────────────────────────────────────────────────────
class _BlinkingDot extends StatefulWidget {
  final Color color;
  final double size;
  const _BlinkingDot({required this.color, this.size = 10});

  @override
  State<_BlinkingDot> createState() => _BlinkingDotState();
}

class _BlinkingDotState extends State<_BlinkingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withOpacity(0.3 + 0.7 * _anim.value),
          boxShadow: [
            BoxShadow(
              color: widget.color.withOpacity(0.5 * _anim.value),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main screen
// ─────────────────────────────────────────────────────────────────────────────
class ProjectDetailsScreen extends StatelessWidget {
  final Project project;
  const ProjectDetailsScreen({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      floatingActionButton: _buildFAB(),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(72),
        child: _buildAppBar(context),
      ),
      body: Stack(
        children: [
          _buildAmbientGlow(),
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            children: [

              _buildInfoCard(),
              const SizedBox(height: 20),
              _buildStatusStepper(),
              const SizedBox(height: 20),
              _buildScreensSection(context),
            ],
          ),
        ],
      ),
    );
  }

  // ── Ambient background glow ─────────────────────────────────────────────
  Widget _buildAmbientGlow() {
    return Stack(
      children: [
        Positioned(
          top: -80, right: -80,
          child: _glowCircle(280, _C.primary.withOpacity(0.07)),
        ),
        Positioned(
          bottom: -120, left: -60,
          child: _glowCircle(320, _C.accent.withOpacity(0.06)),
        ),
        Positioned(
          top: 300, right: 20,
          child: _glowCircle(120, _C.active.withOpacity(0.04)),
        ),
      ],
    );
  }

  Widget _glowCircle(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(colors: [color, Colors.transparent]),
    ),
  );

  // ── AppBar ──────────────────────────────────────────────────────────────
  Widget _buildAppBar(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            color: _C.surface.withOpacity(0.92),
            border: Border(
              bottom: BorderSide(color: _C.border, width: 1),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  _iconButton(Icons.arrow_back_rounded, () => Get.back()),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          project.projectName,
                          style: const TextStyle(
                            color: _C.textPri,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            letterSpacing: -0.4,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${project.listOfScreens.length} screen${project.listOfScreens.length != 1 ? 's' : ''}  ·  ${_statusLabel(project.status)}',
                          style: const TextStyle(
                            color: _C.textSec, fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  _buildAppBarBuildBtn(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _statusLabel(String s) => s
      .replaceAll('_', ' ')
      .toLowerCase()
      .split(' ')
      .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
      .join(' ');

  Widget _iconButton(IconData icon, VoidCallback onTap) => _glassBox(
    48, 48, 14,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Center(child: Icon(icon, color: _C.textPri, size: 20)),
      ),
    ),
  );

  Widget _buildAppBarBuildBtn(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(14),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_C.primary.withOpacity(0.3), _C.accent.withOpacity(0.2)],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _C.primary.withOpacity(0.4), width: 1.5),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () =>_handleBuildProject(context),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.build_rounded, color: _C.primary, size: 18),
                  SizedBox(width: 7),
                  Text(
                    'Build',
                    style: TextStyle(
                      color: _C.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
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

  // ── Floating Action Button ──────────────────────────────────────────────
  Widget _buildFAB() => ClipRRect(
    borderRadius: BorderRadius.circular(18),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_C.primary, _C.accent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: _C.primary.withOpacity(0.45),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Get.to(() => PromptScreen(projectId: project.id)),
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.add_rounded, color: Colors.white, size: 22),
                  SizedBox(width: 9),
                  Text(
                    'New Screen',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
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

  // ── Build Status Stepper ────────────────────────────────────────────────
  Widget _buildStatusStepper() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(Icons.timeline_rounded, 'Project Status', _C.primary),
          const SizedBox(height: 20),
          ...List.generate(_kSteps.length, (i) {
            final step = _kSteps[i];
            final state = _stepState(project.status, i);
            final isLast = i == _kSteps.length - 1;
            return _buildStepRow(step, state, i, isLast);
          }),
        ],
      ),
    );
  }

  Widget _buildStepRow(
      _BuildStep step, _StepState state, int index, bool isLast) {
    final (dotColor, labelColor, bgColor, borderColor) = switch (state) {
      _StepState.done    => (_C.success, _C.success,    _C.success.withOpacity(0.12), _C.success.withOpacity(0.3)),
      _StepState.active  => (_C.active,  _C.active,     _C.active.withOpacity(0.12),  _C.active.withOpacity(0.3)),
      _StepState.failed  => (_C.error,   _C.error,      _C.error.withOpacity(0.12),   _C.error.withOpacity(0.3)),
      _StepState.pending => (_C.textSec.withOpacity(0.3), _C.textSec, Colors.transparent, _C.border),
    };

    Widget dot;
    if (state == _StepState.active) {
      dot = _BlinkingDot(color: _C.active, size: 12);
    } else {
      dot = Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: dotColor,
          boxShadow: state == _StepState.done
              ? [BoxShadow(color: dotColor.withOpacity(0.4), blurRadius: 8)]
              : null,
        ),
        child: state == _StepState.done
            ? const Icon(Icons.check, color: Colors.white, size: 8)
            : state == _StepState.failed
            ? const Icon(Icons.close, color: Colors.white, size: 8)
            : null,
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Timeline column ──
          SizedBox(
            width: 36,
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: bgColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: borderColor, width: 1.5),
                  ),
                  child: Center(
                    child: Icon(step.icon, color: labelColor, size: 16),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            borderColor,
                            _C.border.withOpacity(0.3),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          // ── Content column ──
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          step.label,
                          style: TextStyle(
                            color: state == _StepState.pending
                                ? _C.textSec
                                : labelColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _stepSubtext(step, state, index),
                          style: const TextStyle(
                            color: _C.textSec,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (state == _StepState.active) dot,
                      if (state != _StepState.active) dot,
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(20),
                          border:
                          Border.all(color: borderColor, width: 1),
                        ),
                        child: Text(
                          _stepBadge(state),
                          style: TextStyle(
                            color: labelColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _stepSubtext(_BuildStep step, _StepState state, int index) {
    if (state == _StepState.active) return step.desc;
    if (state == _StepState.done) {
      return switch (index) {
        0 => project.envVariables.isEmpty
            ? 'No env variables defined'
            : '${project.envVariables.length} variable${project.envVariables.length != 1 ? 's' : ''} configured',
        1 => project.androidPermissions.isEmpty
            ? 'No permissions required'
            : '${project.androidPermissions.length} permission${project.androidPermissions.length != 1 ? 's' : ''} set',
        2 => project.appIcon != null && project.appIcon!.isNotEmpty
            ? 'Custom icon applied'
            : 'Default icon used',
        3 => project.firebaseConfigured ? 'Firebase linked' : 'No Firebase config',
        4 => 'Build pipeline completed',
        5 => 'Deployed  •  ${DateFormat.yMMMd().add_jm().format(project.lastBuildAt)}',
        _ => step.desc,
      };
    }
    if (state == _StepState.failed) return 'This step encountered an error';
    return 'Waiting…';
  }

  String _stepBadge(_StepState s) => switch (s) {
    _StepState.done    => 'DONE',
    _StepState.active  => 'ACTIVE',
    _StepState.failed  => 'FAILED',
    _StepState.pending => 'PENDING',
  };

  // ── Info Card (dates + config status pills) ─────────────────────────────
  Widget _buildInfoCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(Icons.info_outline_rounded, 'Project Info', _C.accent),
          const SizedBox(height: 18),
          _infoRow(Icons.calendar_today_rounded, 'Created',
              DateFormat.yMMMd().format(project.createdAt), _C.success),
          const SizedBox(height: 12),
          _infoRow(Icons.build_circle_rounded, 'Last Build',
              DateFormat.yMMMd().add_jm().format(project.lastBuildAt),
              _C.warning),
          const SizedBox(height: 18),
          _divider(),
          const SizedBox(height: 18),
          const Text(
            'Configuration',
            style: TextStyle(
              color: _C.textSec,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _configPill(
                Icons.settings_ethernet_rounded,
                'Env Vars',
                project.envVariables.isNotEmpty,
                project.envVariables.isEmpty
                    ? 'Not Set'
                    : '${project.envVariables.length} vars',
              ),
              _configPill(
                Icons.security_rounded,
                'Permissions',
                project.androidPermissions.isNotEmpty,
                project.androidPermissions.isEmpty
                    ? 'Not Set'
                    : '${project.androidPermissions.length} perms',
              ),
              _configPill(
                Icons.image_rounded,
                'App Icon',
                project.appIcon != null && project.appIcon!.isNotEmpty,
                project.appIcon != null && project.appIcon!.isNotEmpty
                    ? 'Configured'
                    : 'Not Set',
              ),
              _configPill(
                Icons.cloud_rounded,
                'Firebase',
                project.firebaseConfigured,
                project.firebaseConfigured ? 'Configured' : 'Not Set',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _configPill(
      IconData icon, String label, bool configured, String value) {
    final color = configured ? _C.success : _C.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: color.withOpacity(0.8),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Screens Section ─────────────────────────────────────────────────────
  Widget _buildScreensSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: _sectionHeader(Icons.layers_rounded, 'Screens', _C.primary),
        ),
        const SizedBox(height: 14),
        if (project.listOfScreens.isEmpty)
          _buildEmptyScreens()
        else
          ...project.listOfScreens
              .map((s) => _buildScreenCard(context, s))
              .toList(),
      ],
    );
  }

  Widget _buildEmptyScreens() => _card(
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _C.primary.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: _C.primary.withOpacity(0.2), width: 2),
          ),
          child: Icon(Icons.phone_android_rounded,
              size: 44, color: _C.primary.withOpacity(0.7)),
        ),
        const SizedBox(height: 18),
        const Text(
          'No screens yet',
          style: TextStyle(
              color: _C.textPri, fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        const Text(
          'Tap "New Screen" to add your first screen',
          style: TextStyle(color: _C.textSec, fontSize: 13),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );

  Widget _buildScreenCard(BuildContext context, ProjectScreen screen) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _card(
        padding: EdgeInsets.zero,
        child: Theme(
          data: ThemeData(
            dividerColor: Colors.transparent,
            splashColor: _C.primary.withOpacity(0.05),
            highlightColor: _C.primary.withOpacity(0.02),
          ),
          child: ExpansionTile(
            tilePadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            childrenPadding:
            const EdgeInsets.fromLTRB(12, 0, 12, 12),
            leading: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: _C.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: _C.primary.withOpacity(0.25), width: 1.5),
              ),
              child: const Icon(Icons.phone_android_rounded,
                  color: _C.primary, size: 18),
            ),
            title: Text(
              screen.screenName,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: _C.textPri,
                  fontSize: 15,
                  letterSpacing: -0.2),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                screen.screenPrompt,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: _C.textSec, fontSize: 12, height: 1.4),
              ),
            ),
            collapsedIconColor: _C.textSec,
            iconColor: _C.primary,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: _C.bg.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _C.border, width: 1),
                ),
                child: Column(
                  children: [
                    _actionTile(
                      icon: Icons.visibility_rounded,
                      label: 'View Screen',
                      color: _C.primary,
                      onTap: () => Get.to(
                            () => const DynamicRenderingScreen(),
                        binding: DynamicRenderingBinding(),
                        arguments: {
                          'widgetData': screen.screenUI,
                          'mode': ScreenMode.view,
                          'project': project,
                          'screen': screen,
                        },
                      ),
                    ),
                    _tileDivider(),
                    _actionTile(
                      icon: Icons.code_rounded,
                      label: 'View Code',
                      color: _C.accent,
                      onTap: () => Get.to(() => CodeViewerScreen(
                        code: screen.screenCode,
                        title: screen.screenName,
                      )),
                    ),
                    _tileDivider(),
                    _actionTile(
                      icon: Icons.edit_rounded,
                      label: 'Update Screen',
                      color: _C.success,
                      onTap: () => Get.to(
                            () => const DynamicRenderingScreen(),
                        binding: DynamicRenderingBinding(),
                        arguments: {
                          'widgetData': screen.screenUI,
                          'mode': ScreenMode.update,
                          'project': project,
                          'screen': screen,
                        },
                      ),
                    ),
                    _tileDivider(),
                    _actionTile(
                      icon: Icons.delete_rounded,
                      label: 'Delete Screen',
                      color: _C.error,
                      onTap: () {
                        // TODO: delete
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: color.withOpacity(0.22), width: 1),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: color.withOpacity(0.35), size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tileDivider() => Container(
    height: 1,
    margin: const EdgeInsets.symmetric(horizontal: 14),
    color: _C.border.withOpacity(0.5),
  );

  // ── Shared primitives ───────────────────────────────────────────────────
  Widget _card({required Widget child, EdgeInsetsGeometry? padding}) =>
      ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: padding ?? const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: _C.card.withOpacity(0.95),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: _C.border, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: _C.primary.withOpacity(0.07),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: child,
          ),
        ),
      );

  Widget _glassBox(double w, double h, double r, {required Widget child}) =>
      ClipRRect(
        borderRadius: BorderRadius.circular(r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            width: w,
            height: h,
            decoration: BoxDecoration(
              color: _C.surface.withOpacity(0.8),
              borderRadius: BorderRadius.circular(r),
              border: Border.all(color: _C.border, width: 1.5),
            ),
            child: child,
          ),
        ),
      );

  Widget _sectionHeader(IconData icon, String title, Color color) => Row(
    children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.25), width: 1.5),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
      const SizedBox(width: 12),
      Text(
        title,
        style: const TextStyle(
          color: _C.textPri,
          fontWeight: FontWeight.w800,
          fontSize: 17,
          letterSpacing: -0.3,
        ),
      ),
    ],
  );

  Widget _infoRow(IconData icon, String label, String value, Color color) =>
      Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.2), width: 1),
            ),
            child: Icon(icon, color: color, size: 15),
          ),
          const SizedBox(width: 12),
          Text('$label  ',
              style: const TextStyle(color: _C.textSec, fontSize: 13)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  color: _C.textPri, fontWeight: FontWeight.w700, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );

  Widget _divider() => Container(
    height: 1,
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [
        Colors.transparent,
        _C.border.withOpacity(0.6),
        Colors.transparent,
      ]),
    ),
  );

  Future<void> _handleBuildProject(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (_) => BuildConfirmationDialog(
        screens: project.listOfScreens.map((s) => s.screenName).toList(), // your screen list
        onConfirmed: (instructions, initialScreenIndex) async {
          showDialog(
            context: context,
            barrierDismissible: false,
            barrierColor: Colors.black.withOpacity(0.5),
            builder: (_) => _loadingDialog(),
          );
          try {
            final response = await BuildService.buildProject(
              projectId: project.id,
              instructions: instructions,
              initialScreenIndex: initialScreenIndex,
            );
            if (context.mounted) {
              Navigator.of(context).pop();
              _showResultDialog(context, true, 'Build Successful!',
                  'Your project has been built successfully.');
            }
          } on BuildException catch (e) {
            if (context.mounted) {
              Navigator.of(context).pop();
              _showResultDialog(context, false, 'Build Failed', e.message);
            }
          } catch (_) {
            if (context.mounted) {
              Navigator.of(context).pop();
              _showResultDialog(
                  context, false, 'Build Failed', 'An unexpected error occurred.');
            }
          }
        },
      ),
    );
  }

  Widget _loadingDialog() => Dialog(
    backgroundColor: Colors.transparent,
    child: _card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _C.primary.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(color: _C.primary.withOpacity(0.25), width: 2),
            ),
            child: SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(_C.primary),
              ),
            ),
          ),
          const SizedBox(height: 22),
          const Text('Building Project',
              style: TextStyle(
                  color: _C.textPri,
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text(
            'Please wait while we compile your project…',
            textAlign: TextAlign.center,
            style: TextStyle(color: _C.textSec, fontSize: 14, height: 1.5),
          ),
        ],
      ),
    ),
  );

  void _showResultDialog(
      BuildContext context, bool success, String title, String msg) {
    final color = success ? _C.success : _C.error;
    final icon  = success ? Icons.check_circle_rounded : Icons.error_rounded;
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: _card(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withOpacity(0.3), width: 2),
                ),
                child: Icon(icon, color: color, size: 48),
              ),
              const SizedBox(height: 20),
              Text(title,
                  style: const TextStyle(
                      color: _C.textPri,
                      fontSize: 20,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              Text(
                msg,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: _C.textSec, fontSize: 14, height: 1.5),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 22),
              _dialogBtn('Close', () => Navigator.of(context).pop(), color),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dialogBtn(String label, VoidCallback onTap, Color color) =>
      SizedBox(
        width: double.infinity,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withOpacity(0.35), width: 1.5),
              ),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ),
        ),
      );
}