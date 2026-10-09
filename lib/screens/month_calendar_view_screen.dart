import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/fitness_models.dart';
import '../providers/client_provider.dart';
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

    if (mounted) {
      setState(() {
        _days = data;
        _completed = comp;
        _missed = miss;
        _pending = pend;
        _complianceRate = totalPassed > 0 ? (comp / totalPassed) * 100 : 0.0;
        _isLoading = false;
      });
    }
  }

  void _showReadOnlyDayDialog(ScheduleDayModel day, bool isDark) async {
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

    final dialogBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: dialogBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              day.isWorkDay ? Icons.fitness_center : Icons.bed,
              color: day.isWorkDay ? const Color(0xFF3B82F6) : Colors.redAccent,
            ),
            const SizedBox(width: 8),
            Text(
              'Day ${day.dayNumber} (${DateFormat('MMM d').format(day.absoluteDate)})',
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
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
                  color: day.isWorkDay
                      ? const Color(0xFF2563EB)
                      : Colors.grey[800],
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
                style: TextStyle(
                  color: textColor,
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
                  color: isDark
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  exercises,
                  style: TextStyle(color: textColor, fontSize: 13),
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
                            ? const Color(0xFF10B981)
                            : day.status == 'Missed'
                            ? Colors.redAccent
                            : Colors.amber,
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
                backgroundColor: const Color(0xFF10B981),
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
    final clientProvider = Provider.of<ClientProvider>(context);
    final isDark = clientProvider.isDarkMode;

    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          '${widget.entityName}\'s Calendar Ledger',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: bgColor,
        iconTheme: IconThemeData(color: textColor),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_calendar, color: Color(0xFF3B82F6)),
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
                  Text(
                    'No active plan deployed yet.',
                    style: TextStyle(color: textColor.withAlpha(180)),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                    ),
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
                      'Initialize Monthly Calendar Grid',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withAlpha(35),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF10B981)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          color: Color(0xFF10B981),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Active Plan Deployed (${_days.length} Days)',
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? Colors.white10
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Compliance Rate: ${_complianceRate.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF10B981),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatusIndicator(
                              'Completed',
                              '$_completed',
                              const Color(0xFF10B981),
                            ),
                            _buildStatusIndicator(
                              'Missed',
                              '$_missed',
                              Colors.redAccent,
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
                        Color cardColor = cardBg;
                        IconData? statusIcon;

                        if (!day.isWorkDay) {
                          cardColor = isDark
                              ? Colors.grey[900]!
                              : Colors.grey[200]!;
                        } else {
                          if (day.status == 'Completed') {
                            cardColor = const Color(0xFF065F46);
                            statusIcon = Icons.check_circle;
                          } else if (day.status == 'Missed') {
                            cardColor = const Color(0xFF991B1B);
                            statusIcon = Icons.cancel;
                          } else {
                            cardColor = isDark
                                ? const Color(0xFF1E293B)
                                : const Color(0xFFE2E8F0);
                            statusIcon = Icons.pending;
                          }
                        }

                        return InkWell(
                          onTap: () => _showReadOnlyDayDialog(day, isDark),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white10
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Day ${day.dayNumber}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color:
                                        (day.isWorkDay &&
                                            (day.status == 'Completed' ||
                                                day.status == 'Missed'))
                                        ? Colors.white
                                        : textColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  DateFormat('MMM d').format(day.absoluteDate),
                                  style: TextStyle(
                                    fontSize: 9,
                                    color:
                                        (day.isWorkDay &&
                                            (day.status == 'Completed' ||
                                                day.status == 'Missed'))
                                        ? Colors.white70
                                        : Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  day.isWorkDay ? 'Work' : 'Rest',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: day.isWorkDay
                                        ? const Color(0xFF3B82F6)
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
