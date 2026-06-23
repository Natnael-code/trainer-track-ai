import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/fitness_models.dart';
import '../services/database_service.dart';
import 'add_schedule_screen.dart';

class MonthCalendarViewScreen extends StatefulWidget {
  final String? clientId;
  final String? groupId;
  final String entityName;

  const MonthCalendarViewScreen({
    super.key,
    this.clientId,
    this.groupId,
    required this.entityName,
  });

  @override
  State<MonthCalendarViewScreen> createState() =>
      _MonthCalendarViewScreenState();
}

class _MonthCalendarViewScreenState extends State<MonthCalendarViewScreen> {
  List<ScheduleDayModel> _days = [];
  bool _isLoading = true;

  int _completed = 0;
  int _missed = 0;
  int _pending = 0;
  double _complianceRate = 0.0;

  @override
  void initState() {
    super.initState();
    _loadCalendarStream();
  }

  Future<void> _loadCalendarStream() async {
    setState(() => _isLoading = true);
    final data = await DatabaseService.instance.fetchScheduleForEntity(
      clientId: widget.clientId,
      groupId: widget.groupId,
    );

    int comp = 0, miss = 0, pend = 0;
    for (var d in data) {
      if (d.isWorkDay) {
        if (d.status == 'Completed') {
          comp++;
        } else if (d.status == 'Missed') {
          miss++;
        } else {
          pend++;
        }
      }
    }

    int totalPassed = comp + miss;

    setState(() {
      _days = data;
      _completed = comp;
      _missed = miss;
      _pending = pend;
      _complianceRate = totalPassed > 0 ? (comp / totalPassed) * 100 : 0.0;
      _isLoading = false;
    });
  }

  void _showDayDetailsDialog(ScheduleDayModel day) async {
    final workoutPlan = await DatabaseService.instance.fetchWorkoutPlanForDay(
      day.id,
    );
    final routineCtrl = TextEditingController(
      text:
          workoutPlan?.routineName ??
          (day.isWorkDay ? 'Push Day Split' : 'Rest Restorations'),
    );
    final exercisesCtrl = TextEditingController(
      text:
          workoutPlan?.exercisesJson ??
          (day.isWorkDay
              ? '1. Bench Press: 4x10\n2. Skullcrushers: 3x12'
              : 'No exercise tracks assigned. Enjoy your rest!'),
    );
    String currentStatus = day.status;
    bool localWorkToggle = day.isWorkDay;

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: Text(
            'Day ${day.dayNumber} Setup Studio (${DateFormat('MMM d').format(day.absoluteDate)})',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: const Text(
                    'Is Active Work Day',
                    style: TextStyle(fontSize: 14, color: Colors.white),
                  ),
                  value: localWorkToggle,
                  onChanged: (val) =>
                      setModalState(() => localWorkToggle = val),
                ),
                if (localWorkToggle) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: routineCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Routine Header Label',
                      labelStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: exercisesCtrl,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Exercise Routines Engine',
                      labelStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue:
                        [
                          'Pending',
                          'Completed',
                          'Missed',
                        ].contains(currentStatus)
                        ? currentStatus
                        : 'Pending',
                    dropdownColor: const Color(0xFF1E293B),
                    decoration: const InputDecoration(
                      labelText: 'Execution Status Flag',
                      labelStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(),
                    ),
                    items: ['Pending', 'Completed', 'Missed']
                        .map(
                          (s) => DropdownMenuItem(
                            value: s,
                            child: Text(
                              s,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setModalState(() => currentStatus = v!),
                  ),
                ],
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
                final updatedDay = ScheduleDayModel(
                  id: day.id,
                  clientId: day.clientId,
                  groupId: day.groupId,
                  dayNumber: day.dayNumber,
                  isWorkDay: localWorkToggle,
                  absoluteDate: day.absoluteDate,
                  status: localWorkToggle ? currentStatus : 'Pending',
                );

                final updatedPlan = WorkoutPlanModel(
                  id: 'plan_${day.id}',
                  dayScheduleId: day.id,
                  routineName: routineCtrl.text.trim(),
                  exercisesJson: exercisesCtrl.text.trim(),
                );

                await DatabaseService.instance.saveMonthlySchedule(
                  days: [updatedDay],
                  plans: localWorkToggle ? [updatedPlan] : [],
                );

                await DatabaseService.instance.updateScheduleDayStatus(
                  day.id,
                  localWorkToggle ? currentStatus : 'Pending',
                );

                if (context.mounted) {
                  Navigator.pop(context);
                  _loadCalendarStream();
                }
              },
              child: const Text('Save Day Matrix'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(
          '${widget.entityName}\'s Ledger',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0F172A),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _days.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No dynamic schedule initialized yet.',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddScheduleScreen(
                          clientId: widget.clientId,
                          groupId: widget.groupId,
                          entityName: widget.entityName,
                        ),
                      ),
                    ).then((_) => _loadCalendarStream()),
                    child: const Text('Initialize 30-Day Calendar Grid'),
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Compliance Calculation Matrix: ${_complianceRate.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.greenAccent,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatusIndicator(
                              'Completed',
                              '$_completed',
                              Colors.green,
                            ),
                            _buildStatusIndicator(
                              'Missed',
                              '$_missed',
                              Colors.red,
                            ),
                            _buildStatusIndicator(
                              'Pending',
                              '$_pending',
                              Colors.amber,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 5,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                      itemCount: _days.length,
                      itemBuilder: (context, index) {
                        final day = _days[index];
                        Color cardColor = const Color(0xFF1E293B);
                        IconData? statusIcon;

                        if (!day.isWorkDay) {
                          cardColor = Colors.grey[900]!;
                        } else {
                          if (day.status == 'Completed') {
                            cardColor = Colors.green[900]!;
                            statusIcon = Icons.check_circle;
                          } else if (day.status == 'Missed') {
                            cardColor = Colors.red[900]!;
                            statusIcon = Icons.cancel;
                          } else {
                            cardColor = Colors.blueGrey[800]!;
                            statusIcon = Icons.pending;
                          }
                        }

                        return InkWell(
                          onTap: () => _showDayDetailsDialog(day),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Day ${day.dayNumber}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  DateFormat('MMM d').format(day.absoluteDate),
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: Colors.white54,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  day.isWorkDay ? 'Work' : 'Rest',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: day.isWorkDay
                                        ? Colors.blueAccent
                                        : Colors.grey,
                                  ),
                                ),
                                if (statusIcon != null) ...[
                                  const SizedBox(height: 4),
                                  Icon(
                                    statusIcon,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusIndicator(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}
