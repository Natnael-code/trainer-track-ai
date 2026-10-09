import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/fitness_models.dart';
import '../providers/client_provider.dart';
import '../services/database_service.dart';

class AddScheduleScreen extends StatefulWidget {
  final String? clientId;
  final String? groupId;
  final String entityName;

  const AddScheduleScreen({
    super.key,
    this.clientId,
    this.groupId,
    required this.entityName,
  });

  @override
  State<AddScheduleScreen> createState() => _AddScheduleScreenState();
}

class _AddScheduleScreenState extends State<AddScheduleScreen> {
  DateTime _startDate = DateTime.now();

  final Map<int, bool> _dayWorkStatusMap = {};
  final Map<int, String> _dayRoutineNameMap = {};
  final Map<int, String> _dayExercisesMap = {};

  bool _isSaving = false;
  bool _isLoadingSaved = true;
  bool _hasExistingPlan = false;

  int get _daysInSelectedMonth =>
      DateTime(_startDate.year, _startDate.month + 1, 0).day;

  @override
  void initState() {
    super.initState();
    _loadExistingSchedule();
  }

  Future<void> _loadExistingSchedule() async {
    setState(() => _isLoadingSaved = true);

    final existingDays = await DatabaseService.instance.fetchScheduleForEntity(
      clientId: widget.clientId,
      groupId: widget.groupId,
    );

    if (existingDays.isNotEmpty) {
      _hasExistingPlan = true;
      _startDate = existingDays.first.absoluteDate;

      for (var day in existingDays) {
        _dayWorkStatusMap[day.dayNumber] = day.isWorkDay;
        final plan = await DatabaseService.instance.fetchWorkoutPlanForDay(
          day.id,
        );
        if (plan != null) {
          _dayRoutineNameMap[day.dayNumber] = plan.routineName;
          _dayExercisesMap[day.dayNumber] = plan.exercisesJson;
        } else {
          _dayRoutineNameMap[day.dayNumber] = 'General Fullbody Split';
          _dayExercisesMap[day.dayNumber] =
              '1. Pushups: 3x15\n2. Bodyweight Squats: 3x20\n3. Plank: 60s';
        }
      }
    } else {
      int totalDays = _daysInSelectedMonth;
      for (int i = 1; i <= totalDays; i++) {
        _dayWorkStatusMap[i] = true;
        _dayRoutineNameMap[i] = 'General Fullbody Split';
        _dayExercisesMap[i] =
            '1. Pushups: 3x15\n2. Bodyweight Squats: 3x20\n3. Plank: 60s';
      }
    }

    if (mounted) {
      setState(() => _isLoadingSaved = false);
    }
  }

