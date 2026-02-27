import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';

import '../../constants/api_constants.dart';
import '../../models/build_model.dart';
import '../../services/shared_preferences_service.dart';

class BuildDetailsScreen extends StatefulWidget {
  final BuildModel buildModel;

  const BuildDetailsScreen({Key? key, required this.buildModel})
      : super(key: key);

  @override
  State<BuildDetailsScreen> createState() => _BuildDetailsScreenState();
}

class _BuildDetailsScreenState extends State<BuildDetailsScreen>
    with TickerProviderStateMixin {
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  bool _logsExpanded = false;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Design tokens — crisp white + slate palette
  static const Color _white = Color(0xFFFFFFFF);
  static const Color _surface = Color(0xFFF7F8FA);
  static const Color _border = Color(0xFFEAECF0);
  static const Color _ink = Color(0xFF0D1117);
  static const Color _inkMuted = Color(0xFF6E7882);
  static const Color _inkLight = Color(0xFFADB5BD);
  static const Color _accent = Color(0xFF1A56DB);
  static const Color _accentLight = Color(0xFFEBF0FF);
  static const Color _success = Color(0xFF0D9E6A);
  static const Color _successLight = Color(0xFFE6F7F1);
  static const Color _danger = Color(0xFFDC2626);
  static const Color _dangerLight = Color(0xFFFEF2F2);
  static const Color _warning = Color(0xFFD97706);
  static const Color _warningLight = Color(0xFFFFFBEB);

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 420));
    _slideController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 380));

    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _downloadApk() async {
    // --- Permission handling (Android 11+ vs below) ---
    bool hasPermission = false;

    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 30) {
        // Android 11+ — check MANAGE_EXTERNAL_STORAGE
        if (await Permission.manageExternalStorage.isGranted) {
          hasPermission = true;
        } else {
          final status =
          await Permission.manageExternalStorage.request();
          hasPermission = status.isGranted;
        }
      } else {
        // Android 10 and below — regular storage permission
        final status = await Permission.storage.request();
        hasPermission = status.isGranted;
      }
    } else {
      hasPermission = true;
    }

    if (!hasPermission) {
      _showSnackBar(
          'Storage permission required to download APK',
          _danger,
          Icons.lock_rounded);
      return;
    }

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      final token = SharedPreferencesService.getToken();

      // --- Stream the response to track progress ---
      final request = http.Request(
        'GET',
        Uri.parse(
            '${ApiConstants.baseUrl}/build/${widget.buildModel.buildId}/download'),
      );
      request.headers['Authorization'] = 'Bearer $token';

      final streamedResponse = await http.Client().send(request);

      if (streamedResponse.statusCode != 200) {
        setState(() => _isDownloading = false);
        _showSnackBar(
            'Download failed (${streamedResponse.statusCode})',
            _danger,
            Icons.error_rounded);
        return;
      }

      final contentLength = streamedResponse.contentLength ?? 0;
      final bytes = <int>[];

      await for (final chunk in streamedResponse.stream) {
        bytes.addAll(chunk);
        if (contentLength > 0 && mounted) {
          setState(() {
            _downloadProgress = bytes.length / contentLength;
          });
        }
      }

      // --- Save to public Downloads directory ---
      // Using /storage/emulated/0/Download so the system installer can access it
      final version =
          widget.buildModel.buildVersion?.replaceAll(RegExp(r'[^\w.-]'), '_') ??
              'latest';
      final fileName = 'app_$version.apk';

      String filePath;

      // Try public Downloads folder first (accessible by package installer)
      final downloadsDir = Directory('/storage/emulated/0/Download');
      if (await downloadsDir.exists()) {
        filePath = '${downloadsDir.path}/$fileName';
      } else {
        // Fallback: app external storage
        final dir = await getExternalStorageDirectory();
        filePath = '${dir!.path}/$fileName';
      }

      final file = File(filePath);
      await file.writeAsBytes(bytes, flush: true); // flush ensures bytes are committed

      setState(() {
        _isDownloading = false;
        _downloadProgress = 1.0;
      });

      _showSnackBar(
          'APK saved to Downloads', _success, Icons.check_circle_rounded);

      // Small delay to ensure the file is fully flushed before the installer reads it
      await Future.delayed(const Duration(milliseconds: 400));

      // --- Open with explicit MIME type (critical for APK installer to trigger) ---
      final result = await OpenFilex.open(
        filePath,
        type: 'application/vnd.android.package-archive',
      );

      if (result.type != ResultType.done) {
        debugPrint('OpenFilex error: ${result.type} — ${result.message}');
        _showSnackBar(
          _installErrorMessage(result.type, result.message, filePath),
          _warning,
          Icons.warning_rounded,
        );
      }
    } catch (e) {
      debugPrint('Download error: $e');
      setState(() {
        _isDownloading = false;
        _downloadProgress = 0.0;
      });
      _showSnackBar(
          'Download failed. Please try again.', _danger, Icons.error_rounded);
    }
  }

  /// Returns a human-friendly message based on the OpenFilex failure type.
  String _installErrorMessage(
      ResultType type, String message, String filePath) {
    switch (type) {
      case ResultType.fileNotFound:
        return 'APK file not found at path. Please retry.';
      case ResultType.noAppToOpen:
        return 'No app available to install APK. Enable "Install unknown apps" in Settings.';
      case ResultType.permissionDenied:
        return 'Permission denied. Enable "Install unknown apps" for this app in Settings → Apps.';
      default:
        return 'Could not open installer: $message';
    }
  }

  void _showSnackBar(String message, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white)),
          ),
        ]),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '—';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy · hh:mm a').format(date);
    } catch (_) {
      return dateString;
    }
  }

  String _formatDuration(int? ms) {
    if (ms == null) return '—';
    final d = Duration(milliseconds: ms);
    return '${d.inMinutes}m ${d.inSeconds % 60}s';
  }

  @override
  Widget build(BuildContext context) {
    final build = widget.buildModel;
    final isSuccess = build.success && build.completed;
    final isFailed = build.completed && !build.success;
    final isInProgress = !build.completed;

    return Scaffold(
      backgroundColor: _white,
      appBar: _buildAppBar(build, isSuccess, isFailed, isInProgress),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusHero(isSuccess, isFailed, isInProgress),
                const SizedBox(height: 20),
                _buildSection(
                  title: 'Build Information',
                  icon: Icons.info_outline_rounded,
                  child: _buildInfoGrid(build),
                ),
                const SizedBox(height: 16),
                _buildSection(
                  title: 'Created By',
                  icon: Icons.person_outline_rounded,
                  child: _buildCreatorCard(build),
                ),
                const SizedBox(height: 16),
                if (build.instructions != null && build.instructions!.isNotEmpty) ...[
                  _buildSection(
                    title: 'Instructions',
                    icon: Icons.notes_rounded,
                    child: _buildInstructionsCard(build.instructions!),
                  ),
                  const SizedBox(height: 16),
                ],
                if (build.errorMessage != null && build.errorMessage!.isNotEmpty) ...[
                  _buildSection(
                    title: 'Error',
                    icon: Icons.bug_report_outlined,
                    child: _buildErrorCard(build.errorMessage!),
                  ),
                  const SizedBox(height: 16),
                ],
                if (build.logs != null && build.logs!.isNotEmpty) ...[
                  _buildLogsSection(build.logs!),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: isSuccess
          ? _buildDownloadBar()
          : null,
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildModel build, bool isSuccess, bool isFailed, bool isInProgress) {
    return AppBar(
      backgroundColor: _white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      shadowColor: _border,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            size: 18, color: _ink),
        tooltip: 'Back',
      ),
      titleSpacing: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            build.buildVersion ?? 'Build Details',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _ink,
              letterSpacing: -0.3,
            ),
          ),
          Text(
            isInProgress
                ? 'In Progress'
                : isSuccess
                ? 'Completed Successfully'
                : 'Build Failed',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isInProgress
                  ? _warning
                  : isSuccess
                  ? _success
                  : _danger,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {
            Clipboard.setData(
                ClipboardData(text: widget.buildModel.buildId));
            _showSnackBar('Build ID copied', _accent, Icons.copy_rounded);
          },
          icon: const Icon(Icons.copy_outlined, size: 18, color: _inkMuted),
          tooltip: 'Copy Build ID',
        ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _border),
      ),
    );
  }

  Widget _buildStatusHero(bool isSuccess, bool isFailed, bool isInProgress) {
    Color bgColor;
    Color iconColor;
    IconData iconData;
    String statusText;
    String subText;

    if (isSuccess) {
      bgColor = _successLight;
      iconColor = _success;
      iconData = Icons.check_circle_rounded;
      statusText = 'Build Successful';
      subText = widget.buildModel.statusMessage;
    } else if (isFailed) {
      bgColor = _dangerLight;
      iconColor = _danger;
      iconData = Icons.cancel_rounded;
      statusText = 'Build Failed';
      subText = widget.buildModel.statusMessage;
    } else {
      bgColor = _warningLight;
      iconColor = _warning;
      iconData = Icons.pending_rounded;
      statusText = 'Build In Progress';
      subText = widget.buildModel.statusMessage;
    }

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: iconColor.withOpacity(0.18),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(iconData, color: iconColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: iconColor,
                    letterSpacing: -0.2,
                  ),
                ),
                if (subText.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subText,
                    style: TextStyle(
                      fontSize: 12,
                      color: iconColor.withOpacity(0.75),
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
      {required String title,
        required IconData icon,
        required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 15, color: _inkMuted),
            const SizedBox(width: 6),
            Text(
              title.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _inkMuted,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }

  Widget _buildInfoGrid(BuildModel build) {
    return Container(
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border, width: 1),
      ),
      child: Column(
        children: [
          _buildInfoRow(
            'Build ID',
            build.buildId,
            icon: Icons.fingerprint_rounded,
            isFirst: true,
            monospace: true,
            truncate: true,
          ),
          _buildInfoRow(
            'Version',
            build.buildVersion ?? '—',
            icon: Icons.tag_rounded,
          ),
          _buildInfoRow(
            'Status',
            build.completed
                ? (build.success ? 'Completed' : 'Failed')
                : 'In Progress',
            icon: Icons.radio_button_checked_rounded,
            valueColor: build.completed
                ? (build.success ? _success : _danger)
                : _warning,
          ),
          _buildInfoRow(
            'Duration',
            _formatDuration(build.buildDurationMs),
            icon: Icons.timer_outlined,
          ),
          _buildInfoRow(
            'Created',
            _formatDate(build.createdAt),
            icon: Icons.calendar_today_rounded,
          ),
          _buildInfoRow(
            'Completed',
            _formatDate(build.completedAt),
            icon: Icons.check_circle_outline_rounded,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
      String label,
      String value, {
        IconData? icon,
        bool isFirst = false,
        bool isLast = false,
        Color? valueColor,
        bool monospace = false,
        bool truncate = false,
      }) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: isLast
              ? BorderSide.none
              : const BorderSide(color: _border, width: 1),
        ),
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: isFirst ? 14 : 11,
        bottom: isLast ? 14 : 11,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(icon, size: 14, color: _inkLight),
            ),
            const SizedBox(width: 10),
          ],
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: _inkMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: valueColor ?? _ink,
                fontWeight: FontWeight.w600,
                fontFamily: monospace ? 'monospace' : null,
                letterSpacing: monospace ? -0.2 : 0,
              ),
              maxLines: truncate ? 1 : 3,
              overflow: truncate ? TextOverflow.ellipsis : TextOverflow.visible,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreatorCard(BuildModel build) {
    final creator = build.createdBy;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _accentLight,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                creator.userName.isNotEmpty
                    ? creator.userName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _accent,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  creator.userName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  creator.email,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _inkMuted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _accentLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              creator.role,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _accent,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsCard(String instructions) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border, width: 1),
      ),
      child: Text(
        instructions,
        style: const TextStyle(
          fontSize: 13,
          color: _ink,
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildErrorCard(String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _dangerLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _danger.withOpacity(0.2), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, size: 16, color: _danger),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(
                fontSize: 13,
                color: _danger,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogsSection(List<String> logs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.terminal_rounded, size: 15, color: _inkMuted),
            const SizedBox(width: 6),
            const Text(
              'BUILD LOGS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _inkMuted,
                letterSpacing: 0.8,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => setState(() => _logsExpanded = !_logsExpanded),
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _logsExpanded ? 'Collapse' : 'Expand',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _inkMuted,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _logsExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 14,
                      color: _inkMuted,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 280),
          crossFadeState: _logsExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: _buildLogPreview(logs),
          secondChild: _buildFullLogs(logs),
        ),
      ],
    );
  }

  Widget _buildLogPreview(List<String> logs) {
    final preview = logs.take(5).toList();
    return _buildLogContainer(preview, isPreview: true, total: logs.length);
  }

  Widget _buildFullLogs(List<String> logs) {
    return _buildLogContainer(logs, isPreview: false, total: logs.length);
  }

  Widget _buildLogContainer(List<String> logs,
      {required bool isPreview, required int total}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _dot(const Color(0xFFFF5F57)),
              const SizedBox(width: 6),
              _dot(const Color(0xFFFFBD2E)),
              const SizedBox(width: 6),
              _dot(const Color(0xFF28CA41)),
              const Spacer(),
              Text(
                '$total lines',
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF6E7882),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...logs.asMap().entries.map((entry) {
            final line = entry.value;
            final isError = line.toLowerCase().contains('error') ||
                line.toLowerCase().contains('exception') ||
                line.toLowerCase().contains('failed');
            final isSuccess = line.toLowerCase().contains('successfully') ||
                line.toLowerCase().contains('success');
            final isWarning = line.toLowerCase().contains('warning') ||
                line.toLowerCase().contains('warn');

            Color lineColor = const Color(0xFFCDD4DF);
            if (isError) lineColor = const Color(0xFFF87171);
            if (isSuccess) lineColor = const Color(0xFF34D399);
            if (isWarning) lineColor = const Color(0xFFFBBF24);

            return Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${(entry.key + 1).toString().padLeft(3, '0')} ',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: Color(0xFF3D4557),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      line,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: lineColor,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          if (isPreview && total > 5) ...[
            const SizedBox(height: 8),
            Text(
              '+ ${total - 5} more lines...',
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF3D4557),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _dot(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildDownloadBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
      decoration: const BoxDecoration(
        color: _white,
        border: Border(top: BorderSide(color: _border, width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isDownloading) ...[
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _downloadProgress > 0 ? _downloadProgress : null,
                      backgroundColor: _accentLight,
                      valueColor:
                      const AlwaysStoppedAnimation<Color>(_accent),
                      minHeight: 5,
                    ),
                  ),
                ),
                if (_downloadProgress > 0) ...[
                  const SizedBox(width: 12),
                  Text(
                    '${(_downloadProgress * 100).toInt()}%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _accent,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isDownloading ? null : _downloadApk,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _accentLight,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: _isDownloading
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _accent,
                ),
              )
                  : const Icon(Icons.download_rounded, size: 20),
              label: Text(
                _isDownloading ? 'Downloading APK...' : 'Download APK',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}