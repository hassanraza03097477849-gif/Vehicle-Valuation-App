import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/connectivity_service.dart';
import '../services/sync_service.dart';
import '../widgets/premium_job_card.dart';
import 'forms/dynamic_form_screen.dart';
import 'all_surveys_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isOnline = context.watch<ConnectivityService>().isOnline;
    final theme = Theme.of(context);

    // Dummy data for visual presentation
    final List<Map<String, String>> dummyJobs = [
      {'title': 'Toyota Corolla 2021', 'bankName': 'ASKARI', 'jobId': 'AS-9921'},
      {'title': 'Honda Civic 2022', 'bankName': 'MCB', 'jobId': 'MC-4412'},
      {'title': 'Suzuki Swift 2023', 'bankName': 'ALFALAH', 'jobId': 'BA-7739'},
      {'title': 'Kia Sportage 2022', 'bankName': 'FSBL', 'jobId': 'FS-1021'},
      {'title': 'Hyundai Tucson 2021', 'bankName': 'MBL', 'jobId': 'MB-8822'},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Light modern background
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180.0,
            floating: false,
            pinned: true,
            backgroundColor: theme.colorScheme.primary,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Text(
                'Valuation Pro',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [theme.colorScheme.primary, const Color(0xFF003885)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  Positioned(
                    right: -50,
                    top: -50,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    top: MediaQuery.of(context).padding.top + 20,
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 20,
                          backgroundImage: NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuDPVIz0FjJ_t7LDOPKjXRLxXZ7moCFQmxpDlvNNVK9XnGoQ5TavAw5nML5ziTiF-l_WveV1AkMaR4QoOrNTQRmoKKfIraxGdO0KKJTVA2rEedQnRvXuvIERVaegRyPeCJk07JvayO6jcFds4BNiWQVk7hW7foWacOo9FtTh0xT33Iu2_XdIWVmuHoTqnePLjznHuwOnLMtL3CMpBAhLM9pgt_UXPT29IqseduyWeVF4SfDeq3q5XtuRtu6nkFxlFOM4CAcrmCUDdE4'),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Good Morning,', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            Text('Sarah', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(
                          color: isOnline ? const Color(0xFF4ADE80) : Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isOnline ? 'Online' : 'Offline',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Assigned Jobs',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF191B23),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          transitionDuration: const Duration(milliseconds: 500),
                          pageBuilder: (context, animation, secondaryAnimation) => const AllSurveysScreen(),
                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                            var begin = const Offset(1.0, 0.0);
                            var end = Offset.zero;
                            var curve = Curves.easeOutCubic;
                            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                            return SlideTransition(position: animation.drive(tween), child: child);
                          },
                        ),
                      );
                    },
                    child: const Text('View All'),
                  )
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final job = dummyJobs[index];
                  return PremiumJobCard(
                    title: job['title']!,
                    bankName: job['bankName']!,
                    jobId: job['jobId']!,
                    animationDelay: index * 0.1,
                    onTap: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          transitionDuration: const Duration(milliseconds: 500),
                          pageBuilder: (context, animation, secondaryAnimation) => DynamicFormScreen(
                            jobId: job['jobId']!,
                            bankName: job['bankName']!,
                          ),
                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                            var begin = const Offset(1.0, 0.0);
                            var end = Offset.zero;
                            var curve = Curves.easeOutCubic;
                            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                            return SlideTransition(position: animation.drive(tween), child: child);
                          },
                        ),
                      );
                    },
                  );
                },
                childCount: dummyJobs.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)), // Bottom padding
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.read<SyncService>().syncPendingSurveys();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Syncing pending surveys...')),
          );
        },
        icon: const Icon(Icons.sync_rounded),
        label: const Text('Sync Now', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
