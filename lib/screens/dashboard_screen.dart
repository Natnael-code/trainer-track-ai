import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/client_provider.dart';
import '../models/client_model.dart';
import 'add_schedule_screen.dart'; // Import the schedule builder screen

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final String formattedDate = DateFormat('EEEE, MMMM d').format(now);

    return Scaffold(
      backgroundColor: const Color(
        0xFF0F172A,
      ), // Deep futuristic slate background
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
                      await Provider.of<ClientProvider>(
                        context,
                        listen: false,
                      ).backupData();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Exporting Database Security Snapshot...',
                            ),
                          ),
                        );
                      }
                    },
                    child: const CircleAvatar(
                      backgroundColor: Color(0xFF1E293B),
                      child: Icon(Icons.shield, color: Colors.blueAccent),
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
                          title: 'Active Clients',
                          value: '${clientProvider.totalActiveClients}',
                          icon: Icons.person,
                          color: const Color(0xFF3B82F6),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          context: context,
                          title: 'Active Groups',
                          value:
                              '3', // Dynamic or placeholder value depending on group tracking
                          icon: Icons.hub,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // 3. Futuristic Neon Segmented Tab Bar Selector
              Container(
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xFF3B82F6),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey[400],
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  tabs: const [
                    Tab(text: 'Personal Clients'),
                    Tab(text: 'Training Groups'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 4. Dual-Tab Content Windows
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // --- TAB 1: INDIVIDUAL CLIENTS LIST ---
                    Consumer<ClientProvider>(
                      builder: (context, clientProvider, child) {
                        final clientList = clientProvider.clients;
                        if (clientList.isEmpty) {
                          return _buildEmptyState(
                            'No personal clients assigned.',
                          );
                        }
                        return ListView.builder(
                          itemCount: clientList.length,
                          itemBuilder: (context, index) {
                            return _buildWideItemCard(
                              context,
                              clientList[index],
                            );
                          },
                        );
                      },
                    ),

                    // --- TAB 2: TRAINING GROUPS LIST ---
                    ListView(
                      children: [
                        _buildWideGroupCard(
                          context,
                          'Morning Elite Shred',
                          '8 Members',
                          'July 2026 Assigned',
                        ),
                        _buildWideGroupCard(
                          context,
                          'Calisthenics Advanced',
                          '5 Members',
                          'No Plan Configured',
                        ),
                        _buildWideGroupCard(
                          context,
                          'Hypertrophy Pool B',
                          '12 Members',
                          'July 2026 Assigned',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
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
        color: const Color(0xFF1E293B),
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

  // Horizontally wide, medium-height card for personal clients
  Widget _buildWideItemCard(BuildContext context, ClientModel client) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: Colors.grey[800],
            child: const Icon(Icons.person, color: Colors.white70),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  client.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'BMI: ${client.bmi.toStringAsFixed(1)} • ${client.experienceLevel}',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
          ),
          // Interactive Shortcut Calendar Engine Hook Button
          IconButton(
            icon: const Icon(Icons.calendar_month, color: Colors.blueAccent),
            tooltip: 'Setup Monthly Schedule',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddScheduleScreen(
                    clientId: client.id,
                    entityName: client.name,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Horizontally wide, medium-height card for tracking training groups
  Widget _buildWideGroupCard(
    BuildContext context,
    String groupName,
    String sizeText,
    String statusMessage,
  ) {
    bool isAssigned = statusMessage.contains('Assigned');
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 26,
            backgroundColor: Color(0xFF312E81),
            child: Icon(Icons.hub, color: Colors.indigoAccent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  groupName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$sizeText • $statusMessage',
                  style: TextStyle(
                    color: isAssigned ? const Color(0xFF10B981) : Colors.amber,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month, color: Colors.indigoAccent),
            tooltip: 'Setup Group Schedule',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddScheduleScreen(
                    groupId: groupName.toLowerCase().replaceAll(' ', '_'),
                    entityName: groupName,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String sub) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.fitness_center, size: 48, color: Colors.grey[700]),
          const SizedBox(height: 12),
          Text(
            sub,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
        ],
      ),
    );
  }

  String _getGreetingText(int hour) {
    if (hour < 12) return 'Good Morning, Coach';
    if (hour < 17) return 'Good Afternoon, Coach';
    return 'Good Evening, Coach';
  }
}
