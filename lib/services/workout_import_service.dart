import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/workout_set.dart';

/// Service for importing workouts from URLs or text using LLM conversion
class WorkoutImportService {
  static const String _apiKeyStorageKey = 'gemini_api_key';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  /// Check if an API key is stored
  static Future<bool> hasApiKey() async {
    final key = await _storage.read(key: _apiKeyStorageKey);
    return key != null && key.isNotEmpty;
  }

  /// Get the stored API key
  static Future<String?> getApiKey() async {
    return await _storage.read(key: _apiKeyStorageKey);
  }

  /// Save an API key
  static Future<void> saveApiKey(String apiKey) async {
    await _storage.write(key: _apiKeyStorageKey, value: apiKey);
  }

  /// Delete the stored API key
  static Future<void> deleteApiKey() async {
    await _storage.delete(key: _apiKeyStorageKey);
  }

  /// Check if on-device AI is available (Android 14+ with Gemini Nano)
  static Future<bool> isOnDeviceAvailable() async {
    // TODO: Implement actual on-device model availability check
    // For now, return false - we'll implement this in phase 2
    return false;
  }

  /// Import a workout from URL or text
  ///
  /// Strategy:
  /// 1. Try on-device LLM first (if available)
  /// 2. Fall back to API with user's key
  /// 3. Throw error if neither available
  static Future<Map<String, dynamic>> importWorkout({
    String? url,
    String? text,
  }) async {
    if (url == null && text == null) {
      throw ArgumentError('Either url or text must be provided');
    }

    // Get workout text (fetch from URL if needed)
    String workoutText;
    if (url != null) {
      workoutText = await _fetchWorkoutFromUrl(url);
    } else {
      workoutText = text!;
    }

    // Try on-device first
    if (await isOnDeviceAvailable()) {
      print('Using on-device LLM for workout import');
      return await _convertWithOnDeviceLLM(workoutText);
    }

    // Fall back to API
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception(
        'No API key configured. Please add your Gemini API key in settings.',
      );
    }

