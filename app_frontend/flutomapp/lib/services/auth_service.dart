import 'dart:convert';

import 'package:flutomapp/constants/api_constants.dart';
import 'package:flutomapp/controller/create_organisation_controller.dart';
import 'package:flutomapp/controller/second_signup_controller.dart';
import 'package:flutomapp/models/sign_up_data.dart';
import 'package:flutomapp/screens/auth_screens/otp_verification_screen.dart';
import 'package:flutomapp/services/shared_preferences_service.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

class AuthService{

  static Future<void> signUp(SignUpData signUpData,bool isOwner)async {
    final uuid = Uuid();
    final body = {
      "userName": signUpData.userName,
      "email": signUpData.email,
      "password": signUpData.password,
      "role": signUpData.role,
      "deviceToken": uuid.v4().toString()
    };

    final response = await http.post(
        Uri.parse("${ApiConstants.baseUrl}/auth/register"), headers: {
      "Content-Type": "application/json",
    }, body: jsonEncode(body));

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      final String authToken = responseBody['token'];
      final String userId = responseBody['user']['id'];
      final String verificationCode = responseBody['verificationCode'];

      if (!isOwner) {
        await joinOrganization(authToken);
      } else {
        await createOrganization(authToken);
      }
      Get.offAll(()=>OtpVerificationScreen(verificationCode: verificationCode, authToken: authToken, userId: userId,),);
    }
  }

  static Future<void> joinOrganization(String authToken) async {
    final secondSignUpController = Get.find<SecondSignUpController>();
    secondSignUpController.isJoining.value = true;
    String organisationId = secondSignUpController.selectedOrganization.value!.id;
    SharedPreferencesService.storeOrganizationInfo(organisationId);
    final response = await http.post(
      Uri.parse("${ApiConstants.baseUrl}/organisation/join/$organisationId"),
      headers: {
        "Authorization":"Bearer $authToken",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      secondSignUpController.statusMessage.value = "Successfully joined the organization!";
    } else {
      secondSignUpController.statusMessage.value = "Failed to join the organization.";
    }
    secondSignUpController.isJoining.value = false;
  }

  static Future<void> createOrganization(String authToken) async {
    final createOrganizationController = Get.find<CreateOrganizationController>();
    createOrganizationController.isCreating.value = true;
    final body = {
      "organisationName": createOrganizationController.organizationData.value.organisationName,
      "organisationDescription": createOrganizationController.organizationData.value.organisationDescription,
      "organisationLogo": "https://example.com/logo.png",
    };
    final response = await http.post(
      Uri.parse("${ApiConstants.baseUrl}/organisation/create"),
      headers: {
        "Authorization":"Bearer $authToken",
        "Content-Type": "application/json",
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      final String organizationId = responseBody['organisation']['id'];
      SharedPreferencesService.storeOrganizationInfo(organizationId);
      createOrganizationController.statusMessage.value = "Successfully created an organization!";
    } else {
      createOrganizationController.statusMessage.value = "Failed to join the organization.";
    }
    createOrganizationController.isCreating.value = false;
  }

}