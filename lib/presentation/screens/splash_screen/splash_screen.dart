import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:vnote/presentation/screens/onboarding_screens/onboarding_screens.dart';
import 'package:vnote/core/constants/app_colors.dart';
import 'package:vnote/core/constants/app_strings.dart';
import 'package:vnote/core/constants/app_typography.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: AnimatedSplashScreen(
        splash: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 200,
              child: LottieBuilder.asset(
                "assets/splash_screen/voice.json",
                delegates: LottieDelegates(
                  values: [
                    ValueDelegate.color(['**'], value: AppColors.red),
                    ValueDelegate.color([
                      'mic Outlines',
                      '**',
                    ], value: isDark ? AppColors.white : AppColors.white),
                  ],
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppStrings.appFirstName,
                  style: TextStyle(
                    fontSize: AppTypography.size48,
                    color: AppColors.red,
                    fontWeight: AppTypography.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  AppStrings.appSecondName,
                  style: TextStyle(
                    fontSize: AppTypography.size40,
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: AppTypography.bold,
                  ),
                ),
              ],
            ),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(seconds: 2),
              builder: (context, value, child) {
                return Opacity(opacity: value, child: child);
              },
              child: Text(
                AppStrings.appTagline,
                style: TextStyle(
                  fontSize: AppTypography.size18,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).textTheme.bodyMedium!.color,
                ),
              ),
            ),
          ],
        ),
        nextScreen: const OnBoardingScreen(),
        splashIconSize: 400,
        backgroundColor: Colors.transparent,
      ),
    );
  }
}
