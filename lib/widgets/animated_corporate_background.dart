import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';
import 'dart:math' as math;

class AnimatedCorporateBackground extends StatefulWidget {
  final Widget child;

  const AnimatedCorporateBackground({super.key, required this.child});

  @override
  State<AnimatedCorporateBackground> createState() => _AnimatedCorporateBackgroundState();
}

class _AnimatedCorporateBackgroundState extends State<AnimatedCorporateBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeService>().isDarkMode;
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    // Define colors for the glowing orbs based on theme
    final Color orb1Color = isDark ? const Color(0xFF1E3A8A).withOpacity(0.5) : const Color(0xFFBFDBFE).withOpacity(0.6); // Blue
    final Color orb2Color = isDark ? const Color(0xFF0F766E).withOpacity(0.4) : const Color(0xFF99F6E4).withOpacity(0.5); // Teal
    final Color orb3Color = isDark ? const Color(0xFF4C1D95).withOpacity(0.4) : const Color(0xFFE9D5FF).withOpacity(0.5); // Purple

    final iconOpacity = isDark ? 0.05 : 0.08;
    final iconColor = theme.colorScheme.onSurface.withOpacity(iconOpacity);

    return Stack(
      children: [
        // Base background color
        Container(color: theme.scaffoldBackgroundColor),
        
        // Animated Orbs
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Stack(
              children: [
                // Orb 1
                Positioned(
                  left: (math.sin(_controller.value * 2 * math.pi) * 100) + (size.width * 0.1),
                  top: (math.cos(_controller.value * 2 * math.pi) * 100) + (size.height * 0.1),
                  child: Container(
                    width: size.width * 0.8,
                    height: size.width * 0.8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: orb1Color,
                    ),
                  ),
                ),
                // Orb 2
                Positioned(
                  right: (math.cos(_controller.value * 2 * math.pi) * 80) + (size.width * 0.05),
                  bottom: (math.sin(_controller.value * 2 * math.pi) * 120) + (size.height * 0.2),
                  child: Container(
                    width: size.width * 0.7,
                    height: size.width * 0.7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: orb2Color,
                    ),
                  ),
                ),
                // Orb 3
                Positioned(
                  left: (math.cos(_controller.value * 2 * math.pi + math.pi) * 150) + (size.width * 0.2),
                  top: (math.sin(_controller.value * 2 * math.pi + math.pi) * 150) + (size.height * 0.5),
                  child: Container(
                    width: size.width * 0.9,
                    height: size.width * 0.9,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: orb3Color,
                    ),
                  ),
                ),
              ],
            );
          },
        ),

        // Massive blur layer to create the frosted glass / ambient glow effect
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 80.0, sigmaY: 80.0),
            child: Container(
              color: isDark ? Colors.black.withOpacity(0.1) : Colors.white.withOpacity(0.1),
            ),
          ),
        ),

        // Floating outline icons
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Stack(
              children: [
                Positioned(
                  left: (math.cos(_controller.value * 2 * math.pi) * 40) + (size.width * 0.15),
                  top: (math.sin(_controller.value * 2 * math.pi) * 40) + (size.height * 0.25),
                  child: Transform.rotate(
                    angle: _controller.value * 2 * math.pi,
                    child: Icon(Icons.directions_car_outlined, size: 120, color: iconColor),
                  ),
                ),
                Positioned(
                  right: (math.sin(_controller.value * 2 * math.pi) * 50) + (size.width * 0.1),
                  top: (math.cos(_controller.value * 2 * math.pi) * 50) + (size.height * 0.6),
                  child: Transform.rotate(
                    angle: -_controller.value * 2 * math.pi,
                    child: Icon(Icons.description_outlined, size: 150, color: iconColor),
                  ),
                ),
                Positioned(
                  left: (math.cos(_controller.value * 2 * math.pi + math.pi/2) * 60) + (size.width * 0.4),
                  bottom: (math.sin(_controller.value * 2 * math.pi + math.pi/2) * 60) + (size.height * 0.1),
                  child: Transform.rotate(
                    angle: _controller.value * 2 * math.pi,
                    child: Icon(Icons.check_circle_outline_rounded, size: 100, color: iconColor),
                  ),
                ),
                Positioned(
                  right: (math.cos(_controller.value * 2 * math.pi + math.pi) * 30) + (size.width * 0.3),
                  top: (math.sin(_controller.value * 2 * math.pi + math.pi) * 30) + (size.height * 0.1),
                  child: Transform.rotate(
                    angle: -_controller.value * 2 * math.pi,
                    child: Icon(Icons.hexagon_outlined, size: 80, color: iconColor),
                  ),
                ),
              ],
            );
          },
        ),

        // The actual app content on top
        widget.child,
      ],
    );
  }
}
