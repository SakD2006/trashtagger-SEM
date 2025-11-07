import 'dart:io';
import 'dart:convert'; // Required for jsonEncode and base64Encode
import 'package:http/http.dart' as http; // Required for API calls

class VisionLlmService {
  final String _apiKey = '';

  final String _groqApiUrl = "https://api.groq.com/openai/v1/chat/completions";
  final String _visionModel = "meta-llama/llama-4-scout-17b-16e-instruct";

  Future<String?> analyzeInitialImage(File imageFile) async {
    try {
      // 1. Read and Base64-encode the image
      final imageBytes = await imageFile.readAsBytes();
      final String base64Image = base64Encode(imageBytes);
      final String dataUrl = "data:image/jpeg;base64,$base64Image";

      // 2. Create the exact same prompt for the AI
      final prompt =
          "Analyze the content of this image strictly. Your task is to identify "
          "if there is a significant amount of publicly dumped trash, garbage, or waste. "
          "If yes, provide a concise, one-sentence description of the scene. "
          "If no significant trash is visible, you MUST respond with the single word: 'REJECT'.";

      // 3. Set up the Groq API request body
      final body = jsonEncode({
        "model": _visionModel,
        "messages": [
          {
            "role": "user",
            "content": [
              {"type": "text", "text": prompt},
              {
                "type": "image_url",
                "image_url": {"url": dataUrl},
              },
            ],
          },
        ],
        "max_tokens": 100, // 100 tokens is enough for a short description
      });

      // 4. Send the request
      final response = await http.post(
        Uri.parse(_groqApiUrl),
        headers: {
          "Authorization": "Bearer $_apiKey",
          "Content-Type": "application/json",
        },
        body: body,
      );

      // 5. Process the response
      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        final String? responseText =
            responseBody['choices'][0]['message']['content']?.trim();

        if (responseText == null || responseText.isEmpty) {
          return "AI could not process the image."; // Handle empty response
        }

        if (responseText.toUpperCase() == 'REJECT') {
          print("AI rejected the image: No significant trash found.");
          return null; // This is how we reject the report
        }

        return responseText; // Return the valid description
      } else {
        // Handle API error
        print("Groq API Error: ${response.statusCode} ${response.body}");
        return "Error: API returned ${response.statusCode}";
      }
    } catch (e) {
      print("Error calling Groq API: $e");
      return "Error: Could not analyze the image. Details: $e";
    }
  }

  /// Compares the "before" and "after" images and provides a rating.
  Future<String?> compareImagesAndRate(
    File beforeImage,
    File afterImage,
  ) async {
    try {
      // 1. Encode both images
      final beforeBytes = await beforeImage.readAsBytes();
      final String base64Before = base64Encode(beforeBytes);
      final String dataUrlBefore = "data:image/jpeg;base64,$base64Before";

      final afterBytes = await afterImage.readAsBytes();
      final String base64After = base64Encode(afterBytes);
      final String dataUrlAfter = "data:image/jpeg;base64,$base64After";

      // 2. Create the comparison prompt
      final prompt =
          "Compare the first image (before) and the second image (after). "
          "Has the trash from the first image been cleaned up in the second? "
          "Provide a rating out of 10 and a brief summary of the work done.";

      // 3. Set up the body to send BOTH images
      final body = jsonEncode({
        "model": _visionModel,
        "messages": [
          {
            "role": "user",
            "content": [
              {"type": "text", "text": prompt},
              // Send 'before' image first
              {
                "type": "image_url",
                "image_url": {"url": dataUrlBefore},
              },
              // Send 'after' image second
              {
                "type": "image_url",
                "image_url": {"url": dataUrlAfter},
              },
            ],
          },
        ],
        "max_tokens": 150, // More tokens for a summary + rating
      });

      // 4. Send the request
      final response = await http.post(
        Uri.parse(_groqApiUrl),
        headers: {
          "Authorization": "Bearer $_apiKey",
          "Content-Type": "application/json",
        },
        body: body,
      );

      // 5. Process the response
      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        final String? responseText =
            responseBody['choices'][0]['message']['content']?.trim();

        return responseText; // This will be the rating and summary
      } else {
        print("Groq API Error: ${response.statusCode} ${response.body}");
        return "Error: API returned ${response.statusCode}";
      }
    } catch (e) {
      print("Error calling Groq API: $e");
      return "Error: Could not analyze the images. Details: $e";
    }
  }
}
