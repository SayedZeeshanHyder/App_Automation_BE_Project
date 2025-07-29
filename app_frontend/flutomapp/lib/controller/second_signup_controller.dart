import 'dart:convert';

import 'package:flutomapp/constants/api_constants.dart';
import 'package:flutomapp/services/shared_preferences_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../models/organisation_model.dart';

class SecondSignUpController extends GetxController {
  final searchController = TextEditingController();
  var isLoading = true.obs;
  var organizations = <Organization>[].obs;
  var filteredOrganizations = <Organization>[].obs;
  var selectedOrganization = Rxn<Organization>();
  var statusMessage = 'Select an organization to continue'.obs;
  var isJoining = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadOrganizations();
    searchController.addListener(_filterOrganizations);
  }

  Future<void> loadOrganizations() async {
    isLoading.value = true;

    String authToken = SharedPreferencesService.getToken();
    final response = await http.get(Uri.parse("${ApiConstants.baseUrl}/organisation"),headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $authToken",
    });
    if (response.statusCode == 200) {

        final List data = jsonDecode(response.body) as List;
        for(var org in data) {
          organizations.add(Organization(id: org['id'], organisationName: org['organisationName'], organisationLogo: org['organisationLogo'], organisationDescription: org['organisationDescription'], memberCount: org['members'].length));
        }
        filteredOrganizations.value = organizations;
      } else {
        Get.snackbar('Error',"${response.statusCode} ${response.body}");
      }
    filteredOrganizations.value = organizations;
    isLoading.value = false;
  }

  void _filterOrganizations() {
    final query = searchController.text.toLowerCase();
    if (query.isEmpty) {
      filteredOrganizations.value = organizations;
    } else {
      filteredOrganizations.value = organizations.where((org) =>
      org.organisationName.toLowerCase().contains(query) ||
          org.id.toLowerCase().contains(query)).toList();
    }
  }

  void selectOrganization(Organization org) {
    selectedOrganization.value = org;
    statusMessage.value = 'Organization selected: ${org.organisationName}';
  }

  Future<void> requestJoinOrganization() async {
    if (selectedOrganization.value == null) return;

    isJoining.value = true;
    statusMessage.value = 'Sending join request...';

    await Future.delayed(Duration(seconds: 4));

    statusMessage.value = 'Join request sent successfully! Waiting for approval.';
    isJoining.value = false;
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}