import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/fitness_models.dart';
import '../models/client_model.dart';
import '../providers/client_provider.dart';
import '../services/database_service.dart';
import 'add_schedule_screen.dart';
import 'month_calendar_view_screen.dart';

class GroupDetailScreen extends StatefulWidget {
  final GroupModel group;

  const GroupDetailScreen({super.key, required this.group});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ClientModel> _groupMembers = [];
  List<ScheduleDayModel> _groupSchedule = [];
  bool _isLoadingMembers = true;

  // Attendance tab states
  int _selectedDayNumber = 1;
  final Map<String, String> _attendanceMap = {};
  bool _isSavingAttendance = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoadingMembers = true);
    final members = await DatabaseService.instance.fetchClientsForGroup(
      widget.group.id,
    );
    final schedule = await DatabaseService.instance.fetchScheduleForEntity(
      groupId: widget.group.id,
    );

    setState(() {
      _groupMembers = members;
      _groupSchedule = schedule;
      _isLoadingMembers = false;
    });

    _loadAttendanceForSelectedDay();
  }

  // Automatic attendance loader: defaults to Present for active work days
  Future<void> _loadAttendanceForSelectedDay() async {
    if (_groupSchedule.isEmpty) return;

    final dayNode = _groupSchedule.firstWhere(
      (d) => d.dayNumber == _selectedDayNumber,
      orElse: () => _groupSchedule.first,
    );

    final existingAttendance = await DatabaseService.instance
        .fetchAttendanceForDay(widget.group.id, dayNode.id);

    setState(() {
      _attendanceMap.clear();
      for (var member in _groupMembers) {
        final found = existingAttendance.firstWhere(
          (a) => a.clientId == member.id,
          orElse: () => GroupAttendanceModel(
            id: '',
            groupId: widget.group.id,
            dayScheduleId: dayNode.id,
            clientId: member.id,
            status: 'Present',
            date: DateTime.now(),
          ),
        );

        if (found.id.isNotEmpty) {
          _attendanceMap[member.id] = found.status;
        } else {
          // Auto default to 'Present' if it's a working day
          _attendanceMap[member.id] = dayNode.isWorkDay ? 'Present' : 'Absent';
        }
      }
    });
  }

  // Requirement 1: Add new member asking ONLY for Name, Phone Number, and Weight
  void _showAddNewGroupMemberDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final weightCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add Member to Group',
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
                  labelText: 'Member Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: weightCtrl,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Weight (kg)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                  ),
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty) return;

                    await Provider.of<ClientProvider>(
                      context,
                      listen: false,
                    ).addGroupMember(
                      name: nameCtrl.text.trim(),
                      phoneNumber: phoneCtrl.text.trim(),
                      weight: double.tryParse(weightCtrl.text) ?? 70.0,
                      groupId: widget.group.id,
                    );

                    if (context.mounted) {
                      Navigator.pop(context);
                      _loadData();
                    }
                  },
                  child: const Text(
                    'Save Group Member',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveAttendance() async {
    if (_groupSchedule.isEmpty) return;
    setState(() => _isSavingAttendance = true);

    final dayNode = _groupSchedule.firstWhere(
      (d) => d.dayNumber == _selectedDayNumber,
      orElse: () => _groupSchedule.first,
    );

    final List<GroupAttendanceModel> records = [];
    _attendanceMap.forEach((clientId, status) {
      records.add(
        GroupAttendanceModel(
          id: '${widget.group.id}_${dayNode.id}_$clientId',
          groupId: widget.group.id,
          dayScheduleId: dayNode.id,
          clientId: clientId,
          status: status,
          date: dayNode.absoluteDate,
        ),
      );
    });

    await DatabaseService.instance.saveGroupAttendance(records);
    setState(() => _isSavingAttendance = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Attendance records saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(
          widget.group.groupName,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0F172A),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.indigoAccent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.group), text: 'Members'),
            Tab(icon: Icon(Icons.calendar_month), text: 'Calendar'),
            Tab(icon: Icon(Icons.fact_check), text: 'Attendance'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMembersTab(),
          _buildScheduleTab(),
          _buildAttendanceTab(),
        ],
      ),
    );
  }

  Widget _buildMembersTab() {
    final clientProvider = Provider.of<ClientProvider>(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Group Members (${_groupMembers.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.person_add, size: 16),
                label: const Text('Add Member'),
                onPressed: _showAddNewGroupMemberDialog,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoadingMembers
                ? const Center(child: CircularProgressIndicator())
                : _groupMembers.isEmpty
                ? const Center(
                    child: Text(
                      'No members assigned to this group yet.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _groupMembers.length,
                    itemBuilder: (context, idx) {
                      final member = _groupMembers[idx];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const CircleAvatar(child: Icon(Icons.person)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    member.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Phone: ${member.phoneNumber} • Weight: ${member.startingWeight}kg',
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.remove_circle_outline,
                                color: Colors.redAccent,
                              ),
                              onPressed: () async {
                                await clientProvider.removeClientFromGroup(
                                  member.id,
                                  widget.group.id,
                                );
                                _loadData();
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.calendar_month,
            size: 64,
            color: Colors.indigoAccent,
          ),
          const SizedBox(height: 16),
          const Text(
            'Group Monthly Schedule Grid',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'View group routine days or build custom splits.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.grid_view),
                label: const Text('View Calendar Ledger'),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MonthCalendarViewScreen(
                      groupId: widget.group.id,
                      entityName: widget.group.groupName,
                    ),
                  ),
                ).then((_) => _loadData()),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                icon: const Icon(Icons.edit),
                label: const Text('Build Schedule'),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddScheduleScreen(
                      groupId: widget.group.id,
                      entityName: widget.group.groupName,
                    ),
                  ),
                ).then((_) => _loadData()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceTab() {
    if (_groupMembers.isEmpty) {
      return const Center(
        child: Text(
          'Please add group members first to track attendance.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    if (_groupSchedule.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'No active group schedule initialized.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddScheduleScreen(
                    groupId: widget.group.id,
                    entityName: widget.group.groupName,
                  ),
                ),
              ).then((_) => _loadData()),
              child: const Text('Initialize Schedule First'),
            ),
          ],
        ),
      );
    }

    int totalDays = _groupSchedule.length;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'Select Day:',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<int>(
                value: _selectedDayNumber,
                dropdownColor: const Color(0xFF1E293B),
                style: const TextStyle(color: Colors.white),
                items: List.generate(totalDays, (i) => i + 1).map((dayNum) {
                  return DropdownMenuItem(
                    value: dayNum,
                    child: Text('Day $dayNum'),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedDayNumber = val);
                    _loadAttendanceForSelectedDay();
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _groupMembers.length,
              itemBuilder: (context, idx) {
                final member = _groupMembers[idx];
                final currentStatus = _attendanceMap[member.id] ?? 'Present';

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        member.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'Present',
                            label: Text('Present'),
                            icon: Icon(Icons.check, size: 14),
                          ),
                          ButtonSegment(
                            value: 'Absent',
                            label: Text('Absent'),
                            icon: Icon(Icons.close, size: 14),
                          ),
                        ],
                        selected: {currentStatus},
                        onSelectionChanged: (newVal) {
                          setState(() {
                            _attendanceMap[member.id] = newVal.first;
                          });
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigoAccent,
              ),
              onPressed: _isSavingAttendance ? null : _saveAttendance,
              child: _isSavingAttendance
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Save Attendance Record',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
