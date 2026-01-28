import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:open_filex/open_filex.dart';
import 'package:flutomapp/services/shared_preferences_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../constants/api_constants.dart';
import '../../models/build_model.dart';
import 'build_card_widget.dart';

class BuildsScreen extends StatefulWidget {
  const BuildsScreen({Key? key}) : super(key: key);

  @override
  State<BuildsScreen> createState() => _BuildsScreenState();
}

class _BuildsScreenState extends State<BuildsScreen> {
  List<BuildModel> _builds = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Professional Glassmorphism color scheme
  static const Color _primaryColor = Color(0xFF2D3FE7);
  static const Color _accentColor = Color(0xFF6C5DD3);
  static const Color _backgroundColor = Color(0xFFF8F9FD);
  static const Color _primaryTextColor = Color(0xFF0F1419);
  static const Color _secondaryTextColor = Color(0xFF536471);
  static const Color _glassBackground = Color(0xFFFEFEFF);
  static const Color _successColor = Color(0xFF10B981);
  static const Color _glassBorder = Color(0xFFE1E7F0);

  @override
  void initState() {
    super.initState();
    _fetchBuilds();
  }

  Future<void> _fetchBuilds() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = SharedPreferencesService.getToken();
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/build/organisation'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _builds = data.map((json) => BuildModel.fromJson(json)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load builds: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadAndInstallApk(String buildId, String buildVersion) async {
    // Request storage permission
    if (await Permission.storage.request().isGranted ||
        await Permission.manageExternalStorage.request().isGranted) {

      try {
        _showGlassLoadingDialog();

        final token = SharedPreferencesService.getToken();
        final response = await http.get(
          Uri.parse('${ApiConstants.baseUrl}/build/$buildId/download'),
          headers: {
            'Authorization': 'Bearer $token',
          },
        );

        Navigator.pop(context); // Close loading dialog

        if (response.statusCode == 200) {
          // Get the downloads directory
          final Directory? directory = await getExternalStorageDirectory();
          final String filePath = '${directory!.path}/app_$buildVersion.apk';

          // Save the APK file
          final File file = File(filePath);
          await file.writeAsBytes(response.bodyBytes);

          // Show success message
          _showGlassSnackBar(
            'APK downloaded successfully',
            _successColor,
            Icons.check_circle_rounded,
          );

          // Attempt to install the APK
          final result = await OpenFilex.open(filePath);

          if (result.type != ResultType.done) {
            _showGlassSnackBar(
              'Could not open APK: ${result.message}',
              Colors.orange,
              Icons.warning_rounded,
            );
          }
        } else {
          _showGlassSnackBar(
            'Download failed: ${response.statusCode}',
            Colors.red.shade400,
            Icons.error_rounded,
          );
        }
      } catch (e) {
        Navigator.pop(context); // Close loading dialog if still open
        _showGlassSnackBar(
          'Error downloading APK',
          Colors.red.shade400,
          Icons.error_rounded,
        );
      }
    } else {
      _showGlassSnackBar(
        'Storage permission is required',
        Colors.red.shade400,
        Icons.lock_rounded,
      );
    }
  }

  void _showGlassLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (context) => Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: _glassBackground.withOpacity(0.7),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _glassBorder.withOpacity(0.5),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  CircularProgressIndicator(
                    color: _primaryColor,
                    strokeWidth: 3,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Downloading...',
                    style: TextStyle(
                      color: _primaryTextColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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

  void _showGlassSnackBar(String message, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _betaTesting() {
    print('To be Implemented');
    _showGlassSnackBar(
      'Beta Testing - Coming Soon',
      _accentColor,
      Icons.science_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(90),
        child: _buildGlassAppBar(),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: _backgroundColor,
        ),
        child: RefreshIndicator(
          onRefresh: _fetchBuilds,
          color: _primaryColor,
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildGlassAppBar() {
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'My Builds',
                          style: TextStyle(
                            color: _primaryTextColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 24,
                            letterSpacing: -0.5,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Flexible(
                          child: Text(
                            '${_builds.length} build${_builds.length != 1 ? 's' : ''} available',
                            style: const TextStyle(
                              color: _secondaryTextColor,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildGlassIconButton(
                    icon: Icons.science_outlined,
                    onTap: _betaTesting,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassIconButton({required IconData icon, required VoidCallback onTap}) {
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
              onTap: onTap,
              borderRadius: BorderRadius.circular(14),
              child: Center(
                child: Icon(
                  icon,
                  color: _accentColor,
                  size: 22,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _builds.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildGlassContainer(
              child: Container(
                padding: const EdgeInsets.all(24),
                child: const CircularProgressIndicator(
                  color: _primaryColor,
                  strokeWidth: 3,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Loading builds...',
              style: TextStyle(
                color: _secondaryTextColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null && _builds.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _buildGlassContainer(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.error_outline_rounded,
                      color: Colors.red.shade400,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _primaryTextColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 24),
                  _buildGlassButton(
                    onPressed: _fetchBuilds,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.refresh_rounded, size: 20),
                        SizedBox(width: 8),
                        Text('Retry'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (_builds.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _buildGlassContainer(
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: _backgroundColor.withOpacity(0.5),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _glassBorder.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.inbox_outlined,
                      color: _secondaryTextColor.withOpacity(0.6),
                      size: 56,
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'No builds yet',
                    style: TextStyle(
                      color: _primaryTextColor,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Your app builds will appear here\nonce they are ready',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _secondaryTextColor,
                      fontSize: 14,
                      height: 1.5,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      physics: NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
      itemCount: _builds.length,
      shrinkWrap: true,
      itemBuilder: (context, index) {
        final build = _builds[index];
        return BuildCard(
          buildModel: build,
          onDownload: () => _downloadAndInstallApk(
            build.buildId,
            build.buildVersion ?? 'latest',
          ),
        );
      },
    );
  }

  Widget _buildGlassContainer({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            color: _glassBackground.withOpacity(0.6),
            borderRadius: BorderRadius.circular(24),
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
                color: Colors.white.withOpacity(0.5),
                blurRadius: 1,
                offset: const Offset(-1, -1),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildGlassButton({required VoidCallback onPressed, required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: _primaryColor.withOpacity(0.9),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _primaryColor.withOpacity(0.25),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                child: DefaultTextStyle(
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}