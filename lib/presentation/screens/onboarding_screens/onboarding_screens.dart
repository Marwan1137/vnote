// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:vnote/presentation/screens/home_screen/home_screen.dart';
import 'package:vnote/presentation/screens/onboarding_screens/widgets/gradient_icon_box.dart';
import 'package:vnote/core/constants/app_colors.dart';
import 'package:vnote/core/constants/app_strings.dart';
import 'package:vnote/core/constants/app_typography.dart';

class OnBoardingScreen extends StatefulWidget {
  const OnBoardingScreen({super.key});
  @override
  State<OnBoardingScreen> createState() => _OnBoardingScreenState();
}

class _OnBoardingScreenState extends State<OnBoardingScreen> {
  final controller = PageController();
  int currentPage = 0;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Widget buildPage({
    required String title,
    required String subtitle,
    GradientIconBox? child,
  }) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (child != null) child,
          const SizedBox(height: 32),
          Text(
            title,
            style: Theme.of(context).textTheme.displayLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = Theme.of(context).iconTheme.color!;

    return Scaffold(
      body: Container(
        padding: const EdgeInsets.only(bottom: 80),
        child: PageView(
          onPageChanged: (index) {
            setState(() {
              currentPage = index;
            });
          },
          controller: controller,
          children: [
            buildPage(
              title: AppStrings.onboardingTitle1,
              subtitle: AppStrings.onboardingSubtitle1,
              child: GradientIconBox(
                gradientColors: [AppColors.orange, AppColors.red],
                icon: Icons.mic,
                size: 300,
                iconColor: iconColor,
              ),
            ),
            buildPage(
              title: AppStrings.onboardingTitle2,
              subtitle: AppStrings.onboardingSubtitle2,
              child: GradientIconBox(
                gradientColors: [AppColors.purple, AppColors.red],
                icon: FontAwesomeIcons.brain,
                size: 300,
                iconColor: iconColor,
              ),
            ),
            buildPage(
              title: AppStrings.onboardingTitle3,
              subtitle: AppStrings.onboardingSubtitle3,
              child: GradientIconBox(
                gradientColors: [AppColors.green, AppColors.red],
                icon: FontAwesomeIcons.lock,
                size: 300,
                iconColor: iconColor,
              ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        height: 80,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildButton(
                context: context,
                text: AppStrings.skipButton,
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                ),
              ),
              Center(
                child: SmoothPageIndicator(
                  onDotClicked: (index) => controller.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                  ),
                  controller: controller,
                  count: 3,
                  effect: SwapEffect(
                    dotHeight: 12,
                    dotWidth: 12,
                    dotColor: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.3),
                    activeDotColor: AppColors.red,
                  ),
                ),
              ),
              _buildButton(
                context: context,
                text: currentPage == 2
                    ? AppStrings.getStartedButton
                    : AppStrings.nextButton,
                onPressed: () => (currentPage == 2)
                    ? Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HomeScreen(),
                        ),
                      )
                    : controller.nextPage(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton({
    required BuildContext context,
    required String text,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.onSurface),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: TextButton(
        onPressed: onPressed,
        child: Text(
          text,
          style: TextStyle(
            fontSize: text.length > 5
                ? AppTypography.size12
                : AppTypography.size14,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
