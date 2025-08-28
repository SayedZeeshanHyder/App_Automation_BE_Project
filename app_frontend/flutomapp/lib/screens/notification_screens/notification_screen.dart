import 'dart:async';
import 'dart:convert';
import 'dart:io';

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
  String? _processingNotificationId; // Tracks the ID of the notification being processed

  // Define a professional color scheme
  static const Color _primaryColor = Color(0xFF5E72EB);
  static const Color _backgroundColor = Color(0xFFF7F8FC);
  static const Color _primaryTextColor = Color(0xFF1D2939);
  static const Color _secondaryTextColor = Color(0xFF667085);
  static const Color _errorColor = Color(0xFFD92D20);
  static const Color _successColor = Color(0xFF039855);

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
            _notifications = notificationData.map((json) => NotificationEntity.fromJson(json)).toList();
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
    // Prevent multiple clicks while a request is in progress
    if (_processingNotificationId != null) return;

    if (!mounted) return;
    setState(() {
      _processingNotificationId = notification.id;
    });

    try {
      final String token = SharedPreferencesService.getToken();
      final Uri url = Uri.parse(ApiConstants.baseUrl + ApiConstants.approveOrganisationApi);

      // The body of the request is the notification object itself
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
        _showSnackBar("Join request accepted successfully.", isError: false);
        // Refresh the notifications list to reflect the change
        await _fetchNotifications();
      } else {
        final responseBody = json.decode(response.body);
        throw Exception(responseBody['message'] ?? 'Failed to approve request.');
      }
    } on SocketException {
      _showSnackBar("No Internet connection. Please check your network.", isError: true);
    } on TimeoutException {
      _showSnackBar("The approval request timed out. Please try again.", isError: true);
    } catch (e) {
      _showSnackBar(e.toString().replaceFirst("Exception: ", ""), isError: true);
    } finally {
      if (mounted) {
        setState(() => _processingNotificationId = null);
      }
    }
  }

  Future<void> _rejectRequest(NotificationEntity notification) async {
    // This is a placeholder for the reject functionality.
    // You would implement it similarly to _acceptRequest,
    // likely calling a different endpoint (e.g., /organisation/reject).
    print("Rejected request for notification ID: ${notification.id}");
    _showSnackBar("Join request rejected.", isError: false); // Changed to false for visual feedback
    setState(() {
      _notifications.removeWhere((n) => n.id == notification.id);
    });
  }

  void _showSnackBar(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? _errorColor : _successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(SharedPreferencesService.getToken());
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        elevation: 0,
        title: const Text('Notifications', style: TextStyle(color: _primaryTextColor)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: _primaryTextColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
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

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _primaryColor));
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: _secondaryTextColor, fontSize: 16)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchNotifications,
                style: ElevatedButton.styleFrom(backgroundColor: _primaryColor),
                child: const Text("Try Again"),
              )
            ],
          ),
        ),
      );
    }
    if (_notifications.isEmpty) {
      return const Center(
        child: Text('You have no new notifications.', style: TextStyle(color: _secondaryTextColor, fontSize: 16)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        final notification = _notifications[index];
        return _buildNotificationCard(notification);
      },
    );
  }

  Widget _buildNotificationCard(NotificationEntity notification) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.notifications_active_outlined, color: _primaryColor, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.message,
                        style: const TextStyle(color: _primaryTextColor, fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat.yMMMd().add_jm().format(notification.createdAt),
                        style: const TextStyle(color: _secondaryTextColor, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            _buildActionButtons(notification),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(NotificationEntity notification) {
    // Check if this specific notification is being processed
    final bool isProcessing = _processingNotificationId == notification.id;

    switch (notification.category) {
      case 'join_request':
        return Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // If processing, show a loading indicator. Otherwise, show buttons.
              if (isProcessing)
                const SizedBox(
                  height: 36, // Match button height
                  child: Center(
                    child: CircularProgressIndicator(
                      color: _primaryColor,
                      strokeWidth: 2.5,
                    ),
                  ),
                )
              else ...[
                TextButton(
                  onPressed: () => _rejectRequest(notification),
                  style: TextButton.styleFrom(
                    backgroundColor: _errorColor.withOpacity(0.1),
                    foregroundColor: _errorColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Reject'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => _acceptRequest(notification),
                  style: TextButton.styleFrom(
                    backgroundColor: _successColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Accept'),
                ),
              ],
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}