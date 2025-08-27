import 'package:flutomapp/screens/auth_screens/sign_up_screen.dart';
import 'package:flutomapp/services/shared_preferences_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class OnBoardingScreen extends StatefulWidget {
  const OnBoardingScreen({super.key});

  @override
  State<OnBoardingScreen> createState() => _OnBoardingScreenState();
}

class _OnBoardingScreenState extends State<OnBoardingScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  int _currentPage = 0;

  // Define a professional color scheme
  static const Color _primaryTextColor = Color(0xFF1D2939);
  static const Color _secondaryTextColor = Color(0xFF667085);

  // Define a list of accent colors using shades of a single color (blue)
  final List<Color> _accentColors = [
    const Color(0xFF6A82FB), // Lighter, welcoming blue
    const Color(0xFF5E72EB), // The primary, vibrant blue
    const Color(0xFF4A5BCF), // Deeper, conclusive blue
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
    // Re-trigger animation for the new page
    _animationController.reset();
    _animationController.forward();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _getStarted();
    }
  }

  void _skipToEnd() {
    _pageController.animateToPage(
      2,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
    );
  }

  void _getStarted() async{
    await SharedPreferencesService.visitOnboarding();
    Get.to(()=>SignUpScreen(),transition: Transition.rightToLeft,);
  }

  @override
  Widget build(BuildContext context) {
    // Set status bar icons to dark for better visibility on a white background
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Gradient - animated based on current page
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topRight,
                radius: 1.5,
                colors: [
                  _accentColors[_currentPage].withOpacity(0.1),
                  Colors.white,
                ],
                stops: const [0.0, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Top Bar with Skip Button
                _buildTopBar(),

                // Page View for Onboarding content
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    children: [
                      _OnboardingPageContent(
                        imagePath: 'assets/app_icon.png',
                        title: 'Build Apps Without Coding',
                        description:
                        'Transform your brilliant app ideas into reality with our revolutionary Flutter Automation App. No coding experience required!',
                        accentColor: _accentColors[0],
                      ),
                      _OnboardingPageContent(
                        imagePath: 'assets/app_icon.png',
                        title: 'Two Powerful Modes',
                        description:
                        'Choose between Normal Mode for beginners or Developer Mode for advanced users, both designed to accelerate your app journey.',
                        accentColor: _accentColors[1],
                      ),
                      _OnboardingPageContent(
                        imagePath: 'assets/app_icon.png',
                        title: 'Ready to Launch?',
                        description:
                        'Build, test, and deploy your apps with our powerful cloud infrastructure. From idea to app store in record time!',
                        accentColor: _accentColors[2],
                      ),
                    ],
                  ),
                ),

                // Bottom Navigation (Indicators & Button)
                _buildBottomBar(screenHeight),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 60, // Slightly increased height for better visual balance
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, -0.5),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: _currentPage < 2
            ? TextButton(
          key: const ValueKey('skipButton'),
          onPressed: _skipToEnd,
          style: TextButton.styleFrom(
            foregroundColor: _secondaryTextColor.withOpacity(0.8),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          child: const Text('Skip'),
        )
            : const SizedBox(
            key: ValueKey('emptySizedBox'),
            height: 48), // Maintain height when button is gone
      ),
    );
  }

  Widget _buildBottomBar(double screenHeight) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 24.0,
        vertical: screenHeight * 0.03,
      ),
      child: Column(
        children: [
          // Page Indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              3,
                  (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 8,
                width: _currentPage == index ? 28 : 8,
                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? _accentColors[_currentPage]
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          SizedBox(height: screenHeight * 0.04),

          // Next/Get Started Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentColors[_currentPage], // Dynamic color
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4, // More pronounced shadow for impressiveness
                shadowColor: _accentColors[_currentPage].withOpacity(0.4),
              ),
              child: Text(
                _currentPage == 2 ? 'Get Started' : 'Next',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700, // Slightly bolder text
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// A reusable widget for the content of each onboarding page
class _OnboardingPageContent extends StatelessWidget {
  final String imagePath;
  final String title;
  final String description;
  final Color accentColor; // Added for dynamic coloring

  const _OnboardingPageContent({
    required this.imagePath,
    required this.title,
    required this.description,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // Access animations from the parent state
    final parentState =
    context.findAncestorStateOfType<_OnBoardingScreenState>()!;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: FadeTransition(
        opacity: parentState._fadeAnimation,
        child: SlideTransition(
          position: parentState._slideAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: screenHeight * 0.05),

              // Enhanced App Icon Container
              Container(
                width: screenWidth * 0.45,
                height: screenWidth * 0.45,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(screenWidth * 0.1),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accentColor.withOpacity(0.7),
                      accentColor.withOpacity(0.9),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Center(
                  child: Image.asset(
                    imagePath,
                    width: screenWidth * 0.25, // Adjust icon size
                    height: screenWidth * 0.25,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.flutter_dash, // Fallback Flutter icon
                      size: screenWidth * 0.25,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.08),

              // Title Text
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _OnBoardingScreenState._primaryTextColor,
                  fontSize: 30, // Slightly larger title
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16),

              // Description Text
              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _OnBoardingScreenState._secondaryTextColor,
                  fontSize: 17, // Slightly larger description
                  height: 1.5,
                ),
              ),
              SizedBox(height: screenHeight * 0.05),
            ],
          ),
        ),
      ),
    );
  }
}