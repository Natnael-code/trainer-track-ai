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

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Theme & Settings State
  bool _isDarkMode = true;
  String _contactEmail = 'coach@example.com';
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _emailController = TextEditingController(text: _contactEmail);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // Dynamic Theme Colors
  Color get _bgColor =>
      _isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
  Color get _cardBgColor =>
      _isDarkMode ? const Color(0xFF1E293B) : Colors.white;
  Color get _borderColor =>
      _isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
  Color get _textPrimary =>
      _isDarkMode ? Colors.white : const Color(0xFF0F172A);
  Color get _textSecondary =>
      _isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
  Color get _accentColor => const Color(0xFF3B82F6);
  Color get _inputBgColor =>
      _isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);

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
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _cardBgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.photo_library, color: _accentColor),
              title: Text(
                'Choose from Gallery',
                style: TextStyle(color: _textPrimary),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery, photoPathCtrl, setModalState);
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt, color: _accentColor),
              title: Text(
                'Take Photo using Camera',
                style: TextStyle(color: _textPrimary),
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

  // Settings & Theme Toggle Modal
  void _showSettingsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _cardBgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              top: 20,
              left: 20,
              right: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _accentColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.tune,
                            color: _accentColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Preferences & Contact',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _textPrimary,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: _textSecondary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Theme Switcher Section
                Text(
                  'APPEARANCE MODE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: _textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: _inputBgColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _borderColor),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _isDarkMode = false);
                            setModalState(() {});
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: !_isDarkMode
                                  ? _accentColor
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.light_mode,
                                  size: 18,
                                  color: !_isDarkMode
                                      ? Colors.white
                                      : _textSecondary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Bright Mode',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: !_isDarkMode
                                        ? Colors.white
                                        : _textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _isDarkMode = true);
                            setModalState(() {});
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _isDarkMode
                                  ? _accentColor
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.dark_mode,
                                  size: 18,
                                  color: _isDarkMode
                                      ? Colors.white
                                      : _textSecondary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Dark Mode',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: _isDarkMode
                                        ? Colors.white
                                        : _textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Contact Email Input
                Text(
                  'COACH CONTACT EMAIL',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: _textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _emailController,
                  style: TextStyle(color: _textPrimary),
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.email_outlined, color: _accentColor),
                    hintText: 'Enter contact email address',
                    hintStyle: TextStyle(
                      color: _textSecondary.withOpacity(0.6),
                    ),
                    filled: true,
                    fillColor: _inputBgColor,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _accentColor, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accentColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.save, size: 18, color: Colors.white),
                    label: const Text(
                      'Save Contact Email',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _contactEmail = _emailController.text.trim();
                      });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Contact email updated to: $_contactEmail',
                          ),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 44),
                    side: BorderSide(color: _borderColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Icon(Icons.shield, color: _accentColor, size: 18),
                  label: Text(
                    'Backup Database Now',
                    style: TextStyle(color: _textPrimary, fontSize: 13),
                  ),
                  onPressed: () {
                    Provider.of<ClientProvider>(
                      context,
                      listen: false,
                    ).backupData();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Database backup exported successfully!'),
                        backgroundColor: Colors.blueAccent,
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddClientDialog() {
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _cardBgColor,
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
                        icon: Icon(Icons.arrow_back, color: _textPrimary),
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
                          color: _textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameCtrl,
                    style: TextStyle(color: _textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      labelStyle: TextStyle(color: _textSecondary),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneCtrl,
                    style: TextStyle(color: _textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      labelStyle: TextStyle(color: _textSecondary),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: ageCtrl,
                          style: TextStyle(color: _textPrimary),
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Age',
                            labelStyle: TextStyle(color: _textSecondary),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: weightCtrl,
                          style: TextStyle(color: _textPrimary),
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setModalState(() {}),
                          decoration: InputDecoration(
                            labelText: 'Weight (kg)',
                            labelStyle: TextStyle(color: _textSecondary),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: heightCtrl,
                          style: TextStyle(color: _textPrimary),
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setModalState(() {}),
                          decoration: InputDecoration(
                            labelText: 'Height (cm)',
                            labelStyle: TextStyle(color: _textSecondary),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Calculated BMI: ${previewBmi.toStringAsFixed(1)}',
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: photoPathCtrl,
                    readOnly: true,
                    style: TextStyle(color: _textPrimary),
                    onTap: () => _showImagePickerOptions(
                      context,
                      photoPathCtrl,
                      setModalState,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Profile Photo',
                      labelStyle: TextStyle(color: _textSecondary),
                      hintText: photoPathCtrl.text.isEmpty
                          ? 'Tap camera icon to add photo'
                          : photoPathCtrl.text,
                      hintStyle: TextStyle(color: _textSecondary),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.camera_alt, color: _accentColor),
                        onPressed: () => _showImagePickerOptions(
                          context,
                          photoPathCtrl,
                          setModalState,
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
                                  color: Colors.grey[800],
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
                            style: TextStyle(
                              color: _textSecondary,
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
                    dropdownColor: _cardBgColor,
                    decoration: InputDecoration(
                      labelText: 'Fitness Goal',
                      labelStyle: TextStyle(color: _textSecondary),
                      border: const OutlineInputBorder(),
                    ),
                    items: ['Lose Weight', 'Gain Weight', 'Maintain Weight']
                        .map(
                          (g) => DropdownMenuItem(
                            value: g,
                            child: Text(
                              g,
                              style: TextStyle(color: _textPrimary),
                            ),
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
                          dropdownColor: _cardBgColor,
                          decoration: InputDecoration(
                            labelText: 'Days Available/Wk',
                            labelStyle: TextStyle(color: _textSecondary),
                            border: const OutlineInputBorder(),
                          ),
                          items: List.generate(7, (i) => i + 1)
                              .map(
                                (d) => DropdownMenuItem(
                                  value: d,
                                  child: Text(
                                    '$d Days',
                                    style: TextStyle(color: _textPrimary),
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
                          dropdownColor: _cardBgColor,
                          decoration: InputDecoration(
                            labelText: 'Sessions/Day',
                            labelStyle: TextStyle(color: _textSecondary),
                            border: const OutlineInputBorder(),
                          ),
                          items: [1, 2, 3]
                              .map(
                                (s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(
                                    '$s Time(s)',
                                    style: TextStyle(color: _textPrimary),
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
                    dropdownColor: _cardBgColor,
                    decoration: InputDecoration(
                      labelText: 'Experience Level',
                      labelStyle: TextStyle(color: _textSecondary),
                      border: const OutlineInputBorder(),
                    ),
                    items: ['Beginner', 'Intermediate', 'Advanced']
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(
                              e,
                              style: TextStyle(color: _textPrimary),
                            ),
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
                        backgroundColor: _accentColor,
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

  // First Verification Modal - Step 1
  void _confirmDeleteClient(BuildContext context, ClientModel client) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _cardBgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Client',
          style: TextStyle(color: _textPrimary, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'You selected ${client.name} for deletion. Click Delete to proceed with confirmation.',
          style: TextStyle(color: _textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel', style: TextStyle(color: _textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(dialogContext); // Close first prompt
              _showSecondDeleteVerification(
                context,
                client,
              ); // Step 2 verification
            },
            child: const Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Second Verification Modal - Step 2
  void _showSecondDeleteVerification(BuildContext context, ClientModel client) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _cardBgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.redAccent,
              size: 24,
            ),
            SizedBox(width: 8),
            Text(
              'Confirm Permanent Delete',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure this will permanently delete the client ${client.name}? All associated progress history will be removed.',
          style: TextStyle(color: _textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel', style: TextStyle(color: _textSecondary)),
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
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${client.name} was permanently deleted.'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            child: const Text(
              'Yes, Delete Permanently',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showClientProgressDialog(ClientModel client) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _cardBgColor,
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
                            color: _textPrimary,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.add_a_photo, color: _accentColor),
                          onPressed: () => _showAddProgressLogDialog(
                            client,
                            onAdded: () => setModalState(() {}),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tap any progress step below to view photo and full details:',
                      style: TextStyle(color: _textSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: progressList.isEmpty
                          ? Center(
                              child: Text(
                                'No progress logs recorded yet.',
                                style: TextStyle(color: _textSecondary),
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
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: _inputBgColor,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isFirstStep
                                            ? _accentColor.withOpacity(0.5)
                                            : _borderColor,
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
                                                  color: Colors.grey[800],
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Icon(
                                                  isFirstStep
                                                      ? Icons.app_registration
                                                      : Icons.show_chart,
                                                  color: isFirstStep
                                                      ? _accentColor
                                                      : Colors.greenAccent,
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
                                                      ? _accentColor
                                                      : _textPrimary,
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
                                                  color: _textSecondary,
                                                  fontSize: 11,
                                                ),
                                              ),
                                              Text(
                                                'Weight: ${p.weight}kg • Height: ${p.height}cm • BMI: ${p.bmi.toStringAsFixed(1)}',
                                                style: TextStyle(
                                                  color: _textSecondary,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Icon(
                                          Icons.chevron_right,
                                          color: _textSecondary,
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
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _cardBgColor,
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
                  color: _textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.close, color: _textSecondary),
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
                    color: _inputBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image_not_supported,
                        size: 38,
                        color: _textSecondary,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'No progress photo attached to this step',
                        style: TextStyle(color: _textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 14),
              Text(
                DateFormat('EEEE, MMMM d, yyyy').format(progress.date),
                style: TextStyle(
                  color: _accentColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _inputBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Weight:',
                          style: TextStyle(color: _textSecondary),
                        ),
                        Text(
                          '${progress.weight} kg',
                          style: TextStyle(
                            color: _textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Divider(color: _borderColor),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Height:',
                          style: TextStyle(color: _textSecondary),
                        ),
                        Text(
                          '${progress.height} cm',
                          style: TextStyle(
                            color: _textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Divider(color: _borderColor),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('BMI:', style: TextStyle(color: _textSecondary)),
                        Text(
                          progress.bmi.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.greenAccent,
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
                Text(
                  'Notes:',
                  style: TextStyle(
                    color: _textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  progress.notes!,
                  style: TextStyle(color: _textPrimary, fontSize: 13),
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
  }) {
    final weightCtrl = TextEditingController(
      text: client.startingWeight.toString(),
    );
    final heightCtrl = TextEditingController(text: client.height.toString());
    final photoCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _cardBgColor,
        title: Text(
          'Add Progress Entry',
          style: TextStyle(color: _textPrimary),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: weightCtrl,
                style: TextStyle(color: _textPrimary),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Current Weight (kg)',
                  labelStyle: TextStyle(color: _textSecondary),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: heightCtrl,
                style: TextStyle(color: _textPrimary),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Current Height (cm)',
                  labelStyle: TextStyle(color: _textSecondary),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: photoCtrl,
                style: TextStyle(color: _textPrimary),
                decoration: InputDecoration(
                  labelText: 'Progress Photo File Path',
                  labelStyle: TextStyle(color: _textSecondary),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
                style: TextStyle(color: _textPrimary),
                decoration: InputDecoration(
                  labelText: 'Notes',
                  labelStyle: TextStyle(color: _textSecondary),
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: _textSecondary)),
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

  void _showAddGroupDialog() {
    final groupNameCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: _cardBgColor,
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
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: groupNameCtrl,
              style: TextStyle(color: _textPrimary),
              decoration: InputDecoration(
                labelText: 'Group Workspace Name',
                labelStyle: TextStyle(color: _textSecondary),
                border: const OutlineInputBorder(),
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

    final personalClients = clientProvider.clients
        .where((c) => c.groupId == null || c.groupId!.isEmpty)
        .toList();

    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
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
                          color: _textPrimary,
                        ),
                      ),
                      Text(
                        formattedDate,
                        style: TextStyle(fontSize: 14, color: _textSecondary),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => _showSettingsModal(context),
                    child: Tooltip(
                      message: 'Settings & Contact Email',
                      child: CircleAvatar(
                        backgroundColor: _cardBgColor,
                        child: Icon(
                          _isDarkMode ? Icons.dark_mode : Icons.light_mode,
                          color: _accentColor,
                        ),
                      ),
                    ),
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
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Active Groups',
                      value: '${clientProvider.totalActiveGroups}',
                      icon: Icons.hub,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                height: 50,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: _cardBgColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _borderColor),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: _accentColor,
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: _textSecondary,
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
            _showAddClientDialog();
          } else {
            _showAddGroupDialog();
          }
        },
        backgroundColor: _accentColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: _cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
        boxShadow: !_isDarkMode
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
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
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 12, color: _textSecondary)),
        ],
      ),
    );
  }

  Widget _buildWideItemCard(BuildContext context, ClientModel client) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
        boxShadow: !_isDarkMode
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _confirmDeleteClient(context, client),
            child: Tooltip(
              message: 'Tap avatar to delete client',
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
                      backgroundColor: Colors.grey[800],
                      child: const Icon(Icons.person, color: Colors.white70),
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
                      color: _textPrimary,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Goal: ${client.fitnessGoal} • ${client.availableDaysPerWeek} days/wk',
                    style: TextStyle(
                      color: _accentColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'BMI: ${client.bmi.toStringAsFixed(1)} • ${client.startingWeight}kg',
                    style: TextStyle(color: _textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.show_chart, color: Colors.greenAccent),
            tooltip: 'View Progress',
            onPressed: () => _showClientProgressDialog(client),
          ),
          IconButton(
            icon: Icon(Icons.calendar_month, color: _accentColor),
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

  Widget _buildWideGroupCard(BuildContext context, GroupModel group) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
        boxShadow: !_isDarkMode
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 26,
            backgroundColor: Color(0xFF312E81),
            child: Icon(Icons.hub, color: Colors.indigoAccent),
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
                      color: _textPrimary,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
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
          Icon(Icons.fitness_center, size: 48, color: _textSecondary),
          const SizedBox(height: 12),
          Text(
            sub,
            textAlign: TextAlign.center,
            style: TextStyle(color: _textSecondary, fontSize: 14),
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