  void _configureSpecificDayDialog(int dayNum, bool isDark) {
    final routineCtrl = TextEditingController(
      text: _dayRoutineNameMap[dayNum] ?? 'General Split',
    );
    final exercisesCtrl = TextEditingController(
      text: _dayExercisesMap[dayNum] ?? '1. Standard Warmup',
    );
    bool isWork = _dayWorkStatusMap[dayNum] ?? true;

    final dialogBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: dialogBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Configure Plan: Day $dayNum',
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Active Workout Day',
                    style: TextStyle(
                      fontSize: 14,
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  value: isWork,
                  activeColor: const Color(0xFF3B82F6),
                  onChanged: (val) => setModalState(() => isWork = val),
                ),
                if (isWork) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: routineCtrl,
                    style: TextStyle(color: textColor),
                    decoration: const InputDecoration(
                      labelText: 'Routine Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: exercisesCtrl,
                    style: TextStyle(color: textColor),
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Target Exercises List',
                      border: OutlineInputBorder(),
                    ),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
              ),
              onPressed: () {
                setState(() {
                  _dayWorkStatusMap[dayNum] = isWork;
                  _dayRoutineNameMap[dayNum] = routineCtrl.text.trim();
                  _dayExercisesMap[dayNum] = exercisesCtrl.text.trim();
                });
                Navigator.pop(context);
              },
              child: const Text(
                'Apply Changes',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deployFinalizedSchedule() async {
    setState(() => _isSaving = true);

    final List<ScheduleDayModel> deploymentDays = [];
    final List<WorkoutPlanModel> deploymentPlans = [];
    final String entityPrefix = widget.clientId ?? widget.groupId ?? 'entity';
    int totalDaysInMonth = _daysInSelectedMonth;

    for (int dayNum = 1; dayNum <= totalDaysInMonth; dayNum++) {
      final DateTime runningDate = _startDate.add(Duration(days: dayNum - 1));
      final String dayId =
          '${entityPrefix}_day_${dayNum}_${_startDate.millisecondsSinceEpoch}';

      final isWork = _dayWorkStatusMap[dayNum] ?? true;

      final dayNode = ScheduleDayModel(
        id: dayId,
        clientId: widget.clientId,
        groupId: widget.groupId,
        dayNumber: dayNum,
        isWorkDay: isWork,
        absoluteDate: runningDate,
        status: 'Pending',
      );
      deploymentDays.add(dayNode);

      if (isWork) {
        final planNode = WorkoutPlanModel(
          id: 'plan_$dayId',
          dayScheduleId: dayId,
          routineName: _dayRoutineNameMap[dayNum] ?? 'Workout Split',
          exercisesJson: _dayExercisesMap[dayNum] ?? '',
        );
        deploymentPlans.add(planNode);
      }
    }

    await DatabaseService.instance.saveMonthlySchedule(
      days: deploymentDays,
      plans: deploymentPlans,
    );
    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Saved $totalDaysInMonth-Day Routine starting ${DateFormat('MMM d').format(_startDate)}!',
          ),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final clientProvider = Provider.of<ClientProvider>(context);
    final isDark = clientProvider.isDarkMode;

    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subTextColor = isDark ? Colors.grey[400] : Colors.grey[600];

    int totalDaysInMonth = _daysInSelectedMonth;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          '${_hasExistingPlan ? "Edit" : "Build"} Plan for ${widget.entityName}',
          style: TextStyle(
            fontSize: 16,
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: bgColor,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: _isLoadingSaved
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_hasExistingPlan)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withAlpha(38),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF3B82F6)),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.info_outline, color: Color(0xFF3B82F6)),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Loaded saved workout plan. Edit any day and re-deploy updates.',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PLAN MONTH: ${DateFormat('MMMM yyyy').format(_startDate).toUpperCase()} ($totalDaysInMonth DAYS)',
                              style: TextStyle(
                                fontSize: 11,
                                color: subTextColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat(
                                'EEEE, MMMM dd, yyyy',
                              ).format(_startDate),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.calendar_month, size: 18),
                          label: const Text('Change'),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF3B82F6),
                          ),
                          onPressed: () async {
                            final chosen = await showDatePicker(
                              context: context,
                              initialDate: _startDate,
                              firstDate: DateTime.now().subtract(
                                const Duration(days: 30),
                              ),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                            );
                            if (chosen != null) {
                              setState(() {
                                _startDate = chosen;
                                _loadExistingSchedule();
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Click any specific day block to edit exercise targets:',
                    style: TextStyle(fontSize: 12, color: subTextColor),
                  ),
                  const SizedBox(height: 12),

                  Expanded(
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 5,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                      itemCount: totalDaysInMonth,
                      itemBuilder: (context, index) {
                        final int dayNum = index + 1;
                        final bool isWork = _dayWorkStatusMap[dayNum] ?? true;
                        final DateTime calculatedDayDate = _startDate.add(
                          Duration(days: dayNum - 1),
                        );

                        return InkWell(
                          onTap: () =>
                              _configureSpecificDayDialog(dayNum, isDark),
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: isWork
                                  ? (isDark
                                        ? const Color(0xFF1E293B)
                                        : Colors.white)
                                  : Colors.red.withAlpha(25),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isWork
                                    ? const Color(0xFF3B82F6).withAlpha(100)
                                    : Colors.redAccent.withAlpha(80),
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Day $dayNum',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  DateFormat('MMM d').format(calculatedDayDate),
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: subTextColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Icon(
                                  isWork ? Icons.fitness_center : Icons.bed,
                                  size: 14,
                                  color: isWork
                                      ? const Color(0xFF3B82F6)
                                      : Colors.redAccent,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isSaving ? null : _deployFinalizedSchedule,
                      child: _isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              _hasExistingPlan
                                  ? 'Update Saved Plan'
                                  : 'Deploy Final Routine Grid',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
