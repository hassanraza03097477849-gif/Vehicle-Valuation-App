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
  String _selectedBankFilter = 'All';
  List<String> _bankFilters = ['All'];
  List<Map<String, String>> filteredJobs = [];

  @override
  void initState() {
    super.initState();
    filteredJobs = widget.jobs;
    _bankFilters = ['All', ...widget.jobs.map((j) => j['bankName'] ?? '').where((b) => b.isNotEmpty).toSet().toList()];
    _searchController.addListener(_filterJobs);
  }

  void _filterJobs() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredJobs = widget.jobs.where((job) {
        final matchesSearch = (job['title'] ?? '').toLowerCase().contains(query) ||
                              (job['bankName'] ?? '').toLowerCase().contains(query) ||
                              (job['jobId'] ?? '').toLowerCase().contains(query);
        final matchesBank = _selectedBankFilter == 'All' || job['bankName'] == _selectedBankFilter;
        return matchesSearch && matchesBank;
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
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search jobs...',
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w500),
                        prefixIcon: Icon(Icons.search_rounded, color: Colors.blue.shade700),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 48,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _bankFilters.length,
                    itemBuilder: (context, index) {
                      final filter = _bankFilters[index];
                      final isSelected = filter == _selectedBankFilter;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutCubic,
                          child: FilterChip(
                            label: Text(
                              filter,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black87,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (bool selected) {
                              setState(() {
                                _selectedBankFilter = filter;
                                _filterJobs();
                              });
                            },
                            backgroundColor: Colors.white,
                            selectedColor: Colors.blue.shade700,
                            checkmarkColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isSelected ? Colors.transparent : Colors.grey.shade300,
                              ),
                            ),
                            elevation: isSelected ? 4 : 0,
                            pressElevation: 0,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
              ],
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
