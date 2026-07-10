import 'package:flutter/material.dart';
import '../widgets/premium_job_card.dart';
import '../widgets/animated_corporate_background.dart';
import 'forms/dynamic_form_screen.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';

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
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        surfaceTintColor: theme.colorScheme.surface,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
        title: Text(
          'All Surveys',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
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
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(color: theme.colorScheme.outline.withOpacity(0.2), height: 2),
        ),
      ),
      body: AnimatedCorporateBackground(
        child: Column(
          children: [
            Container(
              color: theme.colorScheme.surface,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: 'Search jobs, banks, or IDs...',
                      hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                      prefixIcon: Icon(Icons.search_rounded, color: theme.colorScheme.onSurface.withOpacity(0.6), size: 20),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 36,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _bankFilters.length,
                      itemBuilder: (context, index) {
                        final filter = _bankFilters[index];
                        final isSelected = filter == _selectedBankFilter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(filter),
                            selected: isSelected,
                            onSelected: (bool selected) {
                              setState(() {
                                _selectedBankFilter = filter;
                                _filterJobs();
                              });
                            },
                            backgroundColor: theme.colorScheme.surface,
                            selectedColor: theme.colorScheme.primary.withOpacity(0.2),
                            labelStyle: TextStyle(
                              color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              fontSize: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline,
                                width: isSelected ? 2.0 : 1.0,
                              ),
                            ),
                            showCheckmark: false,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Container(height: 2, color: theme.colorScheme.outline.withOpacity(0.2)),
            Expanded(
              child: filteredJobs.isEmpty
                  ? Center(
                      child: Text(
                        'No jobs match your search.',
                        style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    )
                : ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: filteredJobs.length,
                    itemBuilder: (context, index) {
                      final job = filteredJobs[index];
                      return PremiumJobCard(
                        title: job['title']!,
                        bankName: job['bankName']!,
                        jobId: job['jobId']!,
                        animationDelay: 0.0,
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
                  ),
          ),
        ],
      ),
      ),
    );
  }
}
