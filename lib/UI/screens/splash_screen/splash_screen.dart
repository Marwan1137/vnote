import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:vnote/UI/screens/home_screen/home_screen.dart';
import 'package:vnote/core/constants/app_colors.dart';
import 'package:vnote/core/constants/app_strings.dart';
import 'package:vnote/core/constants/app_typography.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.black),
      child: AnimatedSplashScreen(
        splash: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 200,
              child: LottieBuilder.asset(
                "assets/splash_screen/mic.json",
                delegates: LottieDelegates(
                  values: [
                    ValueDelegate.color(['**'], value: AppColors.primaryRed),
                    ValueDelegate.color([
                      'mic Outlines',
                      '**',
                    ], value: AppColors.lightSurface),
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
                    color: AppColors.primaryRed,
                    fontWeight: AppTypography.bold,
                  ),
                ),
                Text(
                  AppStrings.appSecondName,
                  style: TextStyle(
                    fontSize: AppTypography.size40,
                    color: AppColors.lightSurface,
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
                  fontSize: AppTypography.size20,
                  fontWeight: FontWeight.w500,
                  color: AppColors.lightSurface,
                ),
              ),
            ),
          ],
        ),
        nextScreen: const HomeScreen(),
        splashIconSize: 400,
        backgroundColor: Colors.transparent,
      ),
    );
  }
}
