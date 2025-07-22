import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/encryption_service.dart';
import '../../services/file_service.dart';
import '../../models/project_entity.dart';
import '../editor_screens/file_editor_screen.dart';

class ProjectDetailsScreen extends StatefulWidget {
  final String projectName;
  final String? initialPath;

  const ProjectDetailsScreen({
    Key? key,
    required this.projectName,
    this.initialPath,
  }) : super(key: key);

  @override
  _ProjectDetailsScreenState createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen> with TickerProviderStateMixin {
  List<ProjectEntity> projectContents = [];
  List<String> currentPathSegments = [];
  bool isLoading = true;
  String? error;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  Uint8List? _cachedZipData;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    if (widget.initialPath != null && widget.initialPath!.isNotEmpty) {
      currentPathSegments = widget.initialPath!.split('/');
    }

    _loadProjectStructure();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadProjectStructure() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      // Only decrypt once and cache the result
      if (_cachedZipData == null) {
        final zhspData = await FileService.readZhspFile(widget.projectName);
        _cachedZipData = EncryptionService.decryptZhspFile(zhspData);
      }

      List<ProjectEntity> contents;
      if (currentPathSegments.isEmpty) {
        contents = await FileService.getProjectRootContents(_cachedZipData!); // ✅ NEW FUNCTION
      } else {
        final folderPath = currentPathSegments.join('/');
        contents = await FileService.getProjectFolderContents(_cachedZipData!, folderPath);
      }

      setState(() {
        projectContents = contents; // ✅ NEW VARIABLE
        isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  void _navigateToFolder(ProjectEntity directory) {
    setState(() {
      currentPathSegments.add(directory.name);
      _animationController.reset();
    });
    _loadProjectStructure();
  }

  void _navigateUp() {
    if (currentPathSegments.isNotEmpty) {
      setState(() {
        currentPathSegments.removeLast();
        _animationController.reset();
      });
      _loadProjectStructure();
    }
  }

  void _navigateToPath(int index) {
    if (index < currentPathSegments.length) {
      setState(() {
        currentPathSegments = currentPathSegments.take(index + 1).toList();
        _animationController.reset();
      });
      _loadProjectStructure();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          if (currentPathSegments.isNotEmpty)
            SliverToBoxAdapter(child: _buildBreadcrumb()),
          SliverToBoxAdapter(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          ),
        ),
        child: FlexibleSpaceBar(
          title: Text(
            currentPathSegments.isEmpty
                ? widget.projectName
                : currentPathSegments.last,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          centerTitle: false,
          titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
        ),
      ),
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: Icon(
            currentPathSegments.isEmpty ? Icons.arrow_back_ios : Icons.arrow_upward,
            color: Colors.white,
            size: 20,
          ),
          onPressed: currentPathSegments.isEmpty ? () => Get.back() : _navigateUp,
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
            onPressed: _loadProjectStructure,
          ),
        ),
      ],
    );
  }

  Widget _buildBreadcrumb() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.folder_open, size: 20, color: Color(0xFF667EEA)),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        currentPathSegments.clear();
                        _animationController.reset();
                      });
                      _loadProjectStructure();
                    },
                    child: Text(
                      widget.projectName,
                      style: TextStyle(
                        color: currentPathSegments.isEmpty ? Color(0xFF667EEA) : Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  for (int i = 0; i < currentPathSegments.length; i++) ...[
                    const Text(' / ', style: TextStyle(color: Color(0xFF64748B))),
                    GestureDetector(
                      onTap: () => _navigateToPath(i),
                      child: Text(
                        currentPathSegments[i],
                        style: TextStyle(
                          color: i == currentPathSegments.length - 1
                              ? Color(0xFF667EEA)
                              : Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return _buildLoadingState();
    }

    if (error != null) {
      return _buildErrorState();
    }

    if (projectContents.isEmpty) {
      return _buildEmptyState();
    }

    return _buildContentList();
  }

  Widget _buildLoadingState() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667EEA)),
            ),
            SizedBox(height: 24),
            Text(
              'Loading folder contents...',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Color(0xFFDC2626),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Failed to load folder',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              error!.length > 100 ? '${error!.substring(0, 100)}...' : error!,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loadProjectStructure,
              icon: const Icon(Icons.refresh, size: 20),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667EEA),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.folder_open_rounded,
                size: 48,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Folder is Empty',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'This folder contains no files or subfolders',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentList() {
    final directories = projectContents.where((item) => item.type == ProjectEntityType.directory).toList();
    final files = projectContents.where((item) => item.type == ProjectEntityType.file).toList();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (directories.isNotEmpty) ...[
              _buildSectionHeader('Folders', directories.length, Icons.folder_rounded),
              const SizedBox(height: 12),
              ...directories.map((item) => _buildDirectoryCard(item)),
              const SizedBox(height: 24),
            ],
            if (files.isNotEmpty) ...[
              _buildSectionHeader('Files', files.length, Icons.description_rounded),
              const SizedBox(height: 12),
              ...files.map((item) => _buildFileCard(item)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF667EEA).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: const Color(0xFF667EEA)),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF667EEA).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF667EEA),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDirectoryCard(ProjectEntity directory) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _navigateToFolder(directory),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF9A56), Color(0xFFFFD56D)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.folder_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        directory.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Tap to open',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Color(0xFFCBD5E1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFileCard(ProjectEntity file) {
    final extension = file.extension;
    final fileInfo = _getFileInfo(extension);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: () => _onFileTap(file),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: fileInfo['colors'] as List<Color>,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    fileInfo['icon'] as IconData,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        file.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            fileInfo['type'] as String,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (file.formattedSize.isNotEmpty) ...[
                            Text(
                              ' • ${file.formattedSize}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (extension != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (fileInfo['colors'] as List<Color>)[0].withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      extension.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: (fileInfo['colors'] as List<Color>)[0],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _getFileInfo(String? extension) {
    switch (extension?.toLowerCase()) {
      case 'dart':
        return {
          'icon': Icons.code_rounded,
          'colors': [const Color(0xFF0175C2), const Color(0xFF13B9FD)],
          'type': 'Dart File',
        };
      case 'yaml':
      case 'yml':
        return {
          'icon': Icons.settings_rounded,
          'colors': [const Color(0xFF8B5CF6), const Color(0xFFA78BFA)],
          'type': 'YAML Configuration',
        };
      case 'md':
        return {
          'icon': Icons.description_rounded,
          'colors': [const Color(0xFF059669), const Color(0xFF10B981)],
          'type': 'Markdown',
        };
      case 'json':
        return {
          'icon': Icons.data_object_rounded,
          'colors': [const Color(0xFFDC2626), const Color(0xFFEF4444)],
          'type': 'JSON Data',
        };
      case 'xml':
        return {
          'icon': Icons.code_rounded,
          'colors': [const Color(0xFFEA580C), const Color(0xFFF97316)],
          'type': 'XML File',
        };
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'gif':
        return {
          'icon': Icons.image_rounded,
          'colors': [const Color(0xFFDB2777), const Color(0xFFEC4899)],
          'type': 'Image',
        };
      case 'gradle':
        return {
          'icon': Icons.build_rounded,
          'colors': [const Color(0xFF16A085), const Color(0xFF1ABC9C)],
          'type': 'Gradle Build',
        };
      case 'properties':
        return {
          'icon': Icons.tune_rounded,
          'colors': [const Color(0xFF7C3AED), const Color(0xFF8B5CF6)],
          'type': 'Properties',
        };
      default:
        return {
          'icon': Icons.description_rounded,
          'colors': [const Color(0xFF6B7280), const Color(0xFF9CA3AF)],
          'type': 'File',
        };
    }
  }

  void _onFileTap(ProjectEntity file) async {

    if (FileService.isTextFile(file.extension)) {
      try {
        // Show loading dialog
        Get.dialog(
          const Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading file content...'),
                  ],
                ),
              ),
            ),
          ),
          barrierDismissible: false,
        );

        // Construct the full file path
        final fullPath = currentPathSegments.isEmpty
            ? 'sample/${file.name}'  // Assuming 'sample' is your project root
            : 'sample/${currentPathSegments.join('/')}/${file.name}';

        // Get file content
        final content = await FileService.getFileContent(_cachedZipData!, fullPath);

        // Close loading dialog
        Get.back();

        // Navigate to editor
        Get.to(
              () => FileEditorScreen(
            file: file,
            projectName: widget.projectName,
            content: content,
          ),
          transition: Transition.rightToLeft,
          duration: const Duration(milliseconds: 300),
        );

      } catch (e) {
        // Close loading dialog if open
        if (Get.isDialogOpen ?? false) {
          Get.back();
        }

        Get.snackbar(
          'Error',
          'Failed to open file: ${e.toString()}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFEF4444),
          colorText: Colors.white,
          borderRadius: 12,
          margin: const EdgeInsets.all(16),
          icon: const Icon(Icons.error_outline, color: Colors.white),
          duration: const Duration(seconds: 3),
        );
      }
    } else {
      // Show info for non-text files
      Get.snackbar(
        'File Info',
        '${file.name} ${file.formattedSize.isNotEmpty ? "(${file.formattedSize})" : ""}\nThis file type cannot be edited',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF6366F1),
        colorText: Colors.white,
        borderRadius: 12,
        margin: const EdgeInsets.all(16),
        icon: const Icon(Icons.info_outline, color: Colors.white),
        duration: const Duration(seconds: 3),
      );
    }
  }
}
