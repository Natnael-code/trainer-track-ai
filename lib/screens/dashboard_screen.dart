import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/client_provider.dart';
import '../models/client_model.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final String formattedDate = DateFormat('EEEE, MMMM d').format(now);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // 1. Custom Header Layout
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getGreetingText(now.hour),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        formattedDate,
                        style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () async {
                      // Fire off the backup sharing engine protocol sequence safely
                      await Provider.of<ClientProvider>(
                        context,
                        listen: false,
                      ).backupData();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Exporting Database Security Snapshot...',
                          ),
                        ),
                      );
                    },
                    child: CircleAvatar(
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                      child: const Icon(
                        Icons.shield,
                        color: Colors.white,
                      ), // Changed icon to shield for clarity
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 2. Business Analytics Layer (KPI Cards)
              Consumer<ClientProvider>(
                builder: (context, clientProvider, child) {
                  return Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          context: context,
                          title: 'Active Roster',
                          value: '${clientProvider.totalActiveClients}',
                          icon: Icons.group,
                          color: const Color(0xFF3B82F6), // Vibrant blue
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          context: context,
                          title: 'Compliance',
                          value: '100%', // hardcoded dummy metric for phase 1
                          icon: Icons.assignment_turned_in,
                          color: const Color(0xFF10B981), // Emerald green
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 28),

              // 3. Client Section Label
              const Text(
                'Active Clients',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 12),

              // 4. Dynamic Client Index List
              Expanded(
                child: Consumer<ClientProvider>(
                  builder: (context, clientProvider, child) {
                    final clientList = clientProvider.clients;

                    if (clientList.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.fitness_center,
                              size: 48,
                              color: Colors.grey[700],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No clients registered yet.\nTap the button below to add your first client!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: clientList.length,
                      itemBuilder: (context, index) {
                        final client = clientList[index];
                        return _buildClientListItem(context, client);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),

      // 5. Action Floating Action Button
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigational hook for registration screen layout to be wired in next step
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Navigation link to registration form'),
            ),
          );
        },
        backgroundColor: const Color(0xFF3B82F6),
        child: const Icon(Icons.person_add_alt_1, color: Colors.white),
      ),
    );
  }

  // Helper Widget for Metric Cards
  Widget _buildMetricCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), // Matches our deep slate background
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[400])),
        ],
      ),
    );
  }

  // Helper Widget for individual Client List Tiles
  Widget _buildClientListItem(BuildContext context, ClientModel client) {
    return Card(
      color: const Color(0xFF1E293B),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.white10),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.grey[800],
          backgroundImage: client.localProfileImagePath != null
              ? Uri.parse(client.localProfileImagePath!).isAbsolute
                    ? NetworkImage(client.localProfileImagePath!)
                    : const AssetImage('assets/images/placeholder.png')
                          as ImageProvider
              : null,
          child: client.localProfileImagePath == null
              ? const Icon(Icons.person, color: Colors.white70)
              : null,
        ),
        title: Text(
          client.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        subtitle: Text(
          'BMI: ${client.bmi.toStringAsFixed(1)} | ${client.experienceLevel}',
          style: TextStyle(color: Colors.grey[400]),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.white30),
        onTap: () {
          // Open Detailed progression profile
        },
      ),
    );
  }

  // Dynamic greeting generator script
  String _getGreetingText(int hour) {
    if (hour < 12) return 'Good Morning, Coach';
    if (hour < 17) return 'Good Afternoon, Coach';
    return 'Good Evening, Coach';
  }
}
