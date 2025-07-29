import 'package:flutomapp/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../constants/app_colors.dart';
import '../../controller/create_organisation_controller.dart';
import '../../controller/second_signup_controller.dart';
import '../../controller/sign_up_controller.dart';
import '../../models/organisation_model.dart';

class SecondSignUpScreen extends StatelessWidget {
  final SignUpController signUpController = Get.find<SignUpController>();
  final SecondSignUpController secondSignUpController = Get.put(SecondSignUpController());

  @override
  Widget build(BuildContext context) {
    final role = signUpController.selectedRole.value;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.primaryText),
          onPressed: () => Get.back(),
        ),
        title: Text(
          role == 'Owner' ? 'Create Organization' : 'Join Organization',
          style: TextStyle(
            color: AppColors.primaryText,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: role == 'Owner'
          ? _buildCreateOrganizationView()
          : _buildJoinOrganizationView(),
    );
  }

  Widget _buildJoinOrganizationView() {
    final controller = Get.put(SecondSignUpController());

    return SingleChildScrollView(
      padding: EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchHeader(),
          SizedBox(height: 20),
          _buildSearchField(controller),
          SizedBox(height: 24),
          _buildOrganizationsList(controller),
          SizedBox(height: 24),
          _buildContinueButton(controller),
          SizedBox(height: 16),
          _buildStatusMessage(controller),
        ],
      ),
    );
  }

  Widget _buildCreateOrganizationView() {
    final controller = Get.put(CreateOrganizationController());

    return SingleChildScrollView(
      padding: EdgeInsets.all(24.0),
      child: Form(
        key: controller.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCreateHeader(),
            SizedBox(height: 30),
            _buildImagePicker(controller),
            SizedBox(height: 24),
            _buildOrganizationNameField(controller),
            SizedBox(height: 20),
            _buildOrganizationDescriptionField(controller),
            SizedBox(height: 40),
            _buildCreateButton(controller),
            SizedBox(height: 16),
            _buildCreateStatusMessage(controller),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Find Your Organization',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryText,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Search by organization name or ID',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.secondaryText,
          ),
        ),
      ],
    );
  }

  Widget _buildCreateHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Create Organization',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryText,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Set up your organization profile',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.secondaryText,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField(SecondSignUpController controller) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: AppColors.lightShadow,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller.searchController,
        decoration: InputDecoration(
          hintText: 'Search organizations...',
          prefixIcon: Icon(Icons.search, color: AppColors.primaryGreen),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: AppColors.cardBackground,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildOrganizationsList(SecondSignUpController controller) {
    return Obx(() {
      if (controller.isLoading.value) {
        return Container(
          height: 200,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
                ),
                SizedBox(height: 16),
                Text(
                  'Loading organizations...',
                  style: TextStyle(color: AppColors.secondaryText),
                ),
              ],
            ),
          ),
        );
      }

      return Column(
        children: controller.filteredOrganizations.map((org) {
          return _buildOrganizationCard(org, controller);
        }).toList(),
      );
    });
  }

  Widget _buildOrganizationCard(Organization org, SecondSignUpController controller) {
    return Obx(() {
      final isSelected = controller.selectedOrganization.value?.id == org.id;

      return AnimatedContainer(
        duration: Duration(milliseconds: 300),
        margin: EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primaryGreen : AppColors.borderColor,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? AppColors.shadowColor : AppColors.lightShadow,
              blurRadius: isSelected ? 15 : 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ExpansionTile(
          onExpansionChanged: (expanded) {
            if (expanded) {
              controller.selectOrganization(org);
            }
          },
          leading: CircleAvatar(
            backgroundColor: AppColors.primaryGreenOpacity10,
            child: Text(
              org.organisationName[0].toUpperCase(),
              style: TextStyle(
                color: AppColors.primaryGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            org.organisationName,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.primaryText,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ID: ${org.id}',
                style: TextStyle(
                  color: AppColors.lightText,
                  fontSize: 12,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '${org.memberCount} members',
                style: TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    org.organisationDescription,
                    style: TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: controller.isJoining.value
                          ? null
                          : () => controller.requestJoinOrganization(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: controller.isJoining.value
                          ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.whiteText),
                        ),
                      )
                          : Text(
                        'Request to Join',
                        style: TextStyle(
                          color: AppColors.whiteText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildContinueButton(SecondSignUpController controller) {
    return Obx(() => Container(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: controller.selectedOrganization.value != null && !controller.isJoining.value
            ? () {
                AuthService.signUp(signUpController.signUpData.value, false);
        }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        child: Text(
          'Continue',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.whiteText,
          ),
        ),
      ),
    ));
  }

  Widget _buildStatusMessage(SecondSignUpController controller) {
    return Obx(() => AnimatedContainer(
      duration: Duration(milliseconds: 300),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryGreenOpacity05,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: AppColors.primaryGreen,
            size: 20,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              controller.statusMessage.value,
              style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    ));
  }

  Widget _buildImagePicker(CreateOrganizationController controller) {
    return Obx(() => GestureDetector(
      onTap: controller.pickImage,
      child: Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.primaryGreenOpacity05,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primaryGreen,
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: controller.selectedImage.value != null
            ? ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.file(
            controller.selectedImage.value!,
            fit: BoxFit.cover,
          ),
        )
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 48,
              color: AppColors.primaryGreen,
            ),
            SizedBox(height: 12),
            Text(
              'Upload Organization Logo',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryText,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Tap to select image',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    ));
  }

  Widget _buildOrganizationNameField(CreateOrganizationController controller) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      child: TextFormField(
        controller: controller.organizationNameController,
        decoration: InputDecoration(
          labelText: 'Organization Name',
          prefixIcon: Icon(Icons.business_outlined, color: AppColors.primaryGreen),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.primaryGreen, width: 2),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter organization name';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildOrganizationDescriptionField(CreateOrganizationController controller) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      child: TextFormField(
        controller: controller.organizationDescriptionController,
        maxLines: 4,
        decoration: InputDecoration(
          labelText: 'Organization Description',
          prefixIcon: Padding(
            padding: EdgeInsets.only(bottom: 60),
            child: Icon(Icons.description_outlined, color: AppColors.primaryGreen),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.primaryGreen, width: 2),
          ),
          alignLabelWithHint: true,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter organization description';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildCreateButton(CreateOrganizationController controller) {
    return Obx(() => SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: controller.isCreating.value
            ? null
            : (){
          AuthService.signUp(signUpController.signUpData.value,true);
          },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        child: controller.isCreating.value
            ? Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.whiteText),
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Creating...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.whiteText,
              ),
            ),
          ],
        )
            : Text(
          'Create Organization',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.whiteText,
          ),
        ),
      ),
    ));
  }

  Widget _buildCreateStatusMessage(CreateOrganizationController controller) {
    return Obx(() => AnimatedContainer(
      duration: Duration(milliseconds: 300),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryGreenOpacity05,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: AppColors.primaryGreen,
            size: 20,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              controller.statusMessage.value,
              style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    ));
  }
}