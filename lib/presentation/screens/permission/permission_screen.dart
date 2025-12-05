import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vnote/core/constants/app_colors.dart';
import 'package:vnote/core/constants/app_typography.dart';
import 'package:vnote/core/di/di.dart';
import 'package:vnote/presentation/cubit/recording/recording_cubit.dart';
import 'package:vnote/presentation/cubit/recording/recording_state.dart';
import 'package:vnote/presentation/screens/home_screen/home_screen.dart';

class PermissionScreen extends StatelessWidget {
  const PermissionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final cubit = getIt<RecordingCubit>();
        // Check permission on init, but only if not already granted
        cubit.checkPermission();
        return cubit;
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.mic, size: 120, color: AppColors.red),
                const SizedBox(height: 32),
                Text(
                  'Microphone Permission',
                  style: AppTypography.h3.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'VNote needs microphone access to record your voice notes and payments. This permission is required for the app to function properly.',
                  style: AppTypography.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                BlocConsumer<RecordingCubit, RecordingState>(
                  listener: (context, state) {
                    // Automatically navigate to home if permission is already granted
                    if (state is RecordingReady) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HomeScreen(),
                          ),
                        );
                      });
                    }
                  },
                  builder: (context, state) {
                    if (state is RecordingReady) {
                      return const CircularProgressIndicator();
                    }

                    if (state is RecordingPermissionDenied) {
                      return Column(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () async {
                              await context
                                  .read<RecordingCubit>()
                                  .requestPermission();
                            },
                            icon: const Icon(Icons.mic),
                            label: const Text('Grant Permission'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                              minimumSize: const Size(double.infinity, 56),
                            ),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: () async {
                              await context
                                  .read<RecordingCubit>()
                                  .openAppSettings();
                            },
                            icon: const Icon(Icons.settings),
                            label: const Text('Open Settings'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                              minimumSize: const Size(double.infinity, 56),
                            ),
                          ),
                        ],
                      );
                    }

                    // Initial state - show loading while checking
                    return const CircularProgressIndicator();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
