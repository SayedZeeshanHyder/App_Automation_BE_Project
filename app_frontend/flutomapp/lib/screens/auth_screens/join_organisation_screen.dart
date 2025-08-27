import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../constants/api_constants.dart';
import '../../models/organisation_model.dart';
import '../../services/shared_preferences_service.dart';
import '../navigation_screen.dart';

class JoinOrganisationScreen extends StatefulWidget {
  const JoinOrganisationScreen({super.key});

  @override
  State<JoinOrganisationScreen> createState() => _JoinOrganisationScreenState();
}

class _JoinOrganisationScreenState extends State<JoinOrganisationScreen> {
  bool _isFetching = true;
  bool _isJoining = false;
  List<Organisation> _organisations = [];
  String? _selectedOrganisationId;
  String? _errorMessage;

  static const Color _primaryColor = Color(0xFF5E72EB);
  static const Color _backgroundColor = Color(0xFFF7F8FC);
  static const Color _primaryTextColor = Color(0xFF1D2939);
  static const Color _secondaryTextColor = Color(0xFF667085);
  static const Color _errorColor = Color(0xFFD92D20);

  @override
  void initState() {
    super.initState();
    _fetchOrganisations();
  }

  Future<void> _fetchOrganisations() async {
    setState(() {
      _isFetching = true;
      _errorMessage = null;
    });

    try {
      final String token = SharedPreferencesService.getToken();

      final Uri url = Uri.parse(ApiConstants.baseUrl + ApiConstants.getOrganisationsApi);
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _organisations = data.map((json) => Organisation.fromJson(json)).toList();
        });
      } else {
        final responseBody = json.decode(response.body);
        throw Exception(responseBody['message'] ?? 'Failed to load organisations.');
      }
    } on SocketException {
      _errorMessage = "No Internet connection. Please check your network.";
    } on TimeoutException {
      _errorMessage = "The request timed out. Please try again.";
    } catch (e) {
      _errorMessage = e.toString().replaceFirst("Exception: ", "");
    } finally {
      if (mounted) {
        setState(() => _isFetching = false);
      }
    }
  }

  Future<void> _joinOrganisation() async {
    if (_selectedOrganisationId == null) return;
    setState(() => _isJoining = true);

    try {
      final String token = SharedPreferencesService.getToken();

      final Uri url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.joinOrganisationApi}/$_selectedOrganisationId');
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        Get.offAll(() => NavigationScreen());

        _showSnackBar("Request to join organisation sent successfully.");
      } else {
        final responseBody = json.decode(response.body);
        throw Exception(responseBody['message'] ?? 'Failed to join organisation.');
      }
    } on SocketException {
      _showSnackBar("No Internet connection.", isError: true);
    } on TimeoutException {
      _showSnackBar("The request timed out.", isError: true);
    } catch (e) {
      _showSnackBar(e.toString().replaceFirst("Exception: ", ""), isError: true);
    } finally {
      if (mounted) {
        setState(() => _isJoining = false);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? _errorColor : Colors.green[600],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        elevation: 0,
        title: const Text('Join an Organisation', style: TextStyle(color: _primaryTextColor)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: _primaryTextColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _buildBody(),
            ),
            _buildJoinButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isFetching) {
      return const Center(child: CircularProgressIndicator(color: _primaryColor));
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: _secondaryTextColor, fontSize: 16)),
        ),
      );
    }
    if (_organisations.isEmpty) {
      return const Center(
        child: Text('No organisations found.', style: TextStyle(color: _secondaryTextColor, fontSize: 16)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _organisations.length,
      itemBuilder: (context, index) {
        final org = _organisations[index];
        final isSelected = _selectedOrganisationId == org.id;
        return _buildOrganisationCard(org, isSelected);
      },
    );
  }

  Widget _buildOrganisationCard(Organisation org, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedOrganisationId = org.id;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _primaryColor : Colors.grey.shade200,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: _primaryColor.withOpacity(0.1),
                blurRadius: 8,
                spreadRadius: 2,
              )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _primaryColor.withOpacity(0.1),
                  child: Text(
                    org.name.isNotEmpty ? org.name[0] : '?',
                    style: const TextStyle(color: _primaryColor, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    org.name,
                    style: const TextStyle(
                      color: _primaryTextColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle, color: _primaryColor),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              org.description,
              style: const TextStyle(color: _secondaryTextColor, fontSize: 15, height: 1.4),
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Owner: ${org.ownerName}',
                  style: const TextStyle(color: _secondaryTextColor, fontSize: 13),
                ),
                Text(
                  'Created: ${DateFormat.yMMMd().format(org.createdAt)}',
                  style: const TextStyle(color: _secondaryTextColor, fontSize: 13),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJoinButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: (_selectedOrganisationId == null || _isJoining) ? null : _joinOrganisation,
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
            shadowColor: _primaryColor.withOpacity(0.3),
            disabledBackgroundColor: Colors.grey.shade300,
          ),
          child: _isJoining
              ? const SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
          )
              : const Text(
            'Join Organisation',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
