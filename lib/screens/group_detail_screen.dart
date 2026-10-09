import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
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

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  Future<void> _loadData() async {
    setState(() => _isLoadingMembers = true);
    final members = await DatabaseService.instance.fetchClientsForGroup(
      widget.group.id,
    );
    final schedule = await DatabaseService.instance.fetchScheduleForEntity(
      groupId: widget.group.id,
    );

    int defaultDayNum = 1;
    final DateTime now = DateTime.now();

    for (var day in schedule) {
      if (_isSameDay(day.absoluteDate, now)) {
        defaultDayNum = day.dayNumber;
        break;
      }
    }

    if (mounted) {
      setState(() {
        _groupMembers = members;
        _groupSchedule = schedule;
        _selectedDayNumber = defaultDayNum;
        _isLoadingMembers = false;
      });
      _loadAttendanceForSelectedDay();
    }
  }

  Future<void> _loadAttendanceForSelectedDay() async {
    if (_groupSchedule.isEmpty) return;

    final dayNode = _groupSchedule.firstWhere(
      (d) => d.dayNumber == _selectedDayNumber,
      orElse: () => _groupSchedule.first,
    );

    final existingAttendance = await DatabaseService.instance
        .fetchAttendanceForDay(widget.group.id, dayNode.id);

    if (mounted) {
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
            _attendanceMap[member.id] = dayNode.isWorkDay
                ? 'Present'
                : 'Absent';
          }
        }
      });
    }
  }

  void _showAddNewGroupMemberDialog(bool isDark) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final weightCtrl = TextEditingController();

    final bgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: bgColor,
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
              Text(
                'Add Member to Group',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                style: TextStyle(color: textColor),
                decoration: const InputDecoration(
                  labelText: 'Member Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                style: TextStyle(color: textColor),
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: weightCtrl,
                style: TextStyle(color: textColor),
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
                    backgroundColor: const Color(0xFF2563EB),
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
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
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
          backgroundColor: Color(0xFF10B981),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final clientProvider = Provider.of<ClientProvider>(context);
    final isDark = clientProvider.isDarkMode;

    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          widget.group.groupName,
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: bgColor,
        iconTheme: IconThemeData(color: textColor),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF3B82F6),
          labelColor: const Color(0xFF3B82F6),
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
          _buildMembersTab(isDark),
          _buildScheduleTab(isDark),
          _buildAttendanceTab(isDark),
        ],
      ),
    );
  }

  Widget _buildMembersTab(bool isDark) {
    final clientProvider = Provider.of<ClientProvider>(context);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Group Members (${_groupMembers.length})',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                ),
                icon: const Icon(
                  Icons.person_add,
                  size: 16,
                  color: Colors.white,
                ),
                label: const Text(
                  'Add Member',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () => _showAddNewGroupMemberDialog(isDark),
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
                          color: cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? Colors.white10
                                : const Color(0xFFE2E8F0),
                          ),
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
                                    style: TextStyle(
                                      color: textColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Phone: ${member.phoneNumber} • Weight: ${member.startingWeight}kg',
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
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

  Widget _buildScheduleTab(bool isDark) {
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.calendar_month, size: 64, color: Color(0xFF3B82F6)),
          const SizedBox(height: 16),
          Text(
            'Group Monthly Schedule Grid',
            style: TextStyle(
              color: textColor,
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                ),
                icon: const Icon(Icons.edit, color: Colors.white),
                label: const Text(
                  'Build Schedule',
                  style: TextStyle(color: Colors.white),
                ),
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

  Widget _buildAttendanceTab(bool isDark) {
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

    final DateTime now = DateTime.now();
    final selectedDayNode = _groupSchedule.firstWhere(
      (d) => d.dayNumber == _selectedDayNumber,
      orElse: () => _groupSchedule.first,
    );
    final bool isSelectedToday = _isSameDay(selectedDayNode.absoluteDate, now);

    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    int presentCount = _attendanceMap.values
        .where((v) => v == 'Present')
        .length;
    int absentCount = _attendanceMap.values.where((v) => v == 'Absent').length;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Day:',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                DropdownButton<int>(
                  value: _selectedDayNumber,
                  dropdownColor: cardBg,
                  style: TextStyle(color: textColor),
                  items: _groupSchedule.map((dayNode) {
                    final bool isToday = _isSameDay(dayNode.absoluteDate, now);
                    final String label =
                        'Day ${dayNode.dayNumber} (${DateFormat('MMM d').format(dayNode.absoluteDate)})${isToday ? ' [TODAY]' : ''}';
                    return DropdownMenuItem<int>(
                      value: dayNode.dayNumber,
                      child: Text(
                        label,
                        style: TextStyle(
                          color: isToday ? const Color(0xFF10B981) : textColor,
                          fontWeight: isToday
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
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
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelectedToday
                  ? const Color(0xFF3B82F6).withAlpha(35)
                  : Colors.amber.withAlpha(35),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelectedToday ? const Color(0xFF3B82F6) : Colors.amber,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isSelectedToday ? Icons.today : Icons.history,
                  color: isSelectedToday
                      ? const Color(0xFF3B82F6)
                      : Colors.amber,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isSelectedToday
                            ? 'Today\'s Attendance Session'
                            : 'Saved Attendance Record View',
                        style: TextStyle(
                          color: isSelectedToday
                              ? const Color(0xFF3B82F6)
                              : Colors.amber,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        DateFormat(
                          'EEEE, MMMM d, yyyy',
                        ).format(selectedDayNode.absoluteDate),
                        style: TextStyle(
                          color: textColor.withAlpha(200),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'P: $presentCount | A: $absentCount',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: ListView.builder(
              itemCount: _groupMembers.length,
              itemBuilder: (context, idx) {
                final member = _groupMembers[idx];
                final currentStatus = _attendanceMap[member.id] ?? 'Present';

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member.name,
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            member.phoneNumber,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 11,
                            ),
                          ),
                        ],
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
                backgroundColor: isSelectedToday
                    ? const Color(0xFF2563EB)
                    : Colors.indigoAccent,
              ),
              onPressed: _isSavingAttendance ? null : _saveAttendance,
              child: _isSavingAttendance
                  ? const CircularProgressIndicator(color: Colors.white)
                  : RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        children: isSelectedToday
                            ? const [
                                TextSpan(
                                  text: 'Save Today\'s Attendance',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ]
                            : [
                                const TextSpan(
                                  text: 'Update Saved ',
                                  style: TextStyle(color: Colors.white),
                                ),
                                TextSpan(
                                  text: 'Day $_selectedDayNumber Record',
                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                  ),
                                ),
                              ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
