import 'dart:convert';
import 'package:http/http.dart' as http;

class AiService {
  AiService._privateConstructor();
  static final AiService instance = AiService._privateConstructor();

  static const List<String> defaultGeminiModels = [
    'gemini-1.5-flash',
    'gemini-1.5-pro',
    'gemini-2.0-flash-exp',
  ];

  static const List<String> defaultOpenAiModels = [
    'gpt-4o-mini',
    'gpt-4o',
    'gpt-3.5-turbo',
  ];

  static const List<String> defaultGroqModels = [
    'llama-3.1-8b-instant',
    'llama-3.1-70b-versatile',
    'llama3-8b-8192',
    'llama3-70b-8192',
    'mixtral-8x7b-32768',
  ];

  List<String> getDefaultModels(String provider) {
    switch (provider.toLowerCase()) {
      case 'openai':
        return defaultOpenAiModels;
      case 'groq':
        return defaultGroqModels;
      case 'gemini':
      default:
        return defaultGeminiModels;
    }
  }

  Future<List<String>> fetchModels({
    required String provider,
    required String apiKey,
  }) async {
    if (apiKey.isEmpty) {
      throw ArgumentError('API Key cannot be empty');
    }

    final p = provider.toLowerCase();
    if (p == 'gemini') {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to fetch Gemini models: Status ${response.statusCode}\n${response.body}',
        );
      }

      final data = jsonDecode(response.body);
      final modelsList = data['models'] as List<dynamic>?;
      if (modelsList == null) return [];

