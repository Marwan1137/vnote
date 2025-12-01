// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class GradientIconBox extends StatelessWidget {
  final List<Color> gradientColors;
  final IconData icon;
  final Color iconColor;
  final double size;

  const GradientIconBox({
    super.key,
    required this.gradientColors,
    required this.icon,
    required this.iconColor,
    this.size = 90,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors.last.withOpacity(0.4),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Center(
        child: Container(
          height: size * 0.75,
          width: size * 0.75,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Icon(icon, size: size * 0.35, color: iconColor),
          ),
        ),
      ),
    );
  }
}
