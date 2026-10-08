import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/client_model.dart';
import '../models/fitness_models.dart';

class GeminiService {
  // Read key dynamically from .env
  static String get _groqApiKey => dotenv.env['GROQ_API_KEY'] ?? '';

  static Future<String> generateAdvisorResponse({
    required ClientModel client,
    required List<AiChatMessageModel> history,
    required String userPrompt,
  }) async {
    if (_groqApiKey.isEmpty) {
      return '⚠️ Please set your valid Groq API key in `.env`.';
    }

    final preferredModels = [
      'llama-3.3-70b-versatile',
      'llama-3.1-8b-instant',
      'llama3-70b-8192',
      'llama3-8b-8192',
      'gemma2-9b-it',
    ];

    String selectedModel = preferredModels.first;

    try {
      final modelsUri = Uri.parse('https://api.groq.com/openai/v1/models');
      final modelsResponse = await http.get(
        modelsUri,
        headers: {'Authorization': 'Bearer $_groqApiKey'},
      );

      if (modelsResponse.statusCode == 200) {
        final modelsData = jsonDecode(modelsResponse.body);
        final List modelsList = modelsData['data'] ?? [];
        final List<String> availableIds = modelsList
            .map((m) => m['id'].toString())
            .toList();

        bool foundPreferred = false;
        for (String pref in preferredModels) {
          if (availableIds.contains(pref)) {
            selectedModel = pref;
            foundPreferred = true;
            break;
          }
        }

        if (!foundPreferred) {
          final validChatModels = availableIds.where((id) {
            final lower = id.toLowerCase();
            final isExcluded =
                lower.contains('guard') ||
                lower.contains('whisper') ||
                lower.contains('embed') ||
                lower.contains('vision') ||
                lower.contains('canopylabs') ||
                lower.contains('orpheus') ||
                lower.contains('audio') ||
                lower.contains('tts');

            return !isExcluded &&
                (lower.contains('llama') ||
                    lower.contains('gemma') ||
                    lower.contains('gpt') ||
                    lower.contains('qwen'));
          }).toList();

          if (validChatModels.isNotEmpty) {
            selectedModel = validChatModels.first;
          }
        }
      }
    } catch (e) {
      debugPrint('Model lookup warning: $e');
    }

    debugPrint('Selected Groq Chat Model: $selectedModel');

    final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');

    final systemPrompt =
        '''
You are TrainerTrack AI, an elite strength & conditioning coach advising personal trainers for client ${client.name}.
Goal: ${client.fitnessGoal}, Age:${client.age}, Weight: ${client.startingWeight}kg, Injuries:${client.injuries}.
Whenever you suggest a workout routine split, format the routine title with "ROUTINE:" and the exercise list with numbered bullets.
''';

    final messages = [
      {'role': 'system', 'content': systemPrompt},
      ...history.map(
        (msg) => {
          'role': msg.sender == 'user' ? 'user' : 'assistant',
          'content': msg.text,
        },
      ),
      {'role': 'user', 'content': userPrompt},
    ];

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $_groqApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': selectedModel,
          'messages': messages,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        return 'Groq Error [${response.statusCode}] ($selectedModel):\n${response.body}';
      }
    } catch (e) {
      return 'Connection Error: $e';
    }
  }
}
