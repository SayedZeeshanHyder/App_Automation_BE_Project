import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_syntax_view/flutter_syntax_view.dart';

class CodeViewerScreen extends StatelessWidget {
  final String code;
  final String title;
  const CodeViewerScreen({
    super.key,
    required this.code,
    this.title = 'Code Viewer',
  });

  @override
  Widget build(BuildContext context) {
    const Color appBarColor = Color(0xFF252526);
    const Color backgroundColor = Color(0xFF1E1E1E);
    const Color primaryTextColor = Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(color: primaryTextColor)),
        backgroundColor: appBarColor,
        elevation: 1,
        iconTheme: const IconThemeData(color: primaryTextColor),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_all_outlined),
            tooltip: 'Copy Code',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Code copied to clipboard!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: SyntaxView(
        code: code,
        syntax: Syntax.DART,
        syntaxTheme: SyntaxTheme.vscodeDark(),
        withLinesCount: true,
        expanded: true,
      ),
    );
  }
}