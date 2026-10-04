import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/client_provider.dart';
import '../models/client_model.dart';
import '../models/fitness_models.dart';
import '../services/database_service.dart';
import 'add_schedule_screen.dart';
import 'month_calendar_view_screen.dart';
import 'group_detail_screen.dart';

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

  void _showAddClientDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final ageCtrl = TextEditingController(text: '25');
    final weightCtrl = TextEditingController(text: '70');
    final heightCtrl = TextEditingController(text: '175');
    final photoPathCtrl = TextEditingController();

    String expLevel = 'Beginner';
    String lifestyle = 'Sedentary';
    int availableDays = 5;
    int sessionsPerDay = 1;
    String goal = 'Lose Weight';

    bool isSavingClient = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          // Dynamic calculated preview BMI
          double calcWeight = double.tryParse(weightCtrl.text) ?? 70.0;
          double calcHeight = double.tryParse(heightCtrl.text) ?? 175.0;
          double heightMeters = calcHeight / 100.0;
          double previewBmi = heightMeters > 0
              ? calcWeight / (heightMeters * heightMeters)
              : 0.0;

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 20,
              left: 16,
              right: 16,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Register New Personal Client',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: ageCtrl,
                          style: const TextStyle(color: Colors.white),
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Age',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: weightCtrl,
                          style: const TextStyle(color: Colors.white),
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setModalState(() {}),
                          decoration: const InputDecoration(
                            labelText: 'Weight (kg)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: heightCtrl,
                          style: const TextStyle(color: Colors.white),
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setModalState(() {}),
                          decoration: const InputDecoration(
                            labelText: 'Height (cm)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Calculated BMI: ${previewBmi.toStringAsFixed(1)}',
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: photoPathCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Local Image File Path (Optional)',
                      hintText: '/storage/emulated/0/...',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(
                        Icons.camera_alt,
                        color: Colors.blueAccent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: goal,
                    dropdownColor: const Color(0xFF1E293B),
                    decoration: const InputDecoration(
                      labelText: 'Fitness Goal',
                      border: OutlineInputBorder(),
                    ),
                    items: ['Lose Weight', 'Gain Weight', 'Maintain Weight']
                        .map(
                          (g) => DropdownMenuItem(
                            value: g,
                            child: Text(
                              g,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setModalState(() => goal = v!),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: availableDays,
                          dropdownColor: const Color(0xFF1E293B),
                          decoration: const InputDecoration(
                            labelText: 'Days Available/Wk',
                            border: OutlineInputBorder(),
                          ),
                          items: List.generate(7, (i) => i + 1)
                              .map(
                                (d) => DropdownMenuItem(
                                  value: d,
                                  child: Text(
                                    '$d Days',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setModalState(() => availableDays = v!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: sessionsPerDay,
                          dropdownColor: const Color(0xFF1E293B),
                          decoration: const InputDecoration(
                            labelText: 'Sessions/Day',
                            border: OutlineInputBorder(),
                          ),
                          items: [1, 2, 3]
                              .map(
                                (s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(
                                    '$s Time(s)',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setModalState(() => sessionsPerDay = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: expLevel,
                    dropdownColor: const Color(0xFF1E293B),
                    decoration: const InputDecoration(
                      labelText: 'Experience Level',
                      border: OutlineInputBorder(),
                    ),
                    items: ['Beginner', 'Intermediate', 'Advanced']
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(
                              e,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setModalState(() => expLevel = v!),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: lifestyle,
                    dropdownColor: const Color(0xFF1E293B),
                    decoration: const InputDecoration(
                      labelText: 'Lifestyle Type',
                      border: OutlineInputBorder(),
                    ),
                    items: ['Sedentary', 'Active']
                        .map(
                          (l) => DropdownMenuItem(
                            value: l,
                            child: Text(
                              l,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setModalState(() => lifestyle = v!),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                      ),
                      onPressed: isSavingClient
                          ? null
                          : () async {
                              if (nameCtrl.text.trim().isEmpty) return;
                              setModalState(() => isSavingClient = true);

                              final client = ClientModel(
                                id: 'client_${DateTime.now().millisecondsSinceEpoch}',
                                name: nameCtrl.text.trim(),
                                phoneNumber: phoneCtrl.text.trim(),
                                age: int.tryParse(ageCtrl.text) ?? 25,
                                gender: 'Male',
                                startingWeight: calcWeight,
                                height: calcHeight,
                                localProfileImagePath:
                                    photoPathCtrl.text.trim().isNotEmpty
                                    ? photoPathCtrl.text.trim()
                                    : null,
                                injuries: 'None',
                                medicalConditions: 'None',
                                experienceLevel: expLevel,
                                lifestyleType: lifestyle,
                                joinedDate: DateTime.now(),
                                availableDaysPerWeek: availableDays,
                                workoutSessionsPerDay: sessionsPerDay,
                                fitnessGoal: goal,
                              );

                              await Provider.of<ClientProvider>(
                                context,
                                listen: false,
                              ).addClient(client);

                              if (context.mounted) {
                                Navigator.pop(context);
                              }
                            },
                      child: isSavingClient
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Save Client Profile',
                              style: TextStyle(color: Colors.white),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Requirement 4: Modal to view & add Progress Entry logs for Personal Client
  void _showClientProgressDialog(ClientModel client) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => FutureBuilder<List<ClientProgressModel>>(
          future: DatabaseService.instance.fetchProgressForClient(client.id),
          builder: (context, snapshot) {
            final progressList = snapshot.data ?? [];

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 20,
                left: 16,
                right: 16,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${client.name}\'s Progress Tracker',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.add_a_photo,
                            color: Colors.blueAccent,
                          ),
                          onPressed: () => _showAddProgressLogDialog(
                            client,
                            onAdded: () => setModalState(() {}),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: progressList.isEmpty
                          ? const Center(
                              child: Text(
                                'No progress logs recorded yet.',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              itemCount: progressList.length,
                              itemBuilder: (context, idx) {
                                final p = progressList[idx];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F172A),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      p.imagePath != null &&
                                              p.imagePath!.isNotEmpty &&
                                              File(p.imagePath!).existsSync()
                                          ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Image.file(
                                                File(p.imagePath!),
                                                width: 50,
                                                height: 50,
                                                fit: BoxFit.cover,
                                              ),
                                            )
                                          : Container(
                                              width: 50,
                                              height: 50,
                                              decoration: BoxDecoration(
                                                color: Colors.grey[800],
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: const Icon(
                                                Icons.show_chart,
                                                color: Colors.greenAccent,
                                              ),
                                            ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              DateFormat(
                                                'MMM dd, yyyy',
                                              ).format(p.date),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Weight: ${p.weight}kg • Height: ${p.height}cm',
                                              style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 12,
                                              ),
                                            ),
                                            Text(
                                              'BMI: ${p.bmi.toStringAsFixed(1)}',
                                              style: const TextStyle(
                                                color: Colors.greenAccent,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showAddProgressLogDialog(
    ClientModel client, {
    required VoidCallback onAdded,
  }) {
    final weightCtrl = TextEditingController(
      text: client.startingWeight.toString(),
    );
    final heightCtrl = TextEditingController(text: client.height.toString());
    final photoCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          'Add Progress Entry',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: weightCtrl,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Current Weight (kg)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: heightCtrl,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Current Height (cm)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: photoCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Progress Photo File Path',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              double w =
                  double.tryParse(weightCtrl.text) ?? client.startingWeight;
              double h = double.tryParse(heightCtrl.text) ?? client.height;
              double hM = h / 100.0;
              double bmi = hM > 0 ? w / (hM * hM) : 0.0;

              final entry = ClientProgressModel(
                id: 'progress_${DateTime.now().millisecondsSinceEpoch}',
                clientId: client.id,
                weight: w,
                height: h,
                bmi: bmi,
                imagePath: photoCtrl.text.trim().isNotEmpty
                    ? photoCtrl.text.trim()
                    : null,
                date: DateTime.now(),
                notes: notesCtrl.text.trim(),
              );

              await Provider.of<ClientProvider>(
                context,
                listen: false,
              ).addClientProgress(entry);

              if (mounted) {
                Navigator.pop(context);
                onAdded();
              }
            },
            child: const Text('Save Entry'),
          ),
        ],
      ),
    );
  }

  void _showAddGroupDialog() {
    final groupNameCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 20,
          left: 16,
          right: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Form Training Group',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: groupNameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Group Workspace Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () async {
                  if (groupNameCtrl.text.trim().isEmpty) return;
                  final group = GroupModel(
                    id: 'group_${DateTime.now().millisecondsSinceEpoch}',
                    groupName: groupNameCtrl.text.trim(),
                    createdDate: DateTime.now(),
                  );
                  await Provider.of<ClientProvider>(
                    context,
                    listen: false,
                  ).addGroup(group);
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text(
                  'Initialize Cluster Group',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final String formattedDate = DateFormat('EEEE, MMMM d').format(now);
    final clientProvider = Provider.of<ClientProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
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
                    onTap: () => clientProvider.backupData(),
                    child: const CircleAvatar(
                      backgroundColor: Color(0xFF1E293B),
                      child: Icon(Icons.shield, color: Colors.blueAccent),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Active Clients',
                      value: '${clientProvider.totalActiveClients}',
                      icon: Icons.person,
                      color: const Color(0xFF3B82F6),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Active Groups',
                      value: '${clientProvider.totalActiveGroups}',
                      icon: Icons.hub,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xFF3B82F6),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey[400],
                  tabs: const [
                    Tab(text: 'Personal Clients'),
                    Tab(text: 'Training Groups'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    clientProvider.clients.isEmpty
                        ? _buildEmptyState('No personal clients assigned.')
                        : ListView.builder(
                            itemCount: clientProvider.clients.length,
                            itemBuilder: (context, idx) => _buildWideItemCard(
                              context,
                              clientProvider.clients[idx],
                            ),
                          ),
                    clientProvider.groups.isEmpty
                        ? _buildEmptyState(
                            'No active training groups configured.',
                          )
                        : ListView.builder(
                            itemCount: clientProvider.groups.length,
                            itemBuilder: (context, idx) => _buildWideGroupCard(
                              context,
                              clientProvider.groups[idx],
                            ),
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
          if (_tabController.index == 0) {
            _showAddClientDialog();
          } else {
            _showAddGroupDialog();
          }
        },
        backgroundColor: const Color(0xFF3B82F6),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildMetricCard({
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
          client.localProfileImagePath != null &&
                  client.localProfileImagePath!.isNotEmpty &&
                  File(client.localProfileImagePath!).existsSync()
              ? CircleAvatar(
                  radius: 26,
                  backgroundImage: FileImage(
                    File(client.localProfileImagePath!),
                  ),
                )
              : CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.grey[800],
                  child: const Icon(Icons.person, color: Colors.white70),
                ),
          const SizedBox(width: 14),
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MonthCalendarViewScreen(
                    clientId: client.id,
                    entityName: client.name,
                  ),
                ),
              ),
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
                    'Goal: ${client.fitnessGoal} • ${client.availableDaysPerWeek} days/wk',
                    style: TextStyle(
                      color: Colors.blueAccent[100],
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'BMI: ${client.bmi.toStringAsFixed(1)} • ${client.startingWeight}kg',
                    style: TextStyle(color: Colors.grey[400], fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.show_chart, color: Colors.greenAccent),
            tooltip: 'View Progress',
            onPressed: () => _showClientProgressDialog(client),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month, color: Colors.blueAccent),
            tooltip: 'Calendar Schedule',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddScheduleScreen(
                  clientId: client.id,
                  entityName: client.name,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWideGroupCard(BuildContext context, GroupModel group) {
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
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GroupDetailScreen(group: group),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.groupName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage Members, Schedule & Attendance',
                    style: TextStyle(
                      color: Colors.indigoAccent[100],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.arrow_forward_ios,
              size: 18,
              color: Colors.indigoAccent,
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GroupDetailScreen(group: group),
              ),
            ),
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
