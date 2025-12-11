import 'package:flutter/material.dart';
import 'package:vnote/core/constants/app_colors.dart';

class UnifiedMicFab extends StatefulWidget {
  final VoidCallback onPressed;
  final String heroTag;

  const UnifiedMicFab({
    super.key,
    required this.onPressed,
    required this.heroTag,
  });

  @override
  State<UnifiedMicFab> createState() => _UnifiedMicFabState();
}

class _UnifiedMicFabState extends State<UnifiedMicFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handlePress() {
    _controller.forward().then((_) {
      _controller.reverse();
    });
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: FloatingActionButton(
        onPressed: _handlePress,
        backgroundColor: AppColors.red,
        heroTag: widget.heroTag,
        elevation: 4,
        highlightElevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.mic, color: Colors.white),
      ),
    );
  }
}
