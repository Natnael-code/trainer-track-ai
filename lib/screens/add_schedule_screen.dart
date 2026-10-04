import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/fitness_models.dart';
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

  // Configuration maps
  final Map<int, bool> _dayWorkStatusMap = {};
  final Map<int, String> _dayRoutineNameMap = {};
  final Map<int, String> _dayExercisesMap = {};

  bool _isSaving = false;
  bool _isLoadingSaved = true;
  bool _hasExistingPlan = false;

  // Calculates exact total days for the selected calendar month (28, 29, 30, or 31)
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
      // Baseline initialization if no schedule exists
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

  void _configureSpecificDayDialog(int dayNum) {
    final routineCtrl = TextEditingController(
      text: _dayRoutineNameMap[dayNum] ?? 'General Split',
    );
    final exercisesCtrl = TextEditingController(
      text: _dayExercisesMap[dayNum] ?? '1. Standard Warmup',
    );
    bool isWork = _dayWorkStatusMap[dayNum] ?? true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: Text(
            'Configure Plan: Day $dayNum',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: const Text(
                    'Is Active Workout Day',
                    style: TextStyle(fontSize: 14, color: Colors.white),
                  ),
                  value: isWork,
                  onChanged: (val) => setModalState(() => isWork = val),
                ),
                if (isWork) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: routineCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Routine Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: exercisesCtrl,
                    style: const TextStyle(color: Colors.white),
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
              onPressed: () {
                setState(() {
                  _dayWorkStatusMap[dayNum] = isWork;
                  _dayRoutineNameMap[dayNum] = routineCtrl.text.trim();
                  _dayExercisesMap[dayNum] = exercisesCtrl.text.trim();
                });
                Navigator.pop(context);
              },
              child: const Text('Apply Changes'),
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
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    int totalDaysInMonth = _daysInSelectedMonth;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(
          '${_hasExistingPlan ? "Edit" : "Build"} Plan for ${widget.entityName}',
          style: const TextStyle(fontSize: 16, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0F172A),
        iconTheme: const IconThemeData(color: Colors.white),
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
                        color: Colors.blueAccent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blueAccent),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.info_outline, color: Colors.blueAccent),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Loaded saved workout plan. Edit any day and re-deploy updates.',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PLAN MONTH: ${DateFormat('MMMM yyyy').format(_startDate).toUpperCase()} ($totalDaysInMonth DAYS)',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat(
                                'EEEE, MMMM dd, yyyy',
                              ).format(_startDate),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.calendar_month, size: 18),
                          label: const Text('Change'),
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
                  const Text(
                    'Click any specific day block to edit exercise targets:',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
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
                          onTap: () => _configureSpecificDayDialog(dayNum),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isWork
                                  ? const Color(0xFF1E293B)
                                  : Colors.red.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isWork
                                    ? Colors.blueAccent.withOpacity(0.4)
                                    : Colors.redAccent.withOpacity(0.3),
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Day $dayNum',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  DateFormat('MMM d').format(calculatedDayDate),
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Icon(
                                  isWork ? Icons.fitness_center : Icons.bed,
                                  size: 12,
                                  color: isWork
                                      ? Colors.blueAccent
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
                        backgroundColor: Colors.blueAccent,
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
