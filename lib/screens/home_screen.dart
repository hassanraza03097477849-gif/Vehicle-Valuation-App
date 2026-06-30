import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/connectivity_service.dart';
import '../services/sync_service.dart';
import '../utils/bank_themes.dart';
import 'forms/dynamic_form_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isOnline = context.watch<ConnectivityService>().isOnline;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Valuation Jobs'),
        actions: [
          Icon(
            isOnline ? Icons.cloud_done : Icons.cloud_off,
            color: isOnline ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Assigned Jobs',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildJobCard(context, 'Toyota Corolla - 2021', 'ASKBL', '1234'),
          _buildJobCard(context, 'Honda Civic - 2018', 'MCB', '1235'),
          _buildJobCard(context, 'Suzuki Cultus - 2019', 'BAF', '1236'),
          _buildJobCard(context, 'Kia Sportage - 2022', 'FSBL', '1237'),
          _buildJobCard(context, 'Hyundai Tucson - 2021', 'MBL', '1238'),
          _buildJobCard(context, 'Toyota Yaris - 2020', 'MMB', '1239'),
          _buildJobCard(context, 'Suzuki Swift - 2023', 'SMBL', '1240'),
          _buildJobCard(context, 'Honda City - 2017', 'OTHERS', '1241'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Manual sync trigger
          context.read<SyncService>().syncPendingSurveys();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Syncing pending surveys...')),
          );
        },
        child: const Icon(Icons.sync),
      ),
    );
  }

  Widget _buildJobCard(
    BuildContext context,
    String title,
    String bankName,
    String jobId,
  ) {
    final theme = BankTheme.getTheme(bankName);
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border(left: BorderSide(color: theme.primaryColor, width: 6)),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: CircleAvatar(
            backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
            child: Icon(Icons.car_rental, color: theme.primaryColor),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.account_balance,
                    size: 14,
                    color: theme.secondaryColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    bankName,
                    style: TextStyle(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text('Job ID: $jobId'),
            ],
          ),
          trailing: Icon(Icons.arrow_forward_ios, color: theme.primaryColor),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    DynamicFormScreen(jobId: jobId, bankName: bankName),
              ),
            );
          },
        ),
      ),
    );
  }
}
