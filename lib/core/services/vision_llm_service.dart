import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';

class VisionLlmService {
  final String _apiKey = 'AIzaSyCjRBj7KnVUJ6AgICRgx4bMb3DVnMeDuPQ';
  Future<String?> analyzeInitialImage(File imageFile) async {
    // 1. Initialize the Gemini Pro Vision model
    final model = GenerativeModel(model: 'gemini-pro-vision', apiKey: _apiKey);

    try {
      // 2. Read the image file as bytes
      final imageBytes = await imageFile.readAsBytes();

      // 3. Create the prompt for the AI. This is the most important part!
      // We instruct it to be a gatekeeper.
      final prompt = TextPart(
        "Analyze the content of this image strictly. Your task is to identify "
        "if there is a significant amount of publicly dumped trash, garbage, or waste. "
        "If yes, provide a concise, one-sentence description of the scene. "
        "If no significant trash is visible, you MUST respond with the single word: 'REJECT'.",
      );

      // 4. Create the image part of the request
      final imagePart = DataPart('image/jpeg', imageBytes);

      // 5. Send the request to the model
      final response = await model.generateContent([
        Content.multi([prompt, imagePart]),
      ]);

      // 6. Process the response
      final String? responseText = response.text?.trim();

      if (responseText == null || responseText.isEmpty) {
        return "AI could not process the image."; // Handle empty response
      }

      if (responseText.toUpperCase() == 'REJECT') {
        print("AI rejected the image: No significant trash found.");
        return null; // This is how we reject the report
      }

      return responseText; // Return the valid description
    } catch (e) {
      print("Error calling Gemini API: $e");
      return "Error: Could not analyze the image.";
    }
  }

  // --- You will build this function later for the NGO side ---
  /// Compares the "before" and "after" images and provides a rating.
  Future<String?> compareImagesAndRate(
    File beforeImage,
    File afterImage,
  ) async {
    // The logic here will be similar, but the prompt will be different.
    // The prompt would ask the AI to compare the two images and rate the cleanup.
    // Example Prompt: "Compare the first image (before) and the second image (after).
    // Has the trash from the first image been cleaned up in the second?
    // Provide a rating out of 10 and a brief summary of the work done."

    return "Work rated 9/10: The area has been cleared successfully.";
  }
}
