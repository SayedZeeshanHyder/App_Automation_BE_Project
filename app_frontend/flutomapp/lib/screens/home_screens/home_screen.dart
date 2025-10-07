import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutomapp/screens/home_screens/create_project_screen.dart';
import 'package:flutomapp/screens/home_screens/project_details_screen.dart';
import 'package:flutomapp/screens/notification_screens/notification_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../constants/api_constants.dart';
import '../../models/project_model.dart';
import '../../services/shared_preferences_service.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  List<Project> _projects = [];
  String? _errorMessage;

  // Define a professional color scheme
  static const Color _primaryColor = Color(0xFF5E72EB);
  static const Color _backgroundColor = Color(0xFFF7F8FC);
  static const Color _primaryTextColor = Color(0xFF1D2939);
  static const Color _secondaryTextColor = Color(0xFF667085);
  static const Color _cardBackgroundColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _fetchProjects();
  }

  Future<void> _fetchProjects() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final String token = SharedPreferencesService.getToken(); // Fetch your auth token
      print(ApiConstants.baseUrl);
      print(token);
      final Uri url = Uri.parse(ApiConstants.baseUrl + ApiConstants.projectsApi);

      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _projects = data.map((json) => Project.fromJson(json)).toList();
          });
        }
      } else {
        final responseBody = json.decode(response.body);
        throw Exception(responseBody['message'] ?? 'Failed to load projects.');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: GestureDetector(
        onTap: (){
          Get.to(()=>CreateProjectScreen(),transition: Transition.downToUp);
        },
        child: Container(constraints: BoxConstraints(maxWidth: Get.width*0.4),padding: EdgeInsets.symmetric(horizontal: 10,vertical: 7.5),decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15,),
          color: _primaryColor,
        ),child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Icon(Icons.add,color: _cardBackgroundColor,),
            Text("Create Project",style: TextStyle(color: _cardBackgroundColor,fontWeight: FontWeight.bold),),
          ],
        ),),
      ),
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _cardBackgroundColor,
        elevation: 0.5,
        title: const Text(
          'Projects',
          style: TextStyle(color: _primaryTextColor, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: _primaryColor),
            onPressed: () {
              Get.to(()=>NotificationScreen(),transition: Transition.downToUp);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchProjects,
        color: _primaryColor,
        child: _buildBody(),
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
          child: Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _secondaryTextColor, fontSize: 16),
          ),
        ),
      );
    }

    if (_projects.isEmpty) {
      return const Center(
        child: Text(
          'No projects found.\nTap the + button to create one!',
          textAlign: TextAlign.center,
          style: TextStyle(color: _secondaryTextColor, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _projects.length,
      itemBuilder: (context, index) {
        final project = _projects[index];
        return _buildProjectCard(project);
      },
    );
  }

  // UPDATED WIDGET
  Widget _buildProjectCard(Project project) {
    return GestureDetector(
      onTap: (){
        Get.to(()=>ProjectDetailsScreen(project: project),transition: Transition.rightToLeft);
      },
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 16),
        shadowColor: _primaryColor.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                project.projectName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _primaryTextColor,
                ),
              ),
              const SizedBox(height: 12),

              // Stats Row: Screen Count and Status
              Row(
                children: [
                  Icon(Icons.layers_outlined, color: _secondaryTextColor, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '${project.listOfScreens.length} Screens',
                    style: const TextStyle(color: _secondaryTextColor, fontSize: 14),
                  ),
                  const Spacer(), // Pushes the status chip to the end
                  Chip(
                    label: Text(project.status),
                    backgroundColor: _primaryColor.withOpacity(0.1),
                    labelStyle: const TextStyle(color: _primaryColor, fontWeight: FontWeight.w500),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),

              const Divider(height: 24, thickness: 0.5),

              // Date Metadata
              Text(
                'Created: ${DateFormat.yMMMd().format(project.createdAt)}',
                style: const TextStyle(color: _secondaryTextColor, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                'Last built: ${DateFormat.yMMMd().add_jm().format(project.lastBuildAt)}',
                style: const TextStyle(color: _secondaryTextColor, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}