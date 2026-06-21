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

  // Temporary map cache storing configuration changes safely during draft modes
  final Map<int, bool> _dayWorkStatusMap = {};
  final Map<int, String> _dayRoutineNameMap = {};
  final Map<int, String> _dayExercisesMap = {};

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Initialize standard baseline templates for all 30 blocks
    for (int i = 1; i <= 30; i++) {
      _dayWorkStatusMap[i] = true; // Default to active training days
      _dayRoutineNameMap[i] = 'General Fullbody Split';
      _dayExercisesMap[i] =
          '1. Pushups: 3x15\n2. Bodyweight Squats: 3x20\n3. Plank Challenge: 60s';
    }
  }

  void _configureSpecificDayDialog(int dayNum) {
    final routineCtrl = TextEditingController(text: _dayRoutineNameMap[dayNum]);
    final exercisesCtrl = TextEditingController(text: _dayExercisesMap[dayNum]);
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
                    style: TextStyle(fontSize: 14),
                  ),
                  value: isWork,
                  onChanged: (val) => setModalState(() => isWork = val),
                ),
                if (isWork) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: routineCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Routine Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: exercisesCtrl,
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

    for (int dayNum = 1; dayNum <= 30; dayNum++) {
      // Calculate specific calendar date for this relative day milestone
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
            'Custom 30-Day Plan Deployed Live starting ${DateFormat('MMM d').format(_startDate)}!',
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(
          'Build Plan for ${widget.entityName}',
          style: const TextStyle(fontSize: 16),
        ),
        backgroundColor: const Color(0xFF0F172A),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Calendar anchor selection section
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
                      const Text(
                        'PLAN START DATE (DAY 1)',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('EEEE, MMMM dd, yyyy').format(_startDate),
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
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (chosen != null) setState(() => _startDate = chosen);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Click any specific box block to write custom exercise targets for that workout day:',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
            const SizedBox(height: 12),

            // Visual day distribution configuration engine board matrix
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: 30,
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
                    : const Text(
                        'Deploy Final Routine Grid',
                        style: TextStyle(
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
