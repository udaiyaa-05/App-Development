import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:provider/provider.dart';
import 'libre_translate_service.dart';
import 'main.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  File? _image;
  String _extractedText = '';
  String _translatedText = '';
  bool _isLoading = false;
  String _targetLanguage = 'ta';
  bool _textMode = false;
  final TextEditingController _textController = TextEditingController();

  final Map<String, String> languages = {
    'English': 'en',
    'Tamil': 'ta',
    'Hindi': 'hi',
    'French': 'fr',
    'Spanish': 'es',
    'Telugu': 'te',
    'Malayalam': 'ml',
    'Kannada': 'kn'
  };

  Future<void> _pickImage(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source);
    if (picked != null) {
      setState(() {
        _image = File(picked.path);
        _extractedText = '';
        _translatedText = '';
      });
      _performOCR(_image!);
    }
  }

  Future<void> _performOCR(File image) async {
    setState(() => _isLoading = true);
    final inputImage = InputImage.fromFile(image);
    final textRecognizer = GoogleMlKit.vision.textRecognizer();
    final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

    await textRecognizer.close();
    setState(() {
      _extractedText = recognizedText.text;
    });

    final translated = await translateWithLibre(_extractedText, 'auto', _targetLanguage);
    setState(() {
      _translatedText = translated;
      _isLoading = false;
    });
  }

  Future<void> _translateTypedText() async {
    if (_textController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    final translated = await translateWithLibre(_textController.text.trim(), 'auto', _targetLanguage);
    setState(() {
      _translatedText = translated;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan & Translate"),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'Light') themeProvider.setTheme(ThemeMode.light);
              if (value == 'Dark') themeProvider.setTheme(ThemeMode.dark);
              if (value == 'System') themeProvider.setTheme(ThemeMode.system);
            },
            icon: const Icon(Icons.settings),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'Light', child: Text('Light Theme')),
              PopupMenuItem(value: 'Dark', child: Text('Dark Theme')),
              PopupMenuItem(value: 'System', child: Text('System Default')),
            ],
          ),
          IconButton(
            icon: Icon(_textMode ? Icons.camera_alt : Icons.keyboard),
            onPressed: () => setState(() => _textMode = !_textMode),
          )
        ],
      ),
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: ListView(
                  children: [
                    DropdownButton<String>(
                      value: _targetLanguage,
                      isExpanded: true,
                      onChanged: (val) => setState(() => _targetLanguage = val!),
                      items: languages.entries.map((entry) {
                        return DropdownMenuItem<String>(
                          value: entry.value,
                          child: Text('To: ${entry.key}'),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),
                    if (_textMode) ...[
                      TextField(
                        controller: _textController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Enter text here',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).cardColor,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: _translateTypedText,
                        icon: const Icon(Icons.translate),
                        label: const Text("Translate"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ] else ...[
                      ElevatedButton.icon(
                        onPressed: () => _pickImage(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt),
                        label: const Text("Scan with Camera"),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: () => _pickImage(ImageSource.gallery),
                        icon: const Icon(Icons.image),
                        label: const Text("Select from Gallery"),
                      ),
                      const SizedBox(height: 16),
                      if (_image != null) Image.file(_image!, height: 150),
                      const SizedBox(height: 16),
                      if (_extractedText.isNotEmpty)
                        Text("📝 Extracted Text:\n$_extractedText"),
                      const SizedBox(height: 16),
                    ],
                    if (_translatedText.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "🌍 Translated Text:\n$_translatedText",
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}
