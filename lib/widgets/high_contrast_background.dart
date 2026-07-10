import 'package:flutter/material.dart';

class HighContrastBackground extends StatelessWidget {
  final Widget child;

  const HighContrastBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Stack(
      children: [
        // Base Background
        Container(color: theme.scaffoldBackgroundColor),
        
        // Bold Geometric Shape 1
        Positioned(
          top: -100,
          right: -100,
          child: Transform.rotate(
            angle: -0.2,
            child: Container(
              width: 300,
              height: 500,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(isDark ? 0.4 : 0.2),
                  width: 4,
                ),
              ),
            ),
          ),
        ),
        
        // Bold Geometric Shape 2
        Positioned(
          bottom: -50,
          left: -80,
          child: Transform.rotate(
            angle: 0.1,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(isDark ? 0.2 : 0.1),
                  width: 4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                  ),
                ],
              ),
            ),
          ),
        ),

        // Foreground content
        SafeArea(child: child),
      ],
    );
  }
}
