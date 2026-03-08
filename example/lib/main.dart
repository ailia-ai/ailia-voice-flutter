import 'package:flutter/material.dart';

import 'package:ailia/ailia_license.dart';

import 'utils/download_model.dart';
import 'text_to_speech.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _statusText = '';
  final _textToSpeech = TextToSpeech();
  final bool _userDictionary = true;
  bool _isRunning = false;

  int _selectedModelType = TextToSpeech.MODEL_TYPE_GPT_SOVITS_JA;

  static const Map<int, String> _modelTypeNames = {
    TextToSpeech.MODEL_TYPE_TACOTRON2: "Tacotron2",
    TextToSpeech.MODEL_TYPE_GPT_SOVITS_JA: "GPT-SoVITS V1 (JA)",
    TextToSpeech.MODEL_TYPE_GPT_SOVITS_EN: "GPT-SoVITS V1 (EN)",
    TextToSpeech.MODEL_TYPE_GPT_SOVITS_ZH: "GPT-SoVITS V1 (ZH)",
    TextToSpeech.MODEL_TYPE_GPT_SOVITS_V2_JA: "GPT-SoVITS V2 (JA)",
    TextToSpeech.MODEL_TYPE_GPT_SOVITS_V2_EN: "GPT-SoVITS V2 (EN)",
    TextToSpeech.MODEL_TYPE_GPT_SOVITS_V2_ZH: "GPT-SoVITS V2 (ZH)",
    TextToSpeech.MODEL_TYPE_GPT_SOVITS_V3_JA: "GPT-SoVITS V3 (JA)",
    TextToSpeech.MODEL_TYPE_GPT_SOVITS_V3_EN: "GPT-SoVITS V3 (EN)",
    TextToSpeech.MODEL_TYPE_GPT_SOVITS_V3_ZH: "GPT-SoVITS V3 (ZH)",
    TextToSpeech.MODEL_TYPE_GPT_SOVITS_V2_PRO_JA: "GPT-SoVITS V2Pro (JA)",
    TextToSpeech.MODEL_TYPE_GPT_SOVITS_V2_PRO_EN: "GPT-SoVITS V2Pro (EN)",
    TextToSpeech.MODEL_TYPE_GPT_SOVITS_V2_PRO_ZH: "GPT-SoVITS V2Pro (ZH)",
  };

  void _onRun() async {
    if (_isRunning) return;
    setState(() {
      _isRunning = true;
      _statusText = 'Model Downloading...';
    });

    try {
      await AiliaLicense.checkAndDownloadLicense();

      await _textToSpeech.downloadModels(_selectedModelType, userDictionary: _userDictionary);

      setState(() {
        _statusText = 'Running inference...';
      });

      String outputPath = await getModelPath("temp.wav");
      await _textToSpeech.run(_selectedModelType, outputPath, userDictionary: _userDictionary);

      setState(() {
        _statusText = "finish";
        _isRunning = false;
      });
    } catch (e) {
      setState(() {
        _statusText = "Error: $e";
        _isRunning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('ailia Voice Sample'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Model Type:', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              DropdownButton<int>(
                value: _selectedModelType,
                isExpanded: true,
                onChanged: _isRunning ? null : (int? value) {
                  if (value != null) {
                    setState(() {
                      _selectedModelType = value;
                    });
                  }
                },
                items: _modelTypeNames.entries.map((entry) {
                  return DropdownMenuItem<int>(
                    value: entry.key,
                    child: Text(entry.value),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isRunning ? null : _onRun,
                child: const Text('Run'),
              ),
              const SizedBox(height: 16),
              Text(_statusText, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}
