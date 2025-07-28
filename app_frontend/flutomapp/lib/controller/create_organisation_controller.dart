import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../models/organisation_model.dart';

class CreateOrganizationController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final organizationNameController = TextEditingController();
  final organizationDescriptionController = TextEditingController();

  var selectedImage = Rxn<File>();
  var organizationData = CreateOrganizationData().obs;
  var statusMessage = 'Fill in the organization details'.obs;
  var isCreating = false.obs;

  final ImagePicker _picker = ImagePicker();

  Future<void> pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      selectedImage.value = File(image.path);
      organizationData.value.organisationLogo = image.path;
    }
  }

  Future<void> createOrganization() async {
    if (formKey.currentState!.validate()) {
      isCreating.value = true;
      statusMessage.value = 'Creating organization...';

      organizationData.value.organisationName = organizationNameController.text;
      organizationData.value.organisationDescription = organizationDescriptionController.text;

      // Simulate API calls
      await Future.delayed(Duration(seconds: 4));

      statusMessage.value = 'Organization created successfully!';
      isCreating.value = false;
    }
  }

  @override
  void onClose() {
    organizationNameController.dispose();
    organizationDescriptionController.dispose();
    super.onClose();
  }
}
