import 'package:flutter/material.dart';
import '../widgets/premium_job_card.dart';
import 'forms/dynamic_form_screen.dart';

class AllSurveysScreen extends StatefulWidget {
  final List<Map<String, String>> jobs;

  const AllSurveysScreen({super.key, required this.jobs});

  @override
  State<AllSurveysScreen> createState() => _AllSurveysScreenState();
}

class _AllSurveysScreenState extends State<AllSurveysScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, String>> filteredJobs = [];

  @override
  void initState() {
    super.initState();
    filteredJobs = widget.jobs;
    _searchController.addListener(_filterJobs);
  }

  void _filterJobs() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredJobs = widget.jobs.where((job) {
        return (job['title'] ?? '').toLowerCase().contains(query) ||
               (job['bankName'] ?? '').toLowerCase().contains(query) ||
               (job['jobId'] ?? '').toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 140.0,
            floating: true,
            pinned: true,
            backgroundColor: theme.colorScheme.primary,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 48, bottom: 16),
              title: Text(
                'All Surveys',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [theme.colorScheme.primary, const Color(0xFF003885)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                  ]
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by make, model, bank, or ID...',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w500),
                    prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade400),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final job = filteredJobs[index];
                  return PremiumJobCard(
                    title: job['title']!,
                    bankName: job['bankName']!,
                    jobId: job['jobId']!,
                    animationDelay: (index % 10) * 0.05,
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
                childCount: filteredJobs.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}
