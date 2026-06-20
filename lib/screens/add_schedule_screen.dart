import 'package:flutter/material.dart';
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
  final _formKey = GlobalKey<FormState>();
  String _selectedMonth = 'July_2026';
  String _schedulePattern = 'Every Other Day';

  final TextEditingController _workoutRoutineController = TextEditingController(
    text:
        '1. Bench Press: 4x10\n2. Overhead Press: 3x12\n3. Tricep Pushdowns: 4x15',
  );
  final TextEditingController _routineNameController = TextEditingController(
    text: 'Push Day Split',
  );

  bool _isProcessing = false;

  void _generateAndSaveSchedule() async {
    setState(() => _isProcessing = true);

    final List<ScheduleDayModel> generatedDays = [];
    final List<WorkoutPlanModel> generatedPlans = [];
    final String baseId = widget.clientId ?? widget.groupId ?? 'unknown';

    for (int i = 1; i <= 30; i++) {
      bool isWork = true;

      if (_schedulePattern == 'Every Other Day') {
        isWork = i % 2 != 0;
      } else {
        int cycleDay = i % 7;
        if (cycleDay == 6 || cycleDay == 0) isWork = false;
      }

      final dayId = '${baseId}_${_selectedMonth}_day_$i';

      generatedDays.add(
        ScheduleDayModel(
          id: dayId,
          clientId: widget.clientId,
          groupId: widget.groupId,
          dayNumber: i,
          isWorkDay: isWork,
          monthConfigId: _selectedMonth,
        ),
      );

      if (isWork) {
        generatedPlans.add(
          WorkoutPlanModel(
            id: 'plan_$dayId',
            dayScheduleId: dayId,
            routineName: _routineNameController.text.trim(),
            exercisesJson: _workoutRoutineController.text.trim(),
          ),
        );
      }
    }

    await DatabaseService.instance.saveMonthlySchedule(
      days: generatedDays,
      plans: generatedPlans,
    );

    setState(() => _isProcessing = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('30-Day Calendar Generated for ${widget.entityName}!'),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Setup Month: ${widget.entityName}'),
        backgroundColor: const Color(0xFF0F172A),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Configure Monthly Cycle Blocks',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: _selectedMonth,
                  decoration: const InputDecoration(
                    labelText: 'Target Performance Month',
                    border: OutlineInputBorder(),
                  ),
                  items: ['July_2026', 'August_2026', 'September_2026'].map((
                    m,
                  ) {
                    return DropdownMenuItem(
                      value: m,
                      child: Text(m.replaceAll('_', ' ')),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedMonth = val!),
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: _schedulePattern,
                  decoration: const InputDecoration(
                    labelText: 'Rest/Work Day Alternation Split',
                    border: OutlineInputBorder(),
                  ),
                  items: ['Every Other Day', '5 Days Work / 2 Rest'].map((p) {
                    return DropdownMenuItem(value: p, child: Text(p));
                  }).toList(),
                  onChanged: (val) => setState(() => _schedulePattern = val!),
                ),
                const SizedBox(height: 20),

                const Divider(color: Colors.white),
                // Syntax issue cleanly resolved here
                const SizedBox(height: 12),

                const Text(
                  'Default Work Day Workout Routine Template',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _routineNameController,
                  decoration: const InputDecoration(
                    labelText: 'Routine Split Identifier Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _workoutRoutineController,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Exercises List (Sets x Reps)',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _isProcessing ? null : _generateAndSaveSchedule,
                    child: _isProcessing
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Compile & Build 30-Day Plan',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
