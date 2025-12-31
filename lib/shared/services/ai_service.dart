import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/app_config.dart';

/// OpenRouter AI Service
/// Provides AI capabilities for smart calendar features
class AIService {
  static const String _baseUrl = 'https://openrouter.ai/api/v1';
  static const String _model = AppConfig.aiModel;

  final String apiKey;
  final http.Client _client;

  AIService({required this.apiKey, http.Client? client})
    : _client = client ?? http.Client();

  /// Send a chat message to the AI and get a response
  Future<String> chat({
    required List<Map<String, String>> messages,
    String? model,
    double temperature = 0.7,
  }) async {
    print(
      'DEBUG: Sending request to OpenRouter with model: ${model ?? _model}',
    );
    final response = await _client
        .post(
          Uri.parse('$_baseUrl/chat/completions'),
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
            'HTTP-Referer': 'https://kreo-calendar.app',
            'X-Title': 'Kreo Calendar',
          },
          body: jsonEncode({
            'model': model ?? _model,
            'messages': messages,
            'temperature': temperature,
          }),
        )
        .timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw AIException(
              'Request timed out. Please check your internet connection.',
            );
          },
        );

    print('DEBUG: OpenRouter ID: ${response.statusCode}');
    print('DEBUG: OpenRouter Body: ${response.body}');

    if (response.statusCode != 200) {
      throw AIException('Failed to get AI response: ${response.body}');
    }

    final data = jsonDecode(response.body);
    return data['choices'][0]['message']['content'] ?? '';
  }

  /// Parse natural language into a structured event
  Future<ParsedEvent?> parseEventFromText(String text) async {
    final now = DateTime.now();
    final systemPrompt =
        '''You are a smart calendar assistant. Your ONLY job is to extract event details from natural language and return them as a strict JSON object.

Current Reference Time: ${now.toIso8601String()}

Input: "$text"

Instructions:
1. Identify the Title, Date, Start Time, and Duration.
2. If language is Hindi/Hinglish, translate intent to English.
3. Calculate Start Time and End Time based on the Reference Time.
4. Default Duration is 1 hour if not specified.
5. If "for X hours" or "X minutes" is mentioned, calculate End Time accordingly.
6. OUTPUT MUST BE RAW JSON ONLY. NO MARKDOWN. NO EXPLANATION.

JSON Schema:
{
  "title": "string (capitalized)",
  "date": "YYYY-MM-DD",
  "startTime": "HH:MM",
  "endTime": "HH:MM",
  "isAllDay": boolean,
  "location": "string or null",
  "description": "string or null"
}

Examples:
- "Meeting tomorrow at 3pm for 2 hours" -> {"title":"Meeting","date":"${_getDate(now.add(const Duration(days: 1)))}","startTime":"15:00","endTime":"17:00","isAllDay":false,"location":null,"description":null}
- "Aaj shaam 5 baje cricket" -> {"title":"Cricket","date":"${_getDate(now)}","startTime":"17:00","endTime":"18:00","isAllDay":false,"location":null,"description":null}
''';

    try {
      print('DEBUG: parseEventFromText called with: $text');

      // Gemma 3 4B on OpenRouter/Google AI Studio does not support 'system' role
      // So we merge the system prompt into the user message
      final combinedPrompt = '$systemPrompt\n\nUser Input: "$text"';

      final response = await chat(
        messages: [
          {'role': 'user', 'content': combinedPrompt},
        ],
        temperature: 0.1,
      );
      print('DEBUG: Raw AI response: $response');

      final jsonStr = _extractJson(response);
      print('DEBUG: Extracted JSON string: "$jsonStr"');

      if (jsonStr.isEmpty) {
        print('DEBUG: Extracted JSON is empty!');
        return null;
      }

      final data = jsonDecode(jsonStr);
      print('DEBUG: Decoded JSON data: $data');
      return ParsedEvent.fromJson(data);
    } catch (e, stackTrace) {
      print('Error parsing event: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  String _extractJson(String text) {
    // Find the first '{' and last '}'
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');

    if (start != -1 && end != -1 && end > start) {
      return text.substring(start, end + 1);
    }
    return '';
  }

  String _getDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Ask the AI assistant a question about the calendar
  Future<String> askAssistant(
    String question,
    List<Map<String, dynamic>> recentEvents,
  ) async {
    final eventsJson = jsonEncode(recentEvents);
    final response = await chat(
      messages: [
        {
          'role': 'system',
          'content':
              '''You are Kreo, a helpful calendar assistant. You help users manage their schedule and answer questions about their events. Be concise, friendly, and helpful.

User's recent events: $eventsJson''',
        },
        {'role': 'user', 'content': question},
      ],
      temperature: 0.7,
    );

    return response;
  }

  void dispose() {
    _client.close();
  }
}

/// Parsed event from natural language
class ParsedEvent {
  final String title;
  final DateTime date;
  final DateTime? startTime;
  final DateTime? endTime;
  final bool isAllDay;
  final String? location;
  final String? description;

  ParsedEvent({
    required this.title,
    required this.date,
    this.startTime,
    this.endTime,
    required this.isAllDay,
    this.location,
    this.description,
  });

  factory ParsedEvent.fromJson(Map<String, dynamic> json) {
    final dateParts = (json['date'] as String).split('-');
    final date = DateTime(
      int.parse(dateParts[0]),
      int.parse(dateParts[1]),
      int.parse(dateParts[2]),
    );

    DateTime? startTime;
    DateTime? endTime;

    if (json['startTime'] != null) {
      final timeParts = (json['startTime'] as String).split(':');
      startTime = DateTime(
        date.year,
        date.month,
        date.day,
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );
    }

    if (json['endTime'] != null) {
      final timeParts = (json['endTime'] as String).split(':');
      endTime = DateTime(
        date.year,
        date.month,
        date.day,
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );
    }

    return ParsedEvent(
      title: json['title'] ?? 'New Event',
      date: date,
      startTime: startTime,
      endTime: endTime,
      isAllDay: json['isAllDay'] ?? false,
      location: json['location'],
      description: json['description'],
    );
  }
}

/// AI Exception
class AIException implements Exception {
  final String message;
  AIException(this.message);

  @override
  String toString() => 'AIException: $message';
}
