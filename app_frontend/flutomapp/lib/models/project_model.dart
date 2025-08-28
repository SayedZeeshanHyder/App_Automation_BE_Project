import 'package:flutter/foundation.dart';

class Project {
  final String id;
  final String projectName;
  final String status;
  final DateTime createdAt;
  final DateTime lastBuildAt;
  final String organisationId;
  final List<ProjectScreen> listOfScreens;
  // New fields to handle the updated API response
  final List<dynamic> envVariables;
  final String? appIcon;
  final List<dynamic> androidPermissions;
  final bool firebaseConfigured;

  Project({
    required this.id,
    required this.projectName,
    required this.status,
    required this.createdAt,
    required this.lastBuildAt,
    required this.organisationId,
    required this.listOfScreens,
    // New fields
    required this.envVariables,
    this.appIcon,
    required this.androidPermissions,
    required this.firebaseConfigured,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    // Safely parse the list of screens
    var screenList = json['listOfScreens'] as List<dynamic>? ?? [];
    List<ProjectScreen> screens = screenList
        .map((screenJson) => ProjectScreen.fromJson(screenJson))
        .toList();

    return Project(
      id: json['id'] ?? '',
      projectName: json['projectName'] ?? 'Untitled Project',
      status: json['status'] ?? 'Unknown',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      lastBuildAt: DateTime.tryParse(json['lastBuildAt'] ?? '') ?? DateTime.now(),
      organisationId: json['organisationId'] ?? '',
      listOfScreens: screens,
      // Safely parse the new fields, providing default values
      envVariables: json['envVariables'] as List<dynamic>? ?? [],
      appIcon: json['appIcon'] as String?,
      androidPermissions: json['androidPermissions'] as List<dynamic>? ?? [],
      firebaseConfigured: json['firebaseConfigured'] as bool? ?? false,
    );
  }
}

class ProjectScreen {
  final String screenId;
  final String screenName;
  final String screenPrompt;
  final Map<String, dynamic> screenUI;
  final String screenCode;

  ProjectScreen({
    required this.screenId,
    required this.screenName,
    required this.screenPrompt,
    required this.screenUI,
    required this.screenCode,
  });

  factory ProjectScreen.fromJson(Map<String, dynamic> json) {
    return ProjectScreen(
      screenId: json['screenId'] ?? '',
      screenName: json['screenName'] ?? 'Untitled Screen',
      screenPrompt: json['screenPrompt'] ?? '',
      screenUI: json['screenUI'] is Map<String, dynamic> ? json['screenUI'] : {},
      screenCode: json['screenCode'] ?? '',
    );
  }
}