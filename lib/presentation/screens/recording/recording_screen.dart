// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vnote/core/constants/app_colors.dart';
import 'package:vnote/core/constants/app_strings.dart';
import 'package:vnote/core/constants/app_typography.dart';
import 'package:vnote/presentation/cubit/recording/recording_cubit.dart';
import 'package:vnote/presentation/cubit/recording/recording_state.dart';
import 'package:vnote/presentation/widgets/app_bar_actions.dart';

enum RecordingMode { note, payment, event }

class RecordingScreen extends StatefulWidget {
  final RecordingMode mode;

  const RecordingScreen({super.key, this.mode = RecordingMode.note});

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // When app resumes, check permission again (user might have granted it in settings)
    if (state == AppLifecycleState.resumed) {
      context.read<RecordingCubit>().checkPermission();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => context.read<RecordingCubit>()..checkPermission(),
      child: _RecordingScreenContent(mode: widget.mode),
    );
  }
}

class _RecordingScreenContent extends StatelessWidget {
  final RecordingMode mode;

  const _RecordingScreenContent({required this.mode});

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppStrings.recordingTitle, style: AppTypography.h5),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
          actions: const [AppBarActions()],
        ),
        body: BlocConsumer<RecordingCubit, RecordingState>(
          listener: (context, state) {
            if (state is RecordingProcessed) {
              if (mode == RecordingMode.payment ||
                  mode == RecordingMode.event) {
                // For payments and events, return the transcription string
                Navigator.pop(context, state.transcription);
              } else {
                // For notes, return true to indicate note was created
                Navigator.pop(context, true);
              }
            } else if (state is RecordingError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error,
                ),
              );
            } else if (state is RecordingPermissionDenied) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error,
                  action: SnackBarAction(
                    label: 'Grant',
                    textColor: Colors.white,
                    onPressed: () {
                      context.read<RecordingCubit>().requestPermission();
                    },
                  ),
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is RecordingInitial ||
                state is RecordingPermissionRequested) {
              return _buildInitialState(context);
            }

            if (state is RecordingPermissionDenied) {
              return _buildPermissionDenied(context);
            }

            if (state is RecordingReady) {
              return _buildReadyState(context);
            }

            if (state is RecordingInProgress) {
              return _buildRecordingState(context, state.duration);
            }

            if (state is RecordingTranscribing) {
              return _buildProcessingState(
                context,
                AppStrings.transcribingAudio,
              );
            }

            if (state is RecordingProcessing) {
              final message = mode == RecordingMode.payment
                  ? 'Processing payment...'
                  : mode == RecordingMode.event
                  ? 'Processing event...'
                  : AppStrings.generatingNote;
              return _buildProcessingState(context, message);
            }

            if (state is RecordingFormatSelection) {
              // For payments and events, skip format selection and return transcription directly
              if (mode == RecordingMode.payment ||
                  mode == RecordingMode.event) {
                // Return transcription immediately for payments and events
                final message = mode == RecordingMode.payment
                    ? 'Processing payment...'
                    : 'Processing event...';
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.pop(context, state.transcription);
                });
                return _buildProcessingState(context, message);
              }
              return _buildFormatSelectionState(context, state);
            }

            if (state is RecordingProcessed) {
              return _buildSuccessState(context);
            }

            if (state is RecordingError) {
              return _buildErrorState(context, state.message);
            }

            return _buildInitialState(context);
          },
        ),
      ),
    );
  }

  Widget _buildInitialState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text('Initializing...', style: AppTypography.bodyLarge),
        ],
      ),
    );
  }

  Widget _buildPermissionDenied(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mic_off, size: 80, color: AppColors.error),
            const SizedBox(height: 24),
            Text(
              AppStrings.recordingPermissionDenied,
              style: AppTypography.h4,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Please grant microphone permission to record voice notes.',
              style: AppTypography.bodyMedium.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () async {
                await context.read<RecordingCubit>().requestPermission();
                // Check again after a short delay to see if permission was granted
                await Future.delayed(const Duration(milliseconds: 500));
                if (context.mounted) {
                  context.read<RecordingCubit>().checkPermission();
                }
              },
              icon: const Icon(Icons.mic),
              label: const Text('Grant Permission'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () async {
                await context.read<RecordingCubit>().openAppSettings();
              },
              icon: const Icon(Icons.settings),
              label: const Text('Open Settings'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.red.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.mic, size: 100, color: AppColors.red),
          ),
          const SizedBox(height: 48),
          Text(
            AppStrings.recordingSubtitle,
            style: AppTypography.h5,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 64),
          ElevatedButton.icon(
            onPressed: () {
              context.read<RecordingCubit>().startRecording();
            },
            icon: const Icon(Icons.mic, size: 32),
            label: Text('Start Recording', style: AppTypography.buttonLarge),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingState(BuildContext context, Duration duration) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated recording indicator
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.8, end: 1.0),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeInOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppColors.red.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.mic, size: 80, color: Colors.white),
                  ),
                ),
              );
            },
            onEnd: () {
              // Restart animation
            },
          ),
          const SizedBox(height: 48),
          Text(
            _formatDuration(duration),
            style: AppTypography.displayMedium.copyWith(
              color: AppColors.red,
              fontWeight: AppTypography.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.recordingInProgress,
            style: AppTypography.bodyLarge.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 64),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Cancel button
              OutlinedButton.icon(
                onPressed: () {
                  context.read<RecordingCubit>().cancelRecording();
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.close),
                label: const Text(AppStrings.cancelRecording),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Stop button
              ElevatedButton.icon(
                onPressed: () {
                  context.read<RecordingCubit>().stopRecording();
                },
                icon: const Icon(Icons.stop),
                label: Text(
                  AppStrings.stopRecording,
                  style: AppTypography.buttonMedium,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.red),
          ),
          const SizedBox(height: 24),
          Text(message, style: AppTypography.h5, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            'Please wait...',
            style: AppTypography.bodyMedium.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatSelectionState(
    BuildContext context,
    RecordingFormatSelection state,
  ) {
    return _FormatSelectionContent(state: state);
  }

  Widget _buildSuccessState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, size: 100, color: AppColors.green),
          const SizedBox(height: 24),
          Text(
            AppStrings.noteCreatedSuccessfully,
            style: AppTypography.h4,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: AppColors.error),
            const SizedBox(height: 24),
            Text(
              message,
              style: AppTypography.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormatSelectionContent extends StatefulWidget {
  final RecordingFormatSelection state;

  const _FormatSelectionContent({required this.state});

  @override
  State<_FormatSelectionContent> createState() =>
      _FormatSelectionContentState();
}

class _FormatSelectionContentState extends State<_FormatSelectionContent> {
  // Default to bullet points if available, otherwise full text
  late bool useBulletPoints;

  @override
  void initState() {
    super.initState();
    useBulletPoints = widget.state.processedNote.bulletPoints.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Choose Format', style: AppTypography.h5),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Preview', style: AppTypography.h6),
                  const SizedBox(height: 12),
                  // Title preview
                  Text(
                    widget.state.processedNote.title,
                    style: AppTypography.h5.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Tags preview
                  if (widget.state.processedNote.tags.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.state.processedNote.tags.map((tag) {
                        return Chip(
                          label: Text('#$tag', style: AppTypography.caption),
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primaryContainer,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                  ],
                  // Content preview
                  Text(
                    useBulletPoints
                        ? (widget.state.processedNote.bulletPoints.isEmpty
                              ? widget.state.transcription
                              : widget.state.processedNote.bulletPoints
                                    .map((point) => '• $point')
                                    .join('\n'))
                        : widget.state.transcription,
                    style: AppTypography.bodyMedium,
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Format selection
            Text('Choose Format', style: AppTypography.h5),
            const SizedBox(height: 16),
            StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    // Bullet Points option (only show if bullet points are available)
                    if (widget.state.processedNote.bulletPoints.isNotEmpty)
                      InkWell(
                        onTap: () {
                          setState(() {
                            useBulletPoints = true;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: useBulletPoints
                                  ? AppColors.red
                                  : Theme.of(context).colorScheme.outline
                                        .withValues(alpha: 0.3),
                              width: useBulletPoints ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            color: useBulletPoints
                                ? AppColors.red.withValues(alpha: 0.1)
                                : Colors.transparent,
                          ),
                          child: Row(
                            children: [
                              Radio<bool>(
                                value: true,
                                groupValue: useBulletPoints,
                                onChanged: (value) {
                                  setState(() {
                                    useBulletPoints = value ?? true;
                                  });
                                },
                                activeColor: AppColors.red,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Bullet Points',
                                      style: AppTypography.h6,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Organized key points from your recording',
                                      style: AppTypography.bodySmall.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (widget.state.processedNote.bulletPoints.isNotEmpty)
                      const SizedBox(height: 12),
                    // Full Text option
                    InkWell(
                      onTap: () {
                        setState(() {
                          useBulletPoints = false;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: !useBulletPoints
                                ? AppColors.red
                                : Theme.of(
                                    context,
                                  ).colorScheme.outline.withValues(alpha: 0.3),
                            width: !useBulletPoints ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: !useBulletPoints
                              ? AppColors.red.withValues(alpha: 0.1)
                              : Colors.transparent,
                        ),
                        child: Row(
                          children: [
                            Radio<bool>(
                              value: false,
                              groupValue: useBulletPoints,
                              onChanged: (value) {
                                setState(() {
                                  useBulletPoints = value ?? false;
                                });
                              },
                              activeColor: AppColors.red,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Full Text', style: AppTypography.h6),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Complete transcription as recorded',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),
            // Create Note button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  context.read<RecordingCubit>().createNoteWithFormat(
                    recording: widget.state.recording,
                    transcription: widget.state.transcription,
                    processedNote: widget.state.processedNote,
                    useBulletPoints: useBulletPoints,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('Create Note', style: AppTypography.buttonLarge),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
