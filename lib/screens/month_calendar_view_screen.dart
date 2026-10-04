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

  void _showReadOnlyDayDialog(ScheduleDayModel day) async {
    final workoutPlan = await DatabaseService.instance.fetchWorkoutPlanForDay(
      day.id,
    );
    final String routine =
        workoutPlan?.routineName ??
        (day.isWorkDay ? 'Standard Workout Routine' : 'Rest & Recovery Day');
    final String exercises =
        workoutPlan?.exercisesJson ??
        (day.isWorkDay
            ? 'No exercise list attached.'
            : 'Rest day! Allow muscles time to rebuild.');

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Row(
          children: [
            Icon(
              day.isWorkDay ? Icons.fitness_center : Icons.bed,
              color: day.isWorkDay ? Colors.blueAccent : Colors.redAccent,
            ),
            const SizedBox(width: 8),
            Text(
              'Day ${day.dayNumber} (${DateFormat('MMM d').format(day.absoluteDate)})',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: day.isWorkDay ? Colors.blue[900] : Colors.grey[800],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  day.isWorkDay ? 'WORKOUT DAY' : 'REST DAY',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Routine Header:',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                routine,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Exercise Targets:',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  exercises,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
              if (day.isWorkDay) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Text(
                      'Status: ',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    Text(
                      day.status,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: day.status == 'Completed'
                            ? Colors.greenAccent
                            : day.status == 'Missed'
                            ? Colors.redAccent
                            : Colors.amberAccent,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.grey)),
          ),
          if (day.isWorkDay) ...[
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red[800]),
              icon: const Icon(Icons.close, size: 16, color: Colors.white),
              label: const Text(
                'Mark Missed',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () async {
                await DatabaseService.instance.updateScheduleDayStatus(
                  day.id,
                  'Missed',
                );
                if (mounted) {
                  Navigator.pop(context);
                  _loadCalendarStream();
                }
              },
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
              ),
              icon: const Icon(Icons.check, size: 16, color: Colors.white),
              label: const Text(
                'Mark Done',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () async {
                await DatabaseService.instance.updateScheduleDayStatus(
                  day.id,
                  'Completed',
                );
                if (mounted) {
                  Navigator.pop(context);
                  _loadCalendarStream();
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(
          '${widget.entityName}\'s Calendar Ledger',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0F172A),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_calendar, color: Colors.blueAccent),
            tooltip: 'Configure / Edit Routine',
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
          ),
        ],
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
                    'No active plan deployed yet.',
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
                    child: const Text('Initialize Monthly Calendar Grid'),
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Active Plan Notification Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.green),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.check_circle_outline,
                              color: Colors.greenAccent,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Active Plan Deployed (${_days.length} Days)',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        TextButton(
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
                          child: const Text(
                            'Edit Plan',
                            style: TextStyle(color: Colors.blueAccent),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Compliance Rate: ${_complianceRate.toStringAsFixed(1)}%',
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
                          onTap: () => _showReadOnlyDayDialog(day),
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