    print('Using Gemini API for workout import');
    return await _convertWithGeminiAPI(workoutText, apiKey);
  }

  /// Fetch workout content from a URL
  static Future<String> _fetchWorkoutFromUrl(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch URL: ${response.statusCode}');
      }

      // Parse HTML and extract main content
      final document = html_parser.parse(response.body);

      // Try to find the main workout content
      // This is a simple heuristic - may need refinement for specific sites
      final mainContent =
          document.querySelector('article') ??
          document.querySelector('main') ??
          document.querySelector('.post-content') ??
          document.querySelector('.entry-content') ??
          document.body;

      if (mainContent == null) {
        throw Exception('Could not find workout content in page');
      }

      // Extract text, preserving some structure
      return mainContent.text;
    } catch (e) {
      throw Exception('Failed to fetch workout from URL: $e');
    }
  }

  /// Convert workout text using Gemini API
  static Future<Map<String, dynamic>> _convertWithGeminiAPI(
    String workoutText,
    String apiKey,
  ) async {
    final prompt = _buildConversionPrompt(workoutText);

    try {
      // First, list all available models
      print('Querying available models...');
      final listUrl = Uri.parse(
        'https://generativelanguage.googleapis.com/v1/models?key=$apiKey',
      );

      final listResponse = await http.get(listUrl);
      print('ListModels status: ${listResponse.statusCode}');
      print('ListModels response: ${listResponse.body}');

      // Parse the response to find a suitable model
      String modelToUse = 'gemini-1.5-flash'; // default

      if (listResponse.statusCode == 200) {
        final modelsJson =
            jsonDecode(listResponse.body) as Map<String, dynamic>;
        final models = modelsJson['models'] as List?;

        if (models != null && models.isNotEmpty) {
          print('Found ${models.length} available models');

          // Look for the best available model for generateContent
          for (final model in models) {
            final modelName = model['name'] as String;
            final supportedMethods =
                model['supportedGenerationMethods'] as List?;

            print('Model: $modelName, Methods: $supportedMethods');

            if (supportedMethods != null &&
                supportedMethods.contains('generateContent')) {
              // Extract just the model name (remove "models/" prefix if present)
              modelToUse = modelName.replaceFirst('models/', '');
              print('Selected model: $modelToUse');
              break;
            }
          }
        }
      }

      // Use the discovered model
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1/models/$modelToUse:generateContent?key=$apiKey',
      );

      final requestBody = {
        'contents': [
          {
            'parts': [
              {'text': prompt},
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0.1,
          'maxOutputTokens':
              8192, // Increased from 2048 to handle larger workouts
        },
      };

      print(
        'Making API request to: ${url.toString().replaceAll(apiKey, 'REDACTED')}',
      );

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      print('API response status: ${response.statusCode}');

      if (response.statusCode != 200) {
        print('API response body: ${response.body}');
        throw Exception(
          'API request failed (${response.statusCode}): ${response.body}',
        );
      }

      final responseJson = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = responseJson['candidates'] as List?;

      if (candidates == null || candidates.isEmpty) {
        throw Exception('No response from API: ${response.body}');
      }

      final content = candidates[0]['content'] as Map<String, dynamic>;
      final parts = content['parts'] as List;
      final responseText = parts[0]['text'] as String;

      if (responseText.isEmpty) {
        throw Exception('Empty response from LLM');
      }

      print('LLM response received: ${responseText.length} characters');

      // Extract JSON from response (LLM might wrap it in markdown code blocks)
      final jsonString = _extractJson(responseText);
      final workout = jsonDecode(jsonString) as Map<String, dynamic>;

      // Validate the workout structure
      _validateWorkout(workout);

      print('Workout successfully converted: ${workout['name']}');
      return workout;
    } catch (e) {
      print('Error in _convertWithGeminiAPI: $e');
      throw Exception('Failed to convert workout: $e');
    }
  }

  /// Convert workout text using on-device LLM (Gemini Nano)
  static Future<Map<String, dynamic>> _convertWithOnDeviceLLM(
    String workoutText,
  ) async {
    // TODO: Implement on-device LLM conversion using Gemini Nano
    // This will be implemented in phase 2
    throw UnimplementedError('On-device LLM not yet implemented');
  }

  /// Build the LLM prompt for workout conversion
  static String _buildConversionPrompt(String workoutText) {
    return '''
You are a workout parser. Convert the following workout description into a structured JSON format.

WORKOUT TEXT:
$workoutText

OUTPUT FORMAT:
Generate a JSON object with this structure:

{
  "name": "Workout name",
  "description": "Brief description",
  "sets": [
    // Array of sets - each set can be either:
    // 1. A LEAF SET (exercise):
    {
      "name": "Exercise name",
      "description": "Instructions",
      "type": "reps" or "time",
      "value": number (reps count or seconds),
      "transitionTime": seconds (default 5),
      "duration": seconds (optional - for rep exercises with time cap)
    }
    // 2. A CONTAINER SET (group of exercises):
    {
      "name": "Section name",
      "description": "Section description",
      "rounds": number (default 1),
      "restBetweenRounds": seconds (default 0),
      "sets": [ /* nested leaf or container sets */ ]
    }
  ]
}

RULES:
1. Leaf sets MUST have "type" ("reps" or "time") and usually have "value"
2. Container sets MUST have "sets" array and MUST NOT have "type"
3. For AMRAP (as many rounds as possible), set rounds to a high number (e.g., 999)
4. For timed workouts (e.g., "20 minutes"), the container should have type "time" with value in seconds
5. Common exercises: Push-ups, Pull-ups, Squats, Burpees, Sit-ups, etc.
6. Transition time is rest between exercises (default 5 seconds)
7. Rest between rounds is rest between rounds of the same set
8. If workout mentions warm-up, main workout, and cool-down, structure them as separate container sets
9. For rep-based exercises with time caps (e.g., "50 burpees for time"), use type "reps" with "duration" field
10. Convert all times to seconds (e.g., "2 minutes" → 120)

IMPORTANT:
- Return ONLY valid JSON, no extra text
- Preserve exercise names as written
- Be conservative with transition times (5s default is good)
- If unclear, default to "reps" type

Example for "Cindy: 20 min AMRAP of 5 pull-ups, 10 push-ups, 15 squats":
{
  "name": "Cindy - CrossFit Benchmark WOD",
  "description": "20 minute AMRAP",
  "sets": [
    {
      "name": "Cindy - AMRAP 20",
      "description": "As many rounds as possible in 20 minutes",
      "rounds": 999,
      "restBetweenRounds": 0,
      "sets": [
        {"name": "Pull-ups", "type": "reps", "value": 5, "transitionTime": 3},
        {"name": "Push-ups", "type": "reps", "value": 10, "transitionTime": 3},
        {"name": "Air Squats", "type": "reps", "value": 15, "transitionTime": 3}
      ]
    }
  ]
}

Now convert the workout above:
''';
  }

  /// Extract JSON from LLM response (handles markdown code blocks)
  static String _extractJson(String text) {
    print('Attempting to extract JSON from response (length: ${text.length})');
    print('Full response text:');
    print(text);
    print('---END OF RESPONSE---');

    // Try multiple regex patterns for markdown code blocks
    // Pattern 1: Standard markdown with newlines
    var codeBlockRegex = RegExp(r'```[^\n]*\n([\s\S]*?)\n```', multiLine: true);
    var match = codeBlockRegex.firstMatch(text);

    if (match != null) {
      final extracted = match.group(1)!.trim();
      print('Extracted from code block (pattern 1)');
      return extracted;
    }

    // Pattern 2: No trailing newline before closing ```
    codeBlockRegex = RegExp(r'```[^\n]*\n([\s\S]*?)```', multiLine: true);
    match = codeBlockRegex.firstMatch(text);

    if (match != null) {
      final extracted = match.group(1)!.trim();
      print('Extracted from code block (pattern 2)');
      return extracted;
    }

    // Pattern 3: More lenient - just look for ``` ... ```
    codeBlockRegex = RegExp(r'```(?:json)?\s*([\s\S]*?)```', multiLine: true);
    match = codeBlockRegex.firstMatch(text);

    if (match != null) {
      final extracted = match.group(1)!.trim();
      print('Extracted from code block (pattern 3)');
      return extracted;
    }

    // If no code block, try to find JSON object
    final jsonRegex = RegExp(r'\{[\s\S]*\}');
    final jsonMatch = jsonRegex.firstMatch(text);

    if (jsonMatch != null) {
      final extracted = jsonMatch.group(0)!.trim();
      print('Extracted JSON object directly');
      return extracted;
    }

    // Return as-is and let JSON decoder handle it
    print('No extraction needed, returning as-is');
    return text.trim();
  }

  /// Validate that the workout JSON has the correct structure
  static void _validateWorkout(Map<String, dynamic> workout) {
    if (!workout.containsKey('name')) {
      throw Exception('Workout must have a name');
    }

    if (!workout.containsKey('sets') || workout['sets'] is! List) {
      throw Exception('Workout must have a sets array');
    }

    // Basic validation - try to construct WorkoutSet objects
    final sets = workout['sets'] as List;
    for (final set in sets) {
      if (set is! Map<String, dynamic>) {
        throw Exception('Each set must be a JSON object');
      }

      // This will throw if the structure is invalid
      WorkoutSet.fromJson(set);
    }
  }

  /// Estimate the cost of an API-based import
  /// Returns cost in USD
  static double estimateImportCost(String workoutText) {
    // Rough estimate based on Gemini Flash pricing
    // Input: ~$0.000075 per 1K characters
    // Output: ~$0.00030 per 1K characters

    final inputChars = _buildConversionPrompt(workoutText).length;
    final estimatedOutputChars = 1000; // Typical workout JSON size

    final inputCost = (inputChars / 1000) * 0.000075;
    final outputCost = (estimatedOutputChars / 1000) * 0.00030;

    return inputCost + outputCost;
  }
}
