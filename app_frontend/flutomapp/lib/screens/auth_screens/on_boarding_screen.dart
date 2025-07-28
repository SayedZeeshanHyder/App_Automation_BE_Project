import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/on_boarding_controller.dart';

class OnboardingScreen extends StatelessWidget {
  final OnboardingController controller = Get.put(OnboardingController());

  OnboardingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Container(
                    width: size.width,
                    padding: EdgeInsets.symmetric(
                      horizontal: size.width * 0.06,
                      vertical: 16,
                    ),
                    child: Column(
                      children: [
                        // Header with Progress
                        _buildHeader(size),

                        // Main Content
                        Expanded(
                          child: Obx(() {
                            switch (controller.currentSection.value) {
                              case 0:
                                return _buildWelcomeSection(size);
                              case 1:
                                return _buildEducationSection(size);
                              case 2:
                                return _buildGetStartedSection(size);
                              default:
                                return _buildWelcomeSection(size);
                            }
                          }),
                        ),

                        // Bottom Navigation
                        _buildBottomNavigation(size),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(Size size) {
    return Container(
      margin: EdgeInsets.only(bottom: size.height * 0.02),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF8BC34A)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'ZAPP',
                  style: TextStyle(
                    fontSize: size.width * 0.06,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              Obx(() => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${controller.currentSection.value + 1}/3',
                  style: TextStyle(
                    fontSize: size.width * 0.04,
                    color: const Color(0xFF4CAF50),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )),
            ],
          ),
          SizedBox(height: size.height * 0.02),
          Obx(() => ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: controller.progress.value,
              backgroundColor: const Color(0xFF4CAF50).withOpacity(0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
              minHeight: 6,
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection(Size size) {
    return AnimatedBuilder(
      animation: controller.fadeAnimation,
      builder: (context, child) {
        return FadeTransition(
          opacity: controller.fadeAnimation,
          child: SlideTransition(
            position: controller.slideAnimation,
            child: ScaleTransition(
              scale: controller.scaleAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: size.width * 0.4,
                    height: size.width * 0.3,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(size.width * 0.08),
                    ),
                    child: Image.asset("assets/app_icon.png", fit: BoxFit.fill,),
                  ),

                  SizedBox(height: size.height * 0.02),

                  // Welcome Text
                  Text(
                    'Welcome to Zapp',
                    style: TextStyle(
                      fontSize: size.width * 0.08,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2E7D32),
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: size.height * 0.02),

                  Container(
                    constraints: BoxConstraints(maxWidth: size.width * 0.85),
                    child: Text(
                      'Create stunning mobile applications directly from your phone with the power of AI assistance',
                      style: TextStyle(
                        fontSize: size.width * 0.045,
                        color: Colors.grey[600],
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  SizedBox(height: size.height * 0.05),

                  // Feature Cards
                  _buildFeatureCard(
                    size: size,
                    icon: Icons.smartphone,
                    title: 'Mobile-First Development',
                    subtitle: 'Build apps anywhere, anytime using just your mobile device',
                  ),

                  SizedBox(height: size.width * 0.04),

                  _buildFeatureCard(
                    size: size,
                    icon: Icons.auto_awesome,
                    title: 'AI-Powered Creation',
                    subtitle: 'Smart assistance to help you build without coding expertise',
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEducationSection(Size size) {
    return AnimatedBuilder(
      animation: controller.fadeAnimation,
      builder: (context, child) {
        return FadeTransition(
          opacity: controller.fadeAnimation,
          child: SlideTransition(
            position: controller.slideAnimation,
            child: ScaleTransition(
              scale: controller.scaleAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Lottie Animation Placeholder
                  Container(
                    width: size.width * 0.6,
                    height: size.width * 0.6,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(size.width * 0.1),
                      border: Border.all(
                        color: const Color(0xFF4CAF50).withOpacity(0.1),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.code_rounded,
                        size: size.width * 0.2,
                        color: const Color(0xFF4CAF50).withOpacity(0.7),
                      ),
                      // Replace with: Lottie.asset('assets/animations/coding.json')
                    ),
                  ),

                  SizedBox(height: size.height * 0.04),

                  Text(
                    'How Zapp Works',
                    style: TextStyle(
                      fontSize: size.width * 0.07,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2E7D32),
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: size.height * 0.03),

                  // Process Steps
                  _buildProcessStep(
                    size: size,
                    stepNumber: '1',
                    title: 'Choose Your Approach',
                    description: 'Select between Developer Mode for advanced features or Simple Mode for easy drag-and-drop',
                  ),

                  SizedBox(height: size.width * 0.04),

                  _buildProcessStep(
                    size: size,
                    stepNumber: '2',
                    title: 'Design & Build',
                    description: 'Use our intuitive tools or let AI help you create beautiful, functional mobile apps',
                  ),

                  SizedBox(height: size.width * 0.04),

                  _buildProcessStep(
                    size: size,
                    stepNumber: '3',
                    title: 'Deploy & Share',
                    description: 'Test, refine, and publish your app to reach users across different platforms',
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGetStartedSection(Size size) {
    return AnimatedBuilder(
      animation: controller.fadeAnimation,
      builder: (context, child) {
        return FadeTransition(
          opacity: controller.fadeAnimation,
          child: SlideTransition(
            position: controller.slideAnimation,
            child: ScaleTransition(
              scale: controller.scaleAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Success Icon
                  Container(
                    width: size.width * 0.35,
                    height: size.width * 0.35,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4CAF50), Color(0xFF8BC34A)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4CAF50).withOpacity(0.3),
                          blurRadius: 25,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.rocket_launch_rounded,
                      size: size.width * 0.16,
                      color: Colors.white,
                    ),
                  ),

                  SizedBox(height: size.height * 0.04),

                  Text(
                    'Ready to Create?',
                    style: TextStyle(
                      fontSize: size.width * 0.08,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2E7D32),
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: size.height * 0.02),

                  Container(
                    constraints: BoxConstraints(maxWidth: size.width * 0.85),
                    child: Text(
                      'Join our community of creators and start building your dream mobile application today',
                      style: TextStyle(
                        fontSize: size.width * 0.045,
                        color: Colors.grey[600],
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  SizedBox(height: size.height * 0.05),

                  // Get Started Button
                  Container(
                    width: size.width * 0.8,
                    height: size.height * 0.07,
                    child: ElevatedButton(
                      onPressed: controller.navigateToLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        elevation: 8,
                        shadowColor: const Color(0xFF4CAF50).withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(size.height * 0.035),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Get Started',
                            style: TextStyle(
                              fontSize: size.width * 0.045,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: size.width * 0.02),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: size.width * 0.05,
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: size.height * 0.04),

                  // Stats Row
                  Container(
                    constraints: BoxConstraints(maxWidth: size.width * 0.9),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatItem(size, '10K+', 'Apps Built'),
                        Container(
                          width: 1,
                          height: size.height * 0.05,
                          color: Colors.grey[300],
                        ),
                        _buildStatItem(size, '5K+', 'Creators'),
                        Container(
                          width: 1,
                          height: size.height * 0.05,
                          color: Colors.grey[300],
                        ),
                        _buildStatItem(size, '4.9★', 'Rating'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomNavigation(Size size) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: size.height * 0.02),
      child: Obx(() {
        if (controller.currentSection.value < 2) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () {
                  controller.currentSection.value = 2;
                  controller.updateProgress();
                  controller.animationController.reset();
                  controller.animationController.forward();
                },
                child: Text(
                  'Skip',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: size.width * 0.04,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              Container(
                width: size.width * 0.15,
                height: size.width * 0.15,
                child: ElevatedButton(
                  onPressed: controller.nextSection,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    shape: const CircleBorder(),
                    padding: EdgeInsets.zero,
                    elevation: 6,
                    shadowColor: const Color(0xFF4CAF50).withOpacity(0.3),
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: size.width * 0.06,
                  ),
                ),
              ),
            ],
          );
        } else {
          return const SizedBox.shrink();
        }
      }),
    );
  }

  Widget _buildFeatureCard({
    required Size size,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: size.width * 0.85,
      padding: EdgeInsets.all(size.width * 0.05),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size.width * 0.04),
        border: Border.all(
          color: const Color(0xFF4CAF50).withOpacity(0.1),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4CAF50).withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: size.width * 0.12,
            height: size.width * 0.12,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4CAF50), Color(0xFF8BC34A)],
              ),
              borderRadius: BorderRadius.circular(size.width * 0.03),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: size.width * 0.06,
            ),
          ),
          SizedBox(width: size.width * 0.04),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: size.width * 0.04,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2E7D32),
                  ),
                ),
                SizedBox(height: size.height * 0.005),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: size.width * 0.035,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessStep({
    required Size size,
    required String stepNumber,
    required String title,
    required String description,
  }) {
    return Container(
      constraints: BoxConstraints(maxWidth: size.width * 0.9),
      margin: EdgeInsets.symmetric(horizontal: size.width * 0.02),
      padding: EdgeInsets.all(size.width * 0.04),
      decoration: BoxDecoration(
        color: const Color(0xFF4CAF50).withOpacity(0.05),
        borderRadius: BorderRadius.circular(size.width * 0.04),
        border: Border.all(
          color: const Color(0xFF4CAF50).withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: size.width * 0.11,
            height: size.width * 0.11,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4CAF50), Color(0xFF8BC34A)],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                stepNumber,
                style: TextStyle(
                  fontSize: size.width * 0.045,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(width: size.width * 0.035),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  constraints: BoxConstraints(maxWidth: size.width * 0.65),
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: size.width * 0.04,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2E7D32),
                    ),
                    overflow: TextOverflow.visible,
                    softWrap: true,
                  ),
                ),
                SizedBox(height: size.height * 0.008),
                Container(
                  constraints: BoxConstraints(maxWidth: size.width * 0.65),
                  child: Text(
                    description,
                    style: TextStyle(
                      fontSize: size.width * 0.033,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                    overflow: TextOverflow.visible,
                    softWrap: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(Size size, String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: size.width * 0.05,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF4CAF50),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: size.width * 0.03,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}