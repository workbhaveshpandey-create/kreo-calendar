import 'dart:convert';
import 'package:http/http.dart' as http;

/// OpenRouter AI Service
/// Provides AI capabilities for smart calendar features
class AIService {
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
    // Directly use Pollinations for fastest response (OpenRouter is rate limited)
    return await _chatWithPollinations(messages);
  }

  /// Fallback chat using Pollinations AI
  Future<String> _chatWithPollinations(
    List<Map<String, String>> messages,
  ) async {
    try {
      // Construct a single prompt from messages for Pollinations
      String fullPrompt = messages
          .map((m) => "${m['role']}: ${m['content']}")
          .join('\n');
      // Append system instruction if needed, though usually included in messages

      print('DEBUG: Sending request to Pollinations AI...');
      final response = await _client
          .post(
            Uri.parse('https://text.pollinations.ai/'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'messages':
                  messages, // Pollinations supports OpenAI format now too, or just text
              'model':
                  'openai', // Optional, pollinations uses openai-compatible or other models
              'jsonMode': true, // Hint for JSON
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        // Pollinations text API usually returns the text directly
        return response.body;
      } else {
        // Try simple GET if POST fails
        final encodedPrompt = Uri.encodeComponent(fullPrompt);
        final getResponse = await _client.get(
          Uri.parse('https://text.pollinations.ai/$encodedPrompt'),
        );
        if (getResponse.statusCode == 200) {
          return getResponse.body;
        }
      }
      throw AIException('Both OpenRouter and Pollinations failed.');
    } catch (e) {
      throw AIException('AI Service failed: $e');
    }
  }

  /// Parse natural language into a structured event
  Future<ParsedEvent?> parseEventFromText(String text) async {
    final now = DateTime.now();
    final systemPrompt =
        '''You are a smart calendar assistant. Your ONLY job is to extract event details from natural language and return them as a strict JSON object.

Current Reference Time: ${now.toIso8601String()} (Year: ${now.year})

Input: "$text"

Instructions:
1. Identify the Title, Date, Start Time, and Duration.
2. If language is Hindi/Hinglish, translate intent to English.
3. Calculate Start Time and End Time based on the Reference Time.
4. Default Duration is 1 hour if not specified.
5. If "for X hours" or "X minutes" is mentioned, calculate End Time accordingly.
6. OUTPUT MUST BE RAW JSON ONLY. NO MARKDOWN. NO EXPLANATION.

CRITICAL DATE LOGIC:
7. Check the Current Reference Time closely.
8. If the user mentions a date (e.g., "January 5th") that has already passed in the current year (${now.year}), you MUST schedule it for the NEXT year (${now.year + 1}).
   - Example: If Reference is Dec 31, 2025 and input is "Meeting Jan 2nd", Date MUST be 2026-01-02.
   - Example: If Reference is May 2025 and input is "Meeting in April", Date MUST be 2026-04-xx.
9. If the user specifies a year explicitly (e.g., "Jan 5 2025"), respect it.

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
- "Meeting tomorrow at 3pm" (Assume Ref: 2025-12-31) -> {"title":"Meeting","date":"2026-01-01","startTime":"15:00","endTime":"16:00","isAllDay":false,"location":null,"description":null}
- "Aaj shaam 5 baje cricket" -> {"title":"Cricket","date":"${_getDate(now)}","startTime":"17:00","endTime":"18:00","isAllDay":false,"location":null,"description":null}
''';

    try {
      print('DEBUG: parseEventFromText called with: $text');

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
