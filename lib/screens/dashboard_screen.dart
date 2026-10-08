import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/client_provider.dart';
import '../models/client_model.dart';
import '../models/fitness_models.dart';
import '../services/database_service.dart';
import 'add_schedule_screen.dart';
import 'month_calendar_view_screen.dart';
import 'group_detail_screen.dart';
import 'ai_advisor_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final String developerEmail = 'developer.support@coachapp.com';

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

  // --- TOP RIGHT MENU: MODE SWITCH, DEVELOPER EMAIL & BACKUP INFO ---
  void _showSettingsAndBackupBottomSheet(
    BuildContext context,
    ClientProvider provider,
    bool isDark,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
            final subTextColor = isDark ? Colors.grey[400] : Colors.grey[600];
            final cardBg = isDark
                ? const Color(0xFF0F172A)
                : const Color(0xFFF1F5F9);

            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'App Settings & Info',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: subTextColor),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 8),

                  // 1. Theme Switch (Dark & Bright Mode)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              provider.isDarkMode
                                  ? Icons.dark_mode
                                  : Icons.light_mode,
                              color: provider.isDarkMode
                                  ? Colors.amber
                                  : Colors.orangeAccent,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              provider.isDarkMode ? 'Dark Mode' : 'Bright Mode',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                        Switch.adaptive(
                          value: provider.isDarkMode,
                          activeColor: const Color(0xFF3B82F6),
                          onChanged: (val) {
                            provider.toggleTheme();
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 2. Developer Email Contact Info
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.email_outlined,
                          color: Color(0xFF3B82F6),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Developer Contact Email',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: subTextColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              SelectableText(
                                developerEmail,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 3. Backup Data Explanation & Action
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? Colors.blueAccent.withOpacity(0.3)
                            : Colors.blueAccent.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.shield_outlined,
                              color: Color(0xFF10B981),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'What Data Backup Does',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Backing up exports a complete, encrypted copy of all your client profiles, group schedules, workout plans, and progress logs to local storage. This safeguards your data against loss and allows quick restoration.',
                          style: TextStyle(
                            fontSize: 12,
                            color: subTextColor,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          height: 40,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: const Icon(
                              Icons.download_outlined,
                              size: 18,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'Run Data Backup Now',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: () async {
                              await provider.backupData();
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Database backup exported successfully!',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- TWO-STEP VERIFICATION FOR DELETING PERSONAL CLIENT ---
  void _startDeleteClientFlow(
    BuildContext context,
    ClientModel client,
    bool isDark,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Client Management',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Manage options or remove ${client.name} from your client roster.',
          style: TextStyle(color: isDark ? Colors.white70 : Colors.grey[700]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: isDark ? Colors.grey : Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(context);
              _confirmDeleteClientStepTwo(context, client, isDark);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteClientStepTwo(
    BuildContext context,
    ClientModel client,
    bool isDark,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text(
              'Confirm Deletion',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'Are u sure this will permantely delete the client?',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: isDark ? Colors.grey : Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              await DatabaseService.instance.deleteClient(client.id);
              if (context.mounted) {
                await Provider.of<ClientProvider>(
                  context,
                  listen: false,
                ).loadClientsFromDatabase();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${client.name} permanently deleted.'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            child: const Text(
              'Permanently Delete',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(
    ImageSource source,
    TextEditingController photoPathCtrl,
    StateSetter setModalState,
  ) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setModalState(() {
        photoPathCtrl.text = pickedFile.path;
      });
    }
  }

  void _showImagePickerOptions(
    BuildContext context,
    TextEditingController photoPathCtrl,
    StateSetter setModalState,
    bool isDark,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: Colors.blueAccent,
              ),
              title: Text(
                'Choose from Gallery',
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery, photoPathCtrl, setModalState);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blueAccent),
              title: Text(
                'Take Photo using Camera',
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera, photoPathCtrl, setModalState);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddClientDialog(bool isDark) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final ageCtrl = TextEditingController(text: '25');
    final weightCtrl = TextEditingController(text: '70');
    final heightCtrl = TextEditingController(text: '175');
    final photoPathCtrl = TextEditingController();

    String expLevel = 'Beginner';
    int availableDays = 5;
    int sessionsPerDay = 1;
    String goal = 'Lose Weight';

    bool isSavingClient = false;

    final bgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: bgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          double calcWeight = double.tryParse(weightCtrl.text) ?? 70.0;
          double calcHeight = double.tryParse(heightCtrl.text) ?? 175.0;
          double heightMeters = calcHeight / 100.0;
          double previewBmi = heightMeters > 0
              ? calcWeight / (heightMeters * heightMeters)
              : 0.0;

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 16,
              left: 16,
              right: 16,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: textColor),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Register New Personal Client',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameCtrl,
                    style: TextStyle(color: textColor),
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneCtrl,
                    style: TextStyle(color: textColor),
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
                          style: TextStyle(color: textColor),
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
                          style: TextStyle(color: textColor),
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
                          style: TextStyle(color: textColor),
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
                      color: Colors.green,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: photoPathCtrl,
                    readOnly: true,
                    style: TextStyle(color: textColor),
                    onTap: () => _showImagePickerOptions(
                      context,
                      photoPathCtrl,
                      setModalState,
                      isDark,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Profile Photo',
                      hintText: photoPathCtrl.text.isEmpty
                          ? 'Tap camera icon to add photo'
                          : photoPathCtrl.text,
                      hintStyle: const TextStyle(color: Colors.grey),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(
                          Icons.camera_alt,
                          color: Colors.blueAccent,
                        ),
                        onPressed: () => _showImagePickerOptions(
                          context,
                          photoPathCtrl,
                          setModalState,
                          isDark,
                        ),
                      ),
                    ),
                  ),
                  if (photoPathCtrl.text.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: File(photoPathCtrl.text).existsSync()
                              ? Image.file(
                                  File(photoPathCtrl.text),
                                  width: 45,
                                  height: 45,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  width: 45,
                                  height: 45,
                                  color: Colors.grey[400],
                                  child: const Icon(
                                    Icons.image,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            photoPathCtrl.text,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: goal,
                    dropdownColor: bgColor,
                    decoration: const InputDecoration(
                      labelText: 'Fitness Goal',
                      border: OutlineInputBorder(),
                    ),
                    items: ['Lose Weight', 'Gain Weight', 'Maintain Weight']
                        .map(
                          (g) => DropdownMenuItem(
                            value: g,
                            child: Text(g, style: TextStyle(color: textColor)),
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
                          dropdownColor: bgColor,
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
                                    style: TextStyle(color: textColor),
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
                          dropdownColor: bgColor,
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
                                    style: TextStyle(color: textColor),
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
                    dropdownColor: bgColor,
                    decoration: const InputDecoration(
                      labelText: 'Experience Level',
                      border: OutlineInputBorder(),
                    ),
                    items: ['Beginner', 'Intermediate', 'Advanced']
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(e, style: TextStyle(color: textColor)),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setModalState(() => expLevel = v!),
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
                                lifestyleType: 'Active',
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

  void _showClientProgressDialog(ClientModel client, bool isDark) {
    final bgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: bgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => FutureBuilder<List<ClientProgressModel>>(
          future: DatabaseService.instance.fetchProgressForClient(client.id),
          builder: (context, snapshot) {
            List<ClientProgressModel> progressList = [...(snapshot.data ?? [])];

            bool hasInit = progressList.any((p) => p.id.contains('init'));
            if (!hasInit) {
              final initialStep = ClientProgressModel(
                id: 'progress_init_${client.id}',
                clientId: client.id,
                weight: client.startingWeight,
                height: client.height,
                bmi: client.bmi,
                imagePath: client.localProfileImagePath,
                date: client.joinedDate,
                notes: 'Initial Registration Baseline',
              );
              progressList.insert(0, initialStep);
            }

            progressList.sort((a, b) => a.date.compareTo(b.date));

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
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
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
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Tap any progress step below to view photo and full details:',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
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
                                final bool isFirstStep = idx == 0;
                                final String stepLabel = isFirstStep
                                    ? 'Step 1: First Saved Registration'
                                    : 'Step ${idx + 1}: Progress Update';

                                return InkWell(
                                  onTap: () => _showProgressDetailDialog(
                                    context,
                                    p,
                                    idx + 1,
                                    isDark,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF0F172A)
                                          : const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isFirstStep
                                            ? Colors.blueAccent.withOpacity(0.5)
                                            : Colors.black12,
                                      ),
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
                                                  width: 55,
                                                  height: 55,
                                                  fit: BoxFit.cover,
                                                ),
                                              )
                                            : Container(
                                                width: 55,
                                                height: 55,
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[300],
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Icon(
                                                  isFirstStep
                                                      ? Icons.app_registration
                                                      : Icons.show_chart,
                                                  color: isFirstStep
                                                      ? Colors.blueAccent
                                                      : Colors.green,
                                                ),
                                              ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                stepLabel,
                                                style: TextStyle(
                                                  color: isFirstStep
                                                      ? Colors.blueAccent
                                                      : textColor,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                DateFormat(
                                                  'MMM dd, yyyy',
                                                ).format(p.date),
                                                style: TextStyle(
                                                  color: isDark
                                                      ? Colors.white70
                                                      : Colors.grey[700],
                                                  fontSize: 11,
                                                ),
                                              ),
                                              Text(
                                                'Weight: ${p.weight}kg • Height: ${p.height}cm • BMI: ${p.bmi.toStringAsFixed(1)}',
                                                style: const TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(
                                          Icons.chevron_right,
                                          color: Colors.grey,
                                        ),
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
          },
        ),
      ),
    );
  }

  void _showProgressDetailDialog(
    BuildContext context,
    ClientProgressModel progress,
    int stepIndex,
    bool isDark,
  ) {
    final bgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                stepIndex == 1
                    ? 'Step 1: First Saved Registration'
                    : 'Step $stepIndex: Saved Progress Change',
                style: TextStyle(
                  color: textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.grey),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (progress.imagePath != null &&
                  progress.imagePath!.isNotEmpty &&
                  File(progress.imagePath!).existsSync())
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(progress.imagePath!),
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  height: 130,
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.image_not_supported,
                        size: 38,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 6),
                      Text(
                        'No progress photo attached to this step',
                        style: TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 14),
              Text(
                DateFormat('EEEE, MMMM d, yyyy').format(progress.date),
                style: const TextStyle(
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Weight:',
                          style: TextStyle(color: Colors.grey),
                        ),
                        Text(
                          '${progress.weight} kg',
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Height:',
                          style: TextStyle(color: Colors.grey),
                        ),
                        Text(
                          '${progress.height} cm',
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'BMI:',
                          style: TextStyle(color: Colors.grey),
                        ),
                        Text(
                          progress.bmi.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (progress.notes != null && progress.notes!.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Notes:',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  progress.notes!,
                  style: TextStyle(color: textColor, fontSize: 13),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showAddProgressLogDialog(
    ClientModel client, {
    required VoidCallback onAdded,
    required bool isDark,
  }) {
    final weightCtrl = TextEditingController(
      text: client.startingWeight.toString(),
    );
    final heightCtrl = TextEditingController(text: client.height.toString());
    final photoCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    final bgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: bgColor,
        title: Text('Add Progress Entry', style: TextStyle(color: textColor)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: weightCtrl,
                style: TextStyle(color: textColor),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Current Weight (kg)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: heightCtrl,
                style: TextStyle(color: textColor),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Current Height (cm)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: photoCtrl,
                style: TextStyle(color: textColor),
                decoration: const InputDecoration(
                  labelText: 'Progress Photo File Path',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
                style: TextStyle(color: textColor),
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

  void _showAddGroupDialog(bool isDark) {
    final groupNameCtrl = TextEditingController();
    final bgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? const Color(0xFF0F172A) : Colors.white;

    showModalBottomSheet(
      context: context,
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Form Training Group',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: groupNameCtrl,
              style: TextStyle(color: textColor),
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
    final isDark = clientProvider.isDarkMode;

    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subTextColor = isDark ? Colors.grey[400] : Colors.grey[600];

    final personalClients = clientProvider.clients
        .where((c) => c.groupId == null || c.groupId!.isEmpty)
        .toList();

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Top Bar with Greeting + AI Advisor + Settings/Info Icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getGreetingText(now.hour),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      Text(
                        formattedDate,
                        style: TextStyle(fontSize: 14, color: subTextColor),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // Launch AI Advisor Screen
                      IconButton(
                        icon: const Icon(
                          Icons.auto_awesome,
                          color: Colors.blueAccent,
                          size: 26,
                        ),
                        tooltip: 'TrainerTrack AI Advisor',
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AiAdvisorScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _showSettingsAndBackupBottomSheet(
                          context,
                          clientProvider,
                          isDark,
                        ),
                        child: CircleAvatar(
                          backgroundColor: isDark
                              ? const Color(0xFF1E293B)
                              : const Color(0xFFE2E8F0),
                          child: Icon(
                            isDark ? Icons.dark_mode : Icons.light_mode,
                            color: isDark ? Colors.amber : Colors.orangeAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Active Personal Clients',
                      value: '${personalClients.length}',
                      icon: Icons.person,
                      color: const Color(0xFF3B82F6),
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Active Groups',
                      value: '${clientProvider.totalActiveGroups}',
                      icon: Icons.hub,
                      color: const Color(0xFF10B981),
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                height: 50,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFE2E8F0),
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
                  unselectedLabelColor: subTextColor,
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
                    personalClients.isEmpty
                        ? _buildEmptyState('No personal clients assigned.')
                        : ListView.builder(
                            itemCount: personalClients.length,
                            itemBuilder: (context, idx) => _buildWideItemCard(
                              context,
                              personalClients[idx],
                              isDark,
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
                              isDark,
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
            _showAddClientDialog(isDark);
          } else {
            _showAddGroupDialog(isDark);
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
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWideItemCard(
    BuildContext context,
    ClientModel client,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _startDeleteClientFlow(context, client, isDark),
            child: Tooltip(
              message: 'Tap to manage/delete client',
              child:
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
                      backgroundColor: isDark
                          ? Colors.grey[800]
                          : Colors.grey[300],
                      child: Icon(
                        Icons.person,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
            ),
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
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Goal: ${client.fitnessGoal} • ${client.availableDaysPerWeek} days/wk',
                    style: const TextStyle(
                      color: Colors.blueAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'BMI: ${client.bmi.toStringAsFixed(1)} • ${client.startingWeight}kg',
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Direct Action: Open AI Advisor for this specific Client
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: Colors.blueAccent),
            tooltip: 'Ask AI Advisor for ${client.name}',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    AiAdvisorScreen(initialClientId: client.id),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.show_chart, color: Colors.green),
            tooltip: 'View Progress',
            onPressed: () => _showClientProgressDialog(client, isDark),
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

  Widget _buildWideGroupCard(
    BuildContext context,
    GroupModel group,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: isDark
                ? const Color(0xFF312E81)
                : const Color(0xFFE0E7FF),
            child: const Icon(Icons.hub, color: Colors.indigoAccent),
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
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Manage Members, Schedule & Attendance',
                    style: TextStyle(
                      color: Colors.indigoAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
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
          Icon(Icons.fitness_center, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            sub,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
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
