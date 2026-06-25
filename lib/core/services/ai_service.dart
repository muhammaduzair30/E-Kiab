import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AiService {
  late final GenerativeModel _model;
  late final bool _isMock;

  AiService() {
    // Try to get from .env first, then fallback to --dart-define
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? const String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
    _isMock = apiKey.isEmpty;
    
    if (!_isMock) {
      _model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);
    }
  }

  Future<String> summarizeText(String text, {String? chapterTitle}) async {
    if (_isMock) {
      await Future.delayed(const Duration(seconds: 2));
      return "This is a mock summary of the chapter. In a real environment with a valid GEMINI_API_KEY, this would provide a concise and insightful summary of the text provided. The chapter covers the main topics comprehensively, providing examples and detailed explanations.";
    }

    try {
      final prompt = """
You are an expert educational AI tutor. Please summarize the following chapter text for a 9th-grade student.

CRITICAL INSTRUCTIONS:
- The text provided is raw text extracted from a PDF. Ignore any irrelevant headers, footers, page numbers, copyright notices, or table of contents.
- If the text provided contains an error message (like "Failed to extract...") or is extremely short/unavailable, DO NOT mention the error. Instead, generate a highly educational, generalized summary of the topic based entirely on what a 9th-grade student should learn regarding the chapter title: "${chapterTitle ?? 'Unknown Topic'}".
- Focus ONLY on summarizing the core educational concepts and topics presented.
- Structure your summary with markdown: use headers, bullet points, and bold text for key terms.
- Keep the summary concise but highly informative, easy for a 9th grader to digest.

Chapter Text:
$text
""";
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? "Failed to generate summary.";
    } catch (e) {
      return "Error generating summary: $e";
    }
  }

  Future<List<Map<String, dynamic>>> generateQuiz(String text, int numberOfQuestions, {String? chapterTitle}) async {
    if (_isMock) {
      await Future.delayed(const Duration(seconds: 2));
      return List.generate(numberOfQuestions, (index) => {
        "question": "This is a mock AI generated question ${index + 1}?",
        "options": ["Option A", "Option B", "Option C", "Option D"],
        "correctAnswerIndex": 0,
        "explanation": "This is a mock explanation for question ${index + 1}."
      });
    }

    try {
      final prompt = """
You are an expert educational AI tutor. Generate a high-quality multiple-choice quiz with $numberOfQuestions questions based on the following chapter text.

CRITICAL INSTRUCTIONS:
- The text provided is raw text extracted from a PDF. Ignore any irrelevant headers, footers, page numbers, or copyright notices.
- If the text provided contains an error message (like "Failed to extract...") or is extremely short, DO NOT mention the error. Instead, generate the quiz based entirely on what a 9th-grade student should learn regarding the chapter title: "${chapterTitle ?? 'Unknown Topic'}".
- Focus the questions strictly on the core educational concepts, definitions, and formulas found in the text.
- Ensure questions are appropriate for a 9th-grade comprehension level.
- Make the options plausible but with only one unambiguously correct answer.
- Respond ONLY with a valid JSON array of objects.

JSON Format Requirements:
Each object in the array must strictly have:
- "question" (string)
- "options" (array of exactly 4 strings)
- "correctAnswerIndex" (integer 0-3)
- "explanation" (string explaining why the answer is correct and why others are wrong)

Chapter Text:
$text
""";
      final apiKey = dotenv.env['GEMINI_API_KEY'] ?? const String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
      final jsonModel = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
        generationConfig: GenerationConfig(responseMimeType: 'application/json'),
      );
      final response = await jsonModel.generateContent([Content.text(prompt)]);
      final responseText = response.text ?? "[]";
      
      String jsonString = responseText.trim();
      
      // Extract JSON array from markdown response
      if (jsonString.contains('```json')) {
        jsonString = jsonString.split('```json')[1].split('```')[0].trim();
      } else if (jsonString.contains('```')) {
        jsonString = jsonString.split('```')[1].split('```')[0].trim();
      } else {
        // Fallback to finding the outermost array brackets
        final startIndex = jsonString.indexOf('[');
        final endIndex = jsonString.lastIndexOf(']');
        if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
          jsonString = jsonString.substring(startIndex, endIndex + 1);
        }
      }
      
      if (jsonString.isNotEmpty) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        return jsonList.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      // Error generating quiz: $e
      return [];
    }
  }

  Stream<String> streamChatResponse(String prompt, List<Content> history, {String? chapterContext}) async* {
    if (_isMock) {
      const mockResponse = "This is a simulated AI response. Please provide a GEMINI_API_KEY to enable real-time generative AI chatting.";
      for (int i = 0; i < mockResponse.length; i++) {
        await Future.delayed(const Duration(milliseconds: 30));
        yield mockResponse[i];
      }
      return;
    }

    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'] ?? const String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
      
      String systemPrompt = """
You are an expert, friendly Socratic AI Tutor.
Your goal is to guide the student to understand concepts by asking thought-provoking questions and providing clear, age-appropriate explanations.
Do NOT simply give away direct answers to homework or math problems. Instead, give hints and ask the student what they think the next step is.
Encourage the student and praise their efforts.
""";

      if (chapterContext != null && chapterContext.isNotEmpty) {
        systemPrompt += """\n
The user is currently studying the following chapter content. Use this as your primary source of truth to answer questions, test the student, and provide examples:
---
$chapterContext
---
""";
      }

      final chatModel = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
        systemInstruction: Content.system(systemPrompt),
      );

      final chat = chatModel.startChat(history: history);
      final responseStream = chat.sendMessageStream(Content.text(prompt));
      
      await for (final chunk in responseStream) {
        if (chunk.text != null) {
          yield chunk.text!;
        }
      }
    } catch (e) {
      yield "\n[Error: $e]";
    }
  }
}

final aiServiceProvider = Provider<AiService>((ref) {
  return AiService();
});
