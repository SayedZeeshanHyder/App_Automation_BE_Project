import 'package:flutomapp/models/user_model.dart';

class BuildModel {
  final String id;
  final String buildId;
  final String projectId;
  final String organisationId;
  final UserModel createdBy;
  final String instructions;
  final int initialScreenIndex;
  final String statusMessage;
  final bool completed;
  final bool success;
  final String? errorMessage;
  final List<String> logs;
  final String? apkLocation;
  final String? buildVersion;
  final String createdAt;
  final String? completedAt;
  final int? buildDurationMs;

  BuildModel({
    required this.id,
    required this.buildId,
    required this.projectId,
    required this.organisationId,
    required this.createdBy,
    required this.instructions,
    required this.initialScreenIndex,
    required this.statusMessage,
    required this.completed,
    required this.success,
    this.errorMessage,
    required this.logs,
    required this.apkLocation,
    required this.buildVersion,
    required this.createdAt,
    this.completedAt,
    this.buildDurationMs,
  });

  factory BuildModel.fromJson(Map<String, dynamic> json) {
    return BuildModel(
      id: json['id'],
      buildId: json['buildId'],
      projectId: json['projectId'],
      organisationId: json['organisationId'],
      createdBy: UserModel.fromJson(json['createdBy']),
      instructions: json['instructions'] ?? '',
      initialScreenIndex: json['initialScreenIndex'],
      statusMessage: json['statusMessage'],
      completed: json['completed'],
      success: json['success'],
      errorMessage: json['errorMessage'],
      logs: List<String>.from(json['logs']),
      apkLocation: json['apkLocation'],
      buildVersion: json['buildVersion'],
      createdAt: json['createdAt'],
      completedAt: json['completedAt'],
      buildDurationMs: json['buildDurationMs'],
    );
  }
}