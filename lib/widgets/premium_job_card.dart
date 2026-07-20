import 'package:flutter/material.dart';
import '../utils/bank_themes.dart';
import '../theme/app_theme.dart';
import '../services/theme_service.dart';
import 'package:provider/provider.dart';
import 'glass_card.dart';
import 'bouncing_widget.dart';

class PremiumJobCard extends StatelessWidget {
  final String title;
  final String bankName;
  final String jobId;
  final VoidCallback onTap;
  final double animationDelay;
  final bool hasDraft;

  const PremiumJobCard({
    super.key,
    required this.title,
    required this.bankName,
    required this.jobId,
    required this.onTap,
    this.animationDelay = 0.0,
    this.hasDraft = false,
  });

  @override
  Widget build(BuildContext context) {
    final bankTheme = BankTheme.getTheme(bankName);
    final theme = Theme.of(context);
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 500),
      tween: Tween<double>(begin: 0, end: 1),
      curve: Interval(animationDelay.clamp(0.0, 1.0), 1.0, curve: Curves.easeOutCubic),
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: BouncingWidget(
        onTap: onTap,
        child: GlassCard(
          margin: const EdgeInsets.only(bottom: 16),
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Status Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  border: Border(bottom: BorderSide(color: theme.colorScheme.outline.withOpacity(0.3), width: 1)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: bankTheme.primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              bankName,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: theme.colorScheme.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (hasDraft)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF79009).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFF79009)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.cloud_upload_rounded, size: 14, color: Color(0xFFF79009)),
                            SizedBox(width: 4),
                            Text(
                              'Pending',
                              style: TextStyle(
                                color: Color(0xFFF79009),
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              // Body
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Hero(
                      tag: 'job_title_$jobId',
                      child: Material(
                        color: Colors.transparent,
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onSurface,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.tag_rounded, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                        const SizedBox(width: 6),
                        Text(
                          jobId,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
