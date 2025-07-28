import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
    // Simulate API call
    await Future.delayed(Duration(seconds: 2));

    organizations.value = [
      Organization(
        id: 'org_001',
        organisationName: 'Tech Innovators Inc.',
        organisationLogo: 'https://example.com/logo1.png',
        organisationDescription: 'Leading technology company focused on AI and ML solutions.',
        memberCount: 150,
      ),
      Organization(
        id: 'org_002',
        organisationName: 'Digital Solutions Ltd.',
        organisationLogo: 'https://example.com/logo2.png',
        organisationDescription: 'Full-stack development and digital transformation services.',
        memberCount: 85,
      ),
      Organization(
        id: 'org_003',
        organisationName: 'StartUp Hub',
        organisationLogo: 'https://example.com/logo3.png',
        organisationDescription: 'Innovation-driven startup accelerator and development house.',
        memberCount: 42,
      ),
    ];

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

    // Simulate API calls
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