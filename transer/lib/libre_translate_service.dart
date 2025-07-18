import 'dart:convert';
import 'package:http/http.dart' as http;

Future<String> translateWithLibre(String text, String fromLang, String toLang) async {
  final url = Uri.parse("http://localhost:5000/translate");
  try {
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'q': text,
        'source': fromLang,
        'target': toLang,
        'format': 'text',
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['translatedText'];
    } else {
      return "LibreTranslate error: ${response.statusCode}";
    }
  } catch (e) {
    return "Translation failed: $e";
  }
}
