import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../constants/api_constants.dart';
import '../../models/notification_entity.dart';
import '../../services/shared_preferences_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  bool _isLoading = true;
  List<NotificationEntity> _notifications = [];
  String? _errorMessage;
  String? _processingNotificationId;

  // Professional Glassmorphism color scheme
  static const Color _primaryColor = Color(0xFF2D3FE7);
  static const Color _accentColor = Color(0xFF6C5DD3);
  static const Color _backgroundColor = Color(0xFFF8F9FD);
  static const Color _primaryTextColor = Color(0xFF0F1419);
  static const Color _secondaryTextColor = Color(0xFF536471);
  static const Color _errorColor = Color(0xFFEF4444);
  static const Color _successColor = Color(0xFF10B981);
  static const Color _glassBackground = Color(0xFFFEFEFF);
  static const Color _glassBorder = Color(0xFFE1E7F0);

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final String token = SharedPreferencesService.getToken();

      final Uri url = Uri.parse(ApiConstants.baseUrl + ApiConstants.getUserApi);
      final response = await http.get(
        url,
        headers: {"Authorization": "Bearer $token"},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> notificationData = data['user']?['notifications'] ?? [];
        if (mounted) {
          setState(() {
            _notifications = notificationData
                .map((json) => NotificationEntity.fromJson(json))
                .toList();
            _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          });
        }
      } else {
        final responseBody = json.decode(response.body);
        throw Exception(responseBody['message'] ?? 'Failed to load notifications.');
      }
    } on SocketException {
      _errorMessage = "No Internet connection. Please check your network.";
    } on TimeoutException {
      _errorMessage = "The request timed out. Please try again.";
    } catch (e) {
      _errorMessage = e.toString().replaceFirst("Exception: ", "");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _acceptRequest(NotificationEntity notification) async {
    if (_processingNotificationId != null) return;

    if (!mounted) return;
    setState(() {
      _processingNotificationId = notification.id;
    });

    try {
      final String token = SharedPreferencesService.getToken();
      final Uri url =
      Uri.parse(ApiConstants.baseUrl + ApiConstants.approveOrganisationApi);

      final String requestBody = json.encode(notification.toJson());

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: requestBody,
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        _showGlassSnackBar("Join request accepted successfully.", isError: false);
        await _fetchNotifications();
      } else {
        final responseBody = json.decode(response.body);
        throw Exception(responseBody['message'] ?? 'Failed to approve request.');
      }
    } on SocketException {
      _showGlassSnackBar("No Internet connection. Please check your network.",
          isError: true);
    } on TimeoutException {
      _showGlassSnackBar("The approval request timed out. Please try again.",
          isError: true);
    } catch (e) {
      _showGlassSnackBar(e.toString().replaceFirst("Exception: ", ""), isError: true);
    } finally {
      if (mounted) {
        setState(() => _processingNotificationId = null);
      }
    }
  }

  Future<void> _rejectRequest(NotificationEntity notification) async {
    print("Rejected request for notification ID: ${notification.id}");
    _showGlassSnackBar("Join request rejected.", isError: false);
    setState(() {
      _notifications.removeWhere((n) => n.id == notification.id);
    });
  }

  void _showGlassSnackBar(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: Colors.white,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: isError ? _errorColor : _successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        elevation: 0,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(SharedPreferencesService.getToken());
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: _backgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(90),
        child: _buildGlassAppBar(),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchNotifications,
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  _buildGlassBackButton(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Notifications',
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
                        if (!_isLoading)
                          Flexible(
                            child: Text(
                              '${_notifications.length} notification${_notifications.length != 1 ? 's' : ''}',
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassBackButton() {
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
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(14),
              child: const Center(
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: _primaryTextColor,
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
    if (_isLoading) {
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
              'Loading notifications...',
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

    if (_errorMessage != null) {
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
                      color: _errorColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.error_outline_rounded,
                      color: _errorColor,
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
                    onPressed: _fetchNotifications,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.refresh_rounded, size: 20),
                        SizedBox(width: 8),
                        Text('Try Again'),
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

    if (_notifications.isEmpty) {
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
                      Icons.notifications_off_outlined,
                      color: _secondaryTextColor.withOpacity(0.6),
                      size: 56,
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'No notifications yet',
                    style: TextStyle(
                      color: _primaryTextColor,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'You\'re all caught up!\nWe\'ll notify you when something new arrives',
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
      padding: const EdgeInsets.all(16),
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        final notification = _notifications[index];
        final isProcessing = _processingNotificationId == notification.id;
        return _buildNotificationCard(notification, isProcessing);
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

  Widget _buildNotificationCard(NotificationEntity notification, bool isProcessing) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: _glassBackground.withOpacity(0.65),
              borderRadius: BorderRadius.circular(20),
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
                  color: Colors.white.withOpacity(0.6),
                  blurRadius: 1,
                  offset: const Offset(-1, -1),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildGlassIconContainer(),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notification.message,
                              style: const TextStyle(
                                color: _primaryTextColor,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                height: 1.4,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.schedule_rounded,
                                  color: _secondaryTextColor.withOpacity(0.7),
                                  size: 14,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    _formatDateTime(notification.createdAt),
                                    style: TextStyle(
                                      color: _secondaryTextColor.withOpacity(0.8),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  _buildActionButtons(notification, isProcessing),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassIconContainer() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _primaryColor.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: const Icon(
            Icons.notifications_active_rounded,
            color: _primaryColor,
            size: 22,
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat.yMMMd().add_jm().format(dateTime);
    }
  }

  Widget _buildActionButtons(NotificationEntity notification, bool isProcessing) {
    switch (notification.category) {
      case 'join_request':
        return Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _backgroundColor.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _glassBorder.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: isProcessing
                    ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: _primaryColor,
                            strokeWidth: 2.5,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Processing...',
                          style: TextStyle(
                            color: _primaryColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                    : Row(
                  children: [
                    Expanded(
                      child: _buildRejectButton(notification),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildAcceptButton(notification),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildRejectButton(NotificationEntity notification) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _rejectRequest(notification),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: _errorColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _errorColor.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.close_rounded,
                    color: _errorColor,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Reject',
                    style: TextStyle(
                      color: _errorColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
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

  Widget _buildAcceptButton(NotificationEntity notification) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _acceptRequest(notification),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: _successColor.withOpacity(0.95),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _successColor.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Accept',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
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
}