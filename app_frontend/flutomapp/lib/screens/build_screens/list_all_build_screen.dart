import 'dart:convert';
import 'dart:io';
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
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(color: Colors.blue),
          ),
        );

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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('APK downloaded: $filePath'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );

          // Attempt to install the APK
          final result = await OpenFilex.open(filePath);

          if (result.type != ResultType.done) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Could not open APK: ${result.message}'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Download failed: ${response.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        Navigator.pop(context); // Close loading dialog if still open
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading APK: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Storage permission is required to download APK'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _betaTesting() {
    print('To be Implemented');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Beta Testing - To be Implemented'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'My Builds',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.science_outlined, color: Colors.blue),
            onPressed: _betaTesting,
            tooltip: 'Beta Testing',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchBuilds,
        color: Colors.blue,
        child: _isLoading && _builds.isEmpty
            ? const Center(
          child: CircularProgressIndicator(color: Colors.blue),
        )
            : _errorMessage != null && _builds.isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _fetchBuilds,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        )
            : _builds.isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 80,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 16),
              Text(
                'No builds yet',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        )
            : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _builds.length,
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
        ),
      ),
    );
  }
}