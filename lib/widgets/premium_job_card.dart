import 'package:flutter/material.dart';
import '../utils/bank_themes.dart';
import 'glass_card.dart';

class PremiumJobCard extends StatelessWidget {
  final String title;
  final String bankName;
  final String jobId;
  final VoidCallback onTap;
  final double animationDelay;

  const PremiumJobCard({
    super.key,
    required this.title,
    required this.bankName,
    required this.jobId,
    required this.onTap,
    this.animationDelay = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = BankTheme.getTheme(bankName);
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 700),
      tween: Tween<double>(begin: 0, end: 1),
      curve: Interval(animationDelay, 1.0, curve: Curves.easeOutCubic),
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset(0, 40 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: GlassCard(
        margin: const EdgeInsets.only(bottom: 20),
        padding: EdgeInsets.zero,
        borderRadius: 24.0,
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24.0),
                border: Border(left: BorderSide(color: theme.primaryColor, width: 6)),
                gradient: LinearGradient(
                  colors: [
                    theme.primaryColor.withValues(alpha: 0.1),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        bankName,
                        style: TextStyle(
                          color: theme.primaryColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Hero(
                      tag: 'job_title_$jobId',
                      child: Material(
                        color: Colors.transparent,
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                                letterSpacing: -0.5,
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.location_on_rounded, size: 20, color: Colors.grey.shade700),
                            const SizedBox(width: 8),
                            const Text(
                              'Pending Inspection',
                              style: TextStyle(
                                color: Colors.black87, 
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: theme.primaryColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: theme.primaryColor.withValues(alpha: 0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              )
                            ],
                          ),
                          child: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 18),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              right: 16,
              top: -12, // Overlaps the top edge of the card
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  'ID: $jobId',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
