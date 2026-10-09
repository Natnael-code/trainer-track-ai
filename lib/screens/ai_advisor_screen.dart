import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/client_model.dart';
import '../models/fitness_models.dart';
import '../providers/client_provider.dart';
import '../services/database_service.dart';
import '../services/gemini_service.dart';

class AiAdvisorScreen extends StatefulWidget {
  final String? initialClientId;

  const AiAdvisorScreen({super.key, this.initialClientId});

  @override
  State<AiAdvisorScreen> createState() => _AiAdvisorScreenState();
}

class _AiAdvisorScreenState extends State<AiAdvisorScreen> {
  ClientModel? _selectedClient;
  List<AiChatMessageModel> _chatMessages = [];
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isGenerating = false;
  bool _isLoadingHistory = false;

  final List<String> _quickPrompts = [
    '🏋️ Generate Weekly Workout Split',
    '🥗 Calculate Daily Macro Targets',
    '🩹 Injury Modifications & Safe Warmups',
    '📉 Weight Loss Acceleration Strategy',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSelectedClient();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeSelectedClient() {
    final provider = Provider.of<ClientProvider>(context, listen: false);
    if (provider.clients.isNotEmpty) {
      ClientModel client = provider.clients.first;
      if (widget.initialClientId != null) {
        final match = provider.clients.firstWhere(
          (c) => c.id == widget.initialClientId,
          orElse: () => provider.clients.first,
        );
        client = match;
      }
      setState(() => _selectedClient = client);
      _loadChatHistoryForClient(client.id);
    }
  }

  Future<void> _loadChatHistoryForClient(String clientId) async {
    setState(() => _isLoadingHistory = true);
    final history = await DatabaseService.instance.fetchAiChatMessagesForClient(
      clientId,
    );
    if (mounted) {
      setState(() {
        _chatMessages = history;
        _isLoadingHistory = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    final query = text.trim();
    if (query.isEmpty || _selectedClient == null || _isGenerating) return;

    _messageController.clear();

    final userMsg = AiChatMessageModel(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      clientId: _selectedClient!.id,
      sender: 'user',
      text: query,
      timestamp: DateTime.now(),
    );

    setState(() {
      _chatMessages.add(userMsg);
      _isGenerating = true;
    });
    _scrollToBottom();

    await DatabaseService.instance.insertAiChatMessage(userMsg);

    final aiResponseText = await GeminiService.generateAdvisorResponse(
      client: _selectedClient!,
      history: _chatMessages,
      userPrompt: query,
    );

    final aiMsg = AiChatMessageModel(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}_ai',
      clientId: _selectedClient!.id,
      sender: 'ai',
      text: aiResponseText,
      timestamp: DateTime.now(),
    );

    await DatabaseService.instance.insertAiChatMessage(aiMsg);

    if (mounted) {
      setState(() {
        _chatMessages.add(aiMsg);
        _isGenerating = false;
      });
      _scrollToBottom();
    }
  }

  Future<void> _applyPlanToClientSchedule(
    BuildContext context,
    String messageText,
  ) async {
    if (_selectedClient == null) return;

    final DateTime startDate = DateTime.now();
    final int daysInMonth = DateTime(
      startDate.year,
      startDate.month + 1,
      0,
    ).day;

    final List<ScheduleDayModel> deploymentDays = [];
    final List<WorkoutPlanModel> deploymentPlans = [];

    List<String> lines = messageText.split('\n');
    String routineTitle = '${_selectedClient!.fitnessGoal} Split';
    List<String> exercisesList = [];

    for (var line in lines) {
      if (line.toUpperCase().contains('ROUTINE:')) {
        routineTitle = line.replaceAll('ROUTINE:', '').trim();
      } else if (line.trim().startsWith('-') ||
          line.trim().startsWith('*') ||
          RegExp(r'^\d+\.').hasMatch(line.trim())) {
        exercisesList.add(line.trim());
      }
    }

    String exercisesText = exercisesList.isNotEmpty
        ? exercisesList.join('\n')
        : messageText;

    for (int dayNum = 1; dayNum <= daysInMonth; dayNum++) {
      final DateTime runningDate = startDate.add(Duration(days: dayNum - 1));
      final String dayId =
          '${_selectedClient!.id}_day_${dayNum}_${startDate.millisecondsSinceEpoch}';

      bool isWork = dayNum % 2 != 0;

      final dayNode = ScheduleDayModel(
        id: dayId,
        clientId: _selectedClient!.id,
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
          routineName: routineTitle,
          exercisesJson: exercisesText,
        );
        deploymentPlans.add(planNode);
      }
    }

    await DatabaseService.instance.saveMonthlySchedule(
      days: deploymentDays,
      plans: deploymentPlans,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Applied AI Workout Plan directly to ${_selectedClient!.name}\'s calendar schedule!',
          ),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
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

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.auto_awesome, color: Color(0xFF3B82F6)),
            const SizedBox(width: 8),
            Text(
              'AI Workout & Diet Advisor',
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: bgColor,
        iconTheme: IconThemeData(color: textColor),
        actions: [
          if (_selectedClient != null)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined, color: Colors.grey),
              tooltip: 'Clear Chat Memory',
              onPressed: () async {
                await DatabaseService.instance.clearAiChatHistoryForClient(
                  _selectedClient!.id,
                );
                _loadChatHistoryForClient(_selectedClient!.id);
              },
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              color: Colors.amber.withAlpha(35),
              child: Row(
                children: const [
                  Icon(Icons.health_and_safety, color: Colors.amber, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'AI Assistant advice — review and adjust for safety before assigning to client.',
                      style: TextStyle(
                        color: Colors.amber,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: cardBg,
              child: Row(
                children: [
                  Text(
                    'Client:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<ClientModel>(
                        value: _selectedClient,
                        dropdownColor: cardBg,
                        isExpanded: true,
                        items: clientProvider.clients.map((client) {
                          return DropdownMenuItem<ClientModel>(
                            value: client,
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.person_pin,
                                  size: 18,
                                  color: Color(0xFF3B82F6),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${client.name} (${client.fitnessGoal})',
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (ClientModel? newClient) {
                          if (newClient != null) {
                            setState(() => _selectedClient = newClient);
                            _loadChatHistoryForClient(newClient.id);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: _quickPrompts.map((prompt) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ActionChip(
                      backgroundColor: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFE2E8F0),
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      label: Text(
                        prompt,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onPressed: () => _sendMessage(prompt),
                    ),
                  );
                }).toList(),
              ),
            ),

            const Divider(height: 1),

            Expanded(
              child: _isLoadingHistory
                  ? const Center(child: CircularProgressIndicator())
                  : _chatMessages.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.psychology,
                              size: 56,
                              color: Color(0xFF3B82F6),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Ask TrainerTrack AI for recommendations for ${_selectedClient?.name ?? "your client"}.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: subTextColor,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(12),
                      itemCount: _chatMessages.length,
                      itemBuilder: (context, idx) {
                        final msg = _chatMessages[idx];
                        final isUser = msg.sender == 'user';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: isUser
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(14),
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.82,
                                ),
                                decoration: BoxDecoration(
                                  color: isUser
                                      ? const Color(0xFF2563EB)
                                      : isDark
                                      ? const Color(0xFF1E293B)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: isUser
                                      ? null
                                      : Border.all(
                                          color: isDark
                                              ? Colors.white10
                                              : const Color(0xFFE2E8F0),
                                        ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isUser ? 'Coach' : 'TrainerTrack AI',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: isUser
                                            ? Colors.white70
                                            : const Color(0xFF3B82F6),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    SelectableText(
                                      msg.text,
                                      style: TextStyle(
                                        color: isUser
                                            ? Colors.white
                                            : textColor,
                                        fontSize: 13,
                                        height: 1.4,
                                      ),
                                    ),
                                    if (!isUser &&
                                        (msg.text.toLowerCase().contains(
                                              'workout',
                                            ) ||
                                            msg.text.toLowerCase().contains(
                                              'split',
                                            ) ||
                                            msg.text.toLowerCase().contains(
                                              'routine',
                                            ))) ...[
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFF10B981,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 8,
                                            ),
                                          ),
                                          icon: const Icon(
                                            Icons.calendar_month,
                                            size: 14,
                                            color: Colors.white,
                                          ),
                                          label: const Text(
                                            'Apply Plan to Client Schedule',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          onPressed: () =>
                                              _applyPlanToClientSchedule(
                                                context,
                                                msg.text,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                DateFormat('hh:mm a').format(msg.timestamp),
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),

            if (_isGenerating)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Gemini AI is analyzing client data...',
                      style: TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
              ),

            Container(
              padding: const EdgeInsets.all(10),
              color: cardBg,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText:
                            'Ask AI about ${_selectedClient?.name ?? "client"}...',
                        hintStyle: TextStyle(color: subTextColor, fontSize: 13),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: _sendMessage,
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: const Color(0xFF2563EB),
                    child: IconButton(
                      icon: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 18,
                      ),
                      onPressed: () => _sendMessage(_messageController.text),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
