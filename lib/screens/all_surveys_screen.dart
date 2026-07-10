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
    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF101828)),
        title: const Text(
          'All Surveys',
          style: TextStyle(
            color: Color(0xFF101828),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFEAECF0), height: 1),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF101828)),
                  decoration: InputDecoration(
                    hintText: 'Search jobs, banks, or IDs...',
                    hintStyle: const TextStyle(color: Color(0xFF98A2B3)),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF667085), size: 20),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF1570EF), width: 2),
                    ),
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
                          backgroundColor: Colors.white,
                          selectedColor: const Color(0xFFEFF8FF),
                          labelStyle: TextStyle(
                            color: isSelected ? const Color(0xFF175CD3) : const Color(0xFF344054),
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            fontSize: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: isSelected ? const Color(0xFFB2DDFF) : const Color(0xFFD0D5DD),
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
          Container(height: 1, color: const Color(0xFFEAECF0)),
          Expanded(
            child: filteredJobs.isEmpty
                ? const Center(
                    child: Text(
                      'No jobs match your search.',
                      style: TextStyle(color: Color(0xFF475467), fontSize: 16),
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
    );
  }
}
