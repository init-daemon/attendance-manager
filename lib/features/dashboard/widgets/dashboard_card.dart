import 'package:flutter/material.dart';

class DashboardCard extends StatelessWidget {
  final int count;
  final String label;
  final Color? color;
  final IconData? icon;

  const DashboardCard({
    super.key,
    required this.count,
    required this.label,
    this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gradient = LinearGradient(
      colors: [
        Color.alphaBlend(
          Colors.black.withOpacity(0.35),
          (color ?? theme.colorScheme.primary),
        ),
        Color.alphaBlend(
          Colors.black.withOpacity(0.55),
          (color ?? theme.colorScheme.primary),
        ),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      shadowColor:
          color?.withOpacity(0.3) ?? theme.colorScheme.primary.withOpacity(0.3),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = MediaQuery.of(context).size.width;
          final isMobile = screenWidth < 600;
          return Container(
            width: isMobile ? screenWidth - 32 : 160,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(24),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) Icon(icon, size: 36, color: Colors.white),
                const SizedBox(height: 8),
                Text(
                  '$count',
                  style: theme.textTheme.displayMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(1, 2),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    letterSpacing: 0.5,
                    shadows: [
                      Shadow(
                        color: Colors.black12,
                        blurRadius: 2,
                        offset: Offset(1, 1),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
