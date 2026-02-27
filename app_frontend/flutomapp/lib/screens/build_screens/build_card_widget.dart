import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/build_model.dart';
import 'build_details_screen.dart';

class BuildCard extends StatelessWidget {
  final BuildModel buildModel;

  const BuildCard({
    Key? key,
    required this.buildModel,
  }) : super(key: key);

  // Design tokens (matches BuildDetailsScreen)
  static const Color _white = Color(0xFFFFFFFF);
  static const Color _border = Color(0xFFEAECF0);
  static const Color _ink = Color(0xFF0D1117);
  static const Color _inkMuted = Color(0xFF6E7882);
  static const Color _accent = Color(0xFF1A56DB);
  static const Color _accentLight = Color(0xFFEBF0FF);
  static const Color _success = Color(0xFF0D9E6A);
  static const Color _successLight = Color(0xFFE6F7F1);
  static const Color _danger = Color(0xFFDC2626);
  static const Color _dangerLight = Color(0xFFFEF2F2);
  static const Color _warning = Color(0xFFD97706);
  static const Color _warningLight = Color(0xFFFFFBEB);
  static const Color _inkLight = Color(0xFFADB5BD);

  @override
  Widget build(BuildContext context) {
    final isSuccess = buildModel.success && buildModel.completed;
    final isFailed = buildModel.completed && !buildModel.success;
    final isInProgress = !buildModel.completed;

    Color statusColor;
    Color statusBg;
    IconData statusIcon;
    String statusLabel;

    if (isSuccess) {
      statusColor = _success;
      statusBg = _successLight;
      statusIcon = Icons.check_circle_rounded;
      statusLabel = 'Success';
    } else if (isFailed) {
      statusColor = _danger;
      statusBg = _dangerLight;
      statusIcon = Icons.cancel_rounded;
      statusLabel = 'Failed';
    } else {
      statusColor = _warning;
      statusBg = _warningLight;
      statusIcon = Icons.pending_rounded;
      statusLabel = 'Building';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    BuildDetailsScreen(buildModel: buildModel),
              ),
            );
          },
          splashColor: _accentLight,
          highlightColor: _accentLight.withOpacity(0.5),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: status icon + title + arrow
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(statusIcon, color: statusColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            buildModel.buildId ?? 'Untitled Build',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _ink,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            buildModel.statusMessage,
                            style: const TextStyle(
                              fontSize: 12,
                              color: _inkMuted,
                              height: 1.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        size: 13, color: _inkLight),
                  ],
                ),

                const SizedBox(height: 14),
                Container(height: 1, color: _border),
                const SizedBox(height: 12),

                // Bottom row: chips
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _buildChip(
                      Icons.person_outline_rounded,
                      buildModel.createdBy.userName,
                      _accent,
                      _accentLight,
                    ),
                    _buildChip(
                      Icons.timer_outlined,
                      _formatDuration(buildModel.buildDurationMs),
                      const Color(0xFFD97706),
                      const Color(0xFFFFFBEB),
                    ),
                    _buildChip(
                      Icons.calendar_today_rounded,
                      _formatDate(buildModel.createdAt),
                      const Color(0xFF7C3AED),
                      const Color(0xFFF5F3FF),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChip(
      IconData icon, String label, Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int? milliseconds) {
    if (milliseconds == null) return 'N/A';
    final d = Duration(milliseconds: milliseconds);
    return '${d.inMinutes}m ${d.inSeconds % 60}s';
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (_) {
      return dateString;
    }
  }
}