import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/connectivity_service.dart';
import '../services/sync_service.dart';
import '../widgets/premium_job_card.dart';
import 'forms/dynamic_form_screen.dart';
import 'all_surveys_screen.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, String>> _jobs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchJobs();
  }

  Future<void> _fetchJobs() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.token == null) return;

    try {
      final response = await http.get(
        Uri.parse('${authService.baseUrl}/getJobs'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${authService.token}',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _jobs = data.map((job) => {
            'title': '${job['make'] ?? ''} ${job['model'] ?? ''} ${job['reg_no'] ?? ''}'.trim().isNotEmpty 
                ? '${job['make'] ?? ''} ${job['model'] ?? ''} ${job['reg_no'] ?? ''}' 
                : 'Vehicle Valuation',
            'bankName': job['bank_name']?.toString() ?? 'OTHERS',
            'jobId': job['job_id']?.toString() ?? '',
            'dbId': job['valuation_id']?.toString() ?? '',
          }).toList();
          
          // Let's ensure the bankName matches one of our 8 supported
          for (var j in _jobs) {
            String b = j['bankName']!.toUpperCase();
            if (b.contains('ASKARI') || b == 'ASKBL') j['bankName'] = 'ASKBL';
            else if (b.contains('MCB')) j['bankName'] = 'MCB';
            else if (b.contains('BANK AL FALAH') || b.contains('BAF')) j['bankName'] = 'BAF';
            else if (b.contains('FAYSAL') || b.contains('FSBL')) j['bankName'] = 'FSBL';
            else if (b.contains('MEEZAN') || b.contains('MBL')) j['bankName'] = 'MBL';
            else if (b.contains('MOBILINK') || b.contains('MMB')) j['bankName'] = 'MMB';
            else if (b.contains('SUMMIT') || b.contains('SMBL')) j['bankName'] = 'SMBL';
            else j['bankName'] = 'OTHERS';
          }
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Failed to fetch jobs: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = context.watch<ConnectivityService>().isOnline;
    final theme = Theme.of(context);
    final authService = context.watch<AuthService>();
    final userName = authService.user?['name'] ?? 'User';

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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Good Morning,', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            Text(userName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_jobs.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Text('No assigned jobs found.', style: theme.textTheme.titleMedium),
              ),
            )
          else
            SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final job = _jobs[index];
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
                            dbId: job['dbId']!,
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
                childCount: _jobs.length > 5 ? 5 : _jobs.length,
              ),
            ),
          ),
          if (_jobs.length > 5)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: TextButton.icon(
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
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: Text('View all ${_jobs.length} jobs', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
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
