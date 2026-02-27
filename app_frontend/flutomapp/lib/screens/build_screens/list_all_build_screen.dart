import 'dart:convert';
import 'dart:ui';

import 'package:flutomapp/services/shared_preferences_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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

  // Design tokens
  static const Color _white = Color(0xFFFFFFFF);
  static const Color _surface = Color(0xFFF7F8FA);
  static const Color _border = Color(0xFFEAECF0);
  static const Color _ink = Color(0xFF0D1117);
  static const Color _inkMuted = Color(0xFF6E7882);
  static const Color _accent = Color(0xFF1A56DB);
  static const Color _accentLight = Color(0xFFEBF0FF);

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
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _builds = data.map((json) => BuildModel.fromJson(json)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load builds (${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Something went wrong. Pull down to retry.';
        _isLoading = false;
      });
    }
  }

  int get _successCount =>
      _builds.where((b) => b.success && b.completed).length;
  int get _failedCount =>
      _builds.where((b) => b.completed && !b.success).length;
  int get _inProgressCount => _builds.where((b) => !b.completed).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: _fetchBuilds,
        color: _accent,
        child: _buildBody(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      shadowColor: _border,
      titleSpacing: 20,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'My Builds',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _ink,
              letterSpacing: -0.5,
            ),
          ),
          if (_builds.isNotEmpty)
            Text(
              '${_builds.length} build${_builds.length != 1 ? 's' : ''}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: _inkMuted,
              ),
            ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _border),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _builds.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: _accent,
              strokeWidth: 2.5,
            ),
            SizedBox(height: 16),
            Text(
              'Loading builds...',
              style: TextStyle(
                fontSize: 13,
                color: _inkMuted,
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
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  size: 40,
                  color: Color(0xFFDC2626),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: _ink,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _fetchBuilds,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: _white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_builds.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: _accentLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.inbox_outlined,
                  size: 44,
                  color: _accent,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'No builds yet',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your app builds will appear here\nonce they are ready.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: _inkMuted,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics()),
      slivers: [
        // Summary bar
        SliverToBoxAdapter(
          child: _buildSummaryBar(),
        ),

        // Build list
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) => BuildCard(buildModel: _builds[index]),
              childCount: _builds.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryItem(
              'Total',
              _builds.length.toString(),
              const Color(0xFF1A56DB),
              const Color(0xFFEBF0FF),
            ),
          ),
          Container(width: 1, height: 36, color: _border),
          Expanded(
            child: _buildSummaryItem(
              'Success',
              _successCount.toString(),
              const Color(0xFF0D9E6A),
              const Color(0xFFE6F7F1),
            ),
          ),
          Container(width: 1, height: 36, color: _border),
          Expanded(
            child: _buildSummaryItem(
              'Failed',
              _failedCount.toString(),
              const Color(0xFFDC2626),
              const Color(0xFFFEF2F2),
            ),
          ),
          if (_inProgressCount > 0) ...[
            Container(width: 1, height: 36, color: _border),
            Expanded(
              child: _buildSummaryItem(
                'Running',
                _inProgressCount.toString(),
                const Color(0xFFD97706),
                const Color(0xFFFFFBEB),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
      String label, String value, Color color, Color bgColor) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: _inkMuted,
          ),
        ),
      ],
    );
  }
}