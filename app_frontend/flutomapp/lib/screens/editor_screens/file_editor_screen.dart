import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../models/project_entity.dart';

class FileEditorScreen extends StatefulWidget {
  final ProjectEntity file;
  final String projectName;
  final String content;


  const FileEditorScreen({
    Key? key,
    required this.file,
    required this.projectName,
    required this.content,
  }) : super(key: key);

  @override
  _FileEditorScreenState createState() => _FileEditorScreenState();
}

class _FileEditorScreenState extends State<FileEditorScreen> {
  late TextEditingController _textController;
  bool _isModified = false;
  bool _isSaving = false;
  int _currentLine = 1;
  int _currentColumn = 1;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.content);
    _textController.addListener(_onTextChanged);
    _updateCursorPosition();
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (!_isModified) {
      setState(() {
        _isModified = true;
      });
    }
    _updateCursorPosition();
  }

  void _updateCursorPosition() {
    final text = _textController.text;
    final selection = _textController.selection;
    if (selection.isValid) {
      final textBeforeCursor = text.substring(0, selection.baseOffset);
      final lines = textBeforeCursor.split('\n');
      setState(() {
        _currentLine = lines.length;
        _currentColumn = lines.last.length + 1;
      });
    }
  }

  Future<void> _saveFile() async {
    if (!_isModified) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // TODO: Implement actual save functionality
      // This would involve updating the zip file with new content
      await Future.delayed(const Duration(seconds: 1)); // Simulating save

      setState(() {
        _isModified = false;
        _isSaving = false;
      });

      Get.snackbar(
        'Success',
        'File saved successfully',
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFF10B981),
        colorText: Colors.white,
        borderRadius: 12,
        margin: const EdgeInsets.all(16),
        icon: const Icon(Icons.check_circle, color: Colors.white),
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      setState(() {
        _isSaving = false;
      });

      Get.snackbar(
        'Error',
        'Failed to save file: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
        borderRadius: 12,
        margin: const EdgeInsets.all(16),
        icon: const Icon(Icons.error, color: Colors.white),
        duration: const Duration(seconds: 3),
      );
    }
  }

  Future<bool> _onWillPop() async {
    if (!_isModified) return true;

    final result = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Unsaved Changes'),
        content: const Text('You have unsaved changes. Do you want to save before closing?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Discard'),
          ),
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _saveFile();
              Get.back(result: true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667EEA),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  String _getLanguageMode() {
    final extension = widget.file.extension?.toLowerCase();
    switch (extension) {
      case 'dart':
        return 'Dart';
      case 'yaml':
      case 'yml':
        return 'YAML';
      case 'json':
        return 'JSON';
      case 'xml':
        return 'XML';
      case 'gradle':
      case 'kts':
        return 'Gradle';
      case 'md':
        return 'Markdown';
      case 'txt':
        return 'Text';
      default:
        return 'Text';
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: const Color(0xFF1E1E1E), // Dark theme for code editor
        appBar: _buildAppBar(),
        body: Column(
          children: [
            _buildToolbar(),
            Expanded(child: _buildEditor()),
            _buildStatusBar(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF2D2D30),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () async {
          final canPop = await _onWillPop();
          if (canPop) Get.back();
        },
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.file.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            _getLanguageMode(),
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
      actions: [
        if (_isModified)
          Container(
            margin: const EdgeInsets.all(8),
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveFile,
              icon: _isSaving
                  ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : const Icon(Icons.save, size: 18),
              label: Text(_isSaving ? 'Saving...' : 'Save'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onPressed: _showOptionsMenu,
        ),
      ],
    );
  }

  Widget _buildToolbar() {
    return Container(
      height: 48,
      decoration: const BoxDecoration(
        color: Color(0xFF2D2D30),
        border: Border(bottom: BorderSide(color: Color(0xFF3E3E42), width: 1)),
      ),
      child: Row(
        children: [
          _buildToolbarButton(Icons.undo, 'Undo', () => _undo()),
          _buildToolbarButton(Icons.redo, 'Redo', () => _redo()),
          const VerticalDivider(color: Color(0xFF3E3E42), width: 1),
          _buildToolbarButton(Icons.search, 'Find', () => _showFindDialog()),
          _buildToolbarButton(Icons.find_replace, 'Replace', () => _showReplaceDialog()),
          const VerticalDivider(color: Color(0xFF3E3E42), width: 1),
          _buildToolbarButton(Icons.format_size, 'Font Size', () => _showFontSizeDialog()),
        ],
      ),
    );
  }

  Widget _buildToolbarButton(IconData icon, String tooltip, VoidCallback onPressed) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon, color: Colors.white.withOpacity(0.8), size: 20),
        onPressed: onPressed,
        splashRadius: 20,
      ),
    );
  }

  Widget _buildEditor() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
      ),
      child: Row(
        children: [
          _buildLineNumbers(),
          Expanded(
            child: TextField(
              controller: _textController,
              scrollController: _scrollController,
              style: const TextStyle(
                fontFamily: 'Consolas',
                fontSize: 14,
                color: Colors.white,
                height: 1.4,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
                fillColor: Color(0xFF1E1E1E),
                filled: true,
              ),
              maxLines: null,
              expands: true,
              keyboardType: TextInputType.multiline,
              textAlignVertical: TextAlignVertical.top,
              onTap: _updateCursorPosition,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineNumbers() {
    final lines = _textController.text.split('\n').length;
    return Container(
      width: 50,
      color: const Color(0xFF252526),
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: lines,
              itemBuilder: (context, index) {
                return Container(
                  height: 19.6, // Match the line height of the text field
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontFamily: 'Consolas',
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar() {
    return Container(
      height: 24,
      decoration: const BoxDecoration(
        color: Color(0xFF007ACC),
        border: Border(top: BorderSide(color: Color(0xFF3E3E42), width: 1)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Text(
            'Ln $_currentLine, Col $_currentColumn',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          const Spacer(),
          Text(
            '${_textController.text.length} characters',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          const SizedBox(width: 12),
          Text(
            _getLanguageMode(),
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  void _undo() {
    // Implement undo functionality
    Get.snackbar('Info', 'Undo functionality not implemented yet');
  }

  void _redo() {
    // Implement redo functionality
    Get.snackbar('Info', 'Redo functionality not implemented yet');
  }

  void _showFindDialog() {
    // Implement find dialog
    Get.snackbar('Info', 'Find functionality not implemented yet');
  }

  void _showReplaceDialog() {
    // Implement replace dialog
    Get.snackbar('Info', 'Replace functionality not implemented yet');
  }

  void _showFontSizeDialog() {
    // Implement font size dialog
    Get.snackbar('Info', 'Font size adjustment not implemented yet');
  }

  void _showOptionsMenu() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy All'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: _textController.text));
                Get.back();
                Get.snackbar('Success', 'Content copied to clipboard');
              },
            ),
            ListTile(
              leading: const Icon(Icons.select_all),
              title: const Text('Select All'),
              onTap: () {
                _textController.selection = TextSelection(
                  baseOffset: 0,
                  extentOffset: _textController.text.length,
                );
                Get.back();
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('File Info'),
              onTap: () {
                Get.back();
                _showFileInfo();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showFileInfo() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('File Information'),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildInfoRow('Name', widget.file.name),
            _buildInfoRow('Size', widget.file.formattedSize),
            _buildInfoRow('Type', _getLanguageMode()),
            _buildInfoRow('Lines', '${_textController.text.split('\n').length}'),
            _buildInfoRow('Characters', '${_textController.text.length}'),
            if (widget.file.modifiedDate != null)
              _buildInfoRow('Modified', widget.file.modifiedDate.toString()),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
