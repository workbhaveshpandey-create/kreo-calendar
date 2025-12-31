import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> main() async {
  // 1. Get Key
  final envFile = File('.env');
  if (!envFile.existsSync()) {
    print('Error: .env file not found');
    return;
  }
  final lines = await envFile.readAsLines();
  String key = '';
  for (var line in lines) {
    if (line.startsWith('OPENROUTER_API_KEY=')) {
      key = line.split('=')[1].trim();
    }
  }

  if (key.isEmpty) {
    print('Error: API Key not found');
    return;
  }

  final client = http.Client();

  // Test OpenRouter
  print('Testing OpenRouter...');
  final sw1 = Stopwatch()..start();
  try {
    final response = await client.post(
      Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer $key',
        'Content-Type': 'application/json',
        'HTTP-Referer': 'https://kreo-calendar.app',
      },
      body: jsonEncode({
        'model': 'mistralai/mistral-7b-instruct:free',
        'messages': [
          {'role': 'user', 'content': 'Hello'},
        ],
      }),
    );
    sw1.stop();
    print('OpenRouter Status: ${response.statusCode}');
    print('OpenRouter Time: ${sw1.elapsedMilliseconds}ms');
  } catch (e) {
    print('OpenRouter Error: $e');
  }

  // Test Pollinations
  print('Testing Pollinations...');
  final sw2 = Stopwatch()..start();
  try {
    final response = await client.post(
      Uri.parse('https://text.pollinations.ai/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'messages': [
          {'role': 'user', 'content': 'Hello'},
        ],
        'model': 'openai',
        'jsonMode': true,
      }),
    );
    sw2.stop();
    print('Pollinations Status: ${response.statusCode}');
    print('Pollinations Time: ${sw2.elapsedMilliseconds}ms');
  } catch (e) {
    print('Pollinations Error: $e');
  }

  client.close();
}
