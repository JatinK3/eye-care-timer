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
          'max_tokens': 100,
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
}
