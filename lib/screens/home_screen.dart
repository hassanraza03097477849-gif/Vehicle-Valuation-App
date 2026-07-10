import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/connectivity_service.dart';
import '../services/sync_service.dart';
import '../widgets/premium_job_card.dart';
import '../widgets/animated_corporate_background.dart';
import 'forms/dynamic_form_screen.dart';

import 'all_surveys_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import '../services/theme_service.dart';

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

  Future<void> _logout() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/login'); // Assuming login is pushed manually or using auth state
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = context.watch<ConnectivityService>().isOnline;
    final authService = context.watch<AuthService>();
    final userName = authService.user?['name'] ?? 'User';
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        surfaceTintColor: theme.colorScheme.surface,
        title: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.colorScheme.outline),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/images/logo.jpg',
                  width: 36,
                  height: 36,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                'Valuation Pro',
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              context.watch<ThemeService>().isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: theme.colorScheme.onSurface,
            ),
            onPressed: () {
              context.read<ThemeService>().toggleTheme();
            },
          ),
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isOnline 
                    ? Colors.green.withOpacity(0.1) 
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isOnline ? Colors.green : Colors.red,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 6, height: 6,
                    decoration: BoxDecoration(
                      color: isOnline ? Colors.green : Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isOnline ? 'Online' : 'Offline',
                    style: TextStyle(
                      color: isOnline ? Colors.green : Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: theme.colorScheme.onSurface),
            onPressed: () {
              setState(() => _isLoading = true);
              _fetchJobs();
            },
            tooltip: 'Refresh Surveys',
          ),
          IconButton(
            icon: Icon(Icons.logout_rounded, color: theme.colorScheme.onSurface),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(color: theme.colorScheme.outline.withOpacity(0.2), height: 2),
        ),
      ),
      body: AnimatedCorporateBackground(
        child: CustomScrollView(
          slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dashboard',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Welcome back, $userName. Here is your overview.',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Jobs',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              transitionDuration: const Duration(milliseconds: 300),
                              pageBuilder: (context, animation, secondaryAnimation) => AllSurveysScreen(jobs: _jobs),
                              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                return FadeTransition(opacity: animation, child: child);
                              },
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.primary,
                          textStyle: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        child: const Text('View all'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
             SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: theme.colorScheme.primary)),
            )
          else if (_jobs.isEmpty)
             SliverFillRemaining(
              child: Center(
                child: Text(
                  'No assigned jobs found.',
                  style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final job = _jobs[index];
                    return PremiumJobCard(
                      title: job['title']!,
                      bankName: job['bankName']!,
                      jobId: job['jobId']!,
                      animationDelay: index * 0.1, // Staggered animation
                      onTap: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            transitionDuration: const Duration(milliseconds: 300),
                            pageBuilder: (context, animation, secondaryAnimation) => DynamicFormScreen(
                              jobId: job['jobId']!,
                              bankName: job['bankName']!,
                              dbId: job['dbId']!,
                            ),
                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                              return FadeTransition(opacity: animation, child: child);
                            },
                          ),
                        );
                      },
                    );
                  },
                  childCount: _jobs.length > 5 ? 5 : _jobs.length, // Only show top 5 on dashboard
                ),
              ),
            ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
        ],
      ),
      ),
    );
  }
}