      return modelsList
          .map((m) {
            final name = m['name'] as String? ?? '';
            // Strip models/ prefix if present
            if (name.startsWith('models/')) {
              return name.substring(7);
            }
            return name;
          })
          .where((name) => name.isNotEmpty && (name.contains('gemini') || name.contains('learn')))
          .toList();
    } else if (p == 'openai' || p == 'groq') {
      final baseUrl = p == 'openai'
          ? 'https://api.openai.com/v1/models'
          : 'https://api.groq.com/openai/v1/models';

      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {
          'Authorization': 'Bearer $apiKey',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to fetch $provider models: Status ${response.statusCode}\n${response.body}',
        );
      }

      final data = jsonDecode(response.body);
      final dataList = data['data'] as List<dynamic>?;
      if (dataList == null) return [];

      return dataList
          .map((m) => m['id'] as String? ?? '')
          .where((id) => id.isNotEmpty)
          .toList();
    }

    return [];
  }

  Future<String> generateMotivation({
    required String provider,
    required String apiKey,
    required String model,
    required String prompt,
    double temperature = 0.3,
    int maxTokens = 150,
  }) async {
    if (apiKey.isEmpty) {
      throw ArgumentError('API Key cannot be empty');
    }

    final p = provider.toLowerCase();
    if (p == 'gemini') {
      // Use v1beta generateContent endpoint
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
      );

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': temperature,
          }
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception(
          'Gemini API error: Status ${response.statusCode}\n${response.body}',
        );
      }

      final data = jsonDecode(response.body);
      final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
      if (text == null || text.trim().isEmpty) {
        throw Exception('Received empty content from Gemini');
      }

      return text.trim();
    } else if (p == 'openai' || p == 'groq') {
      final url = p == 'openai'
          ? 'https://api.openai.com/v1/chat/completions'
          : 'https://api.groq.com/openai/v1/chat/completions';

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': model,
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'temperature': temperature,
          'max_tokens': maxTokens,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception(
          '$provider API error: Status ${response.statusCode}\n${response.body}',
        );
      }

      final data = jsonDecode(response.body);
      final text = data['choices']?[0]?['message']?['content'] as String?;
      if (text == null || text.trim().isEmpty) {
        throw Exception('Received empty content from $provider');
      }

      return text.trim();
    }

    throw UnsupportedError('Unsupported AI Provider: $provider');
  }

  /// Generates a single blink-conscious reminder using low temperature.
  Future<String> generateBlinkReminder({
    required String provider,
    required String apiKey,
    required String model,
  }) async {
    const prompt =
        'You are a wellness assistant for developers. Generate exactly ONE short, '
        'warm, direct reminder for a developer to blink consciously right now. '
        'Max 12 words. Vary between: eye moisture, dry eye prevention, conscious '
        'blinking, or relaxing eye muscles. No emojis. No markdown. '
        'Output only the reminder sentence.';
    return generateMotivation(
      provider: provider,
      apiKey: apiKey,
      model: model,
      prompt: prompt,
      temperature: 0.15,
    );
  }

  Future<String> generateWellnessCoachAdvice({
    required String provider,
    required String apiKey,
    required String model,
    required String query,
  }) async {
    final prompt = 'You are an expert ergonomic and wellness coach for desk workers. '
        'The user says: "$query". '
        'Provide a very brief (max 3 short steps) stretching or wellness routine they can do '
        'right now at their desk. Keep it encouraging and direct. '
        'Do not use markdown. Output only the routine.';
    return generateMotivation(
      provider: provider,
      apiKey: apiKey,
      model: model,
      prompt: prompt,
      temperature: 0.3,
      maxTokens: 250,
    );
  }

  Future<Map<String, dynamic>> generateSmartSchedule({
    required String provider,
    required String apiKey,
    required String model,
    required String historySummary,
    required int currentWorkMinutes,
    required int currentBreakMinutes,
    String? userTaskContext,
  }) async {
    String contextStr = '';
    if (userTaskContext != null && userTaskContext.trim().isNotEmpty) {
      contextStr = 'The user is currently working on: "$userTaskContext". Break this task into optimal Pomodoro chunks.\n';
    }

    final prompt = 'You are a wellness assistant for developers. Based on the user\'s recent timer history summary: $historySummary\n'
        'Their current schedule is ${currentWorkMinutes}m work / ${currentBreakMinutes}m break.\n'
        '$contextStr'
        'Suggest an optimal work and break duration to improve focus and reduce fatigue (e.g. 45/5 or 20/1 or 50/10). '
        'Output MUST be valid JSON with exactly three keys: "work_minutes" (integer), "break_minutes" (integer), and "reasoning" (string, max 50 words explaining why and how it fits their task). '
        'Do NOT include markdown formatting, backticks, or any other text. Output only the raw JSON object.';
    final result = await generateMotivation(
      provider: provider,
      apiKey: apiKey,
      model: model,
      prompt: prompt,
      temperature: 0.2,
    );
    try {
      String cleanJson = result;
      final RegExp jsonRegExp = RegExp(r'\{[\s\S]*\}');
      final match = jsonRegExp.firstMatch(result);
      if (match != null) {
        cleanJson = match.group(0)!;
      }
      final data = jsonDecode(cleanJson);
      return {
        'work_minutes': data['work_minutes'] as int? ?? currentWorkMinutes,
        'break_minutes': data['break_minutes'] as int? ?? currentBreakMinutes,
        'reasoning': data['reasoning'] as String? ?? 'Based on your recent history.',
      };
    } catch (e) {
      throw Exception('Failed to parse AI schedule JSON: $e');
    }
  }

  Future<String> generateEndOfDaySummary({
    required String provider,
    required String apiKey,
    required String model,
    required String todayHistorySummary,
  }) async {
    const prompt =
        'You are a wellness and productivity assistant. The user is finishing their workday. '
        'Review their timer history for today and provide a short, insightful, and warmly encouraging '
        'summary of their performance. Praise good habits (taking breaks, hydration) and gently suggest improvements '
        'if they skipped or postponed too many breaks. Keep it under 50 words, conversational, and uplifting. '
        'Do NOT use markdown. Output only the message.\n\n';

    return generateMotivation(
      provider: provider,
      apiKey: apiKey,
      model: model,
      prompt: prompt + todayHistorySummary,
      temperature: 0.3,
    );
  }
}
