import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:ailia/ailia_license.dart';

import 'package:ailia_voice_example/text_to_speech.dart';
import 'package:ailia_voice_example/utils/download_model.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final tts = TextToSpeech();

  setUpAll(() async {
    await AiliaLicense.checkAndDownloadLicense();
  });

  Future<void> testModelType(WidgetTester tester, int modelType, String name) async {
    // Download
    await tts.downloadModels(modelType);

    // Inference
    String outputPath = await getModelPath("test_$name.wav");
    await tts.run(modelType, outputPath, playAudio: false);
  }

  testWidgets('Tacotron2', (WidgetTester tester) async {
    await testModelType(tester, TextToSpeech.MODEL_TYPE_TACOTRON2, "tacotron2");
  });

  testWidgets('GPT-SoVITS V1 JA', (WidgetTester tester) async {
    await testModelType(tester, TextToSpeech.MODEL_TYPE_GPT_SOVITS_JA, "v1_ja");
  });

  testWidgets('GPT-SoVITS V1 EN', (WidgetTester tester) async {
    await testModelType(tester, TextToSpeech.MODEL_TYPE_GPT_SOVITS_EN, "v1_en");
  });

  testWidgets('GPT-SoVITS V1 ZH', (WidgetTester tester) async {
    await testModelType(tester, TextToSpeech.MODEL_TYPE_GPT_SOVITS_ZH, "v1_zh");
  });

  testWidgets('GPT-SoVITS V2 JA', (WidgetTester tester) async {
    await testModelType(tester, TextToSpeech.MODEL_TYPE_GPT_SOVITS_V2_JA, "v2_ja");
  });

  testWidgets('GPT-SoVITS V2 EN', (WidgetTester tester) async {
    await testModelType(tester, TextToSpeech.MODEL_TYPE_GPT_SOVITS_V2_EN, "v2_en");
  });

  testWidgets('GPT-SoVITS V2 ZH', (WidgetTester tester) async {
    await testModelType(tester, TextToSpeech.MODEL_TYPE_GPT_SOVITS_V2_ZH, "v2_zh");
  });

  testWidgets('GPT-SoVITS V3 JA', (WidgetTester tester) async {
    await testModelType(tester, TextToSpeech.MODEL_TYPE_GPT_SOVITS_V3_JA, "v3_ja");
  });

  testWidgets('GPT-SoVITS V3 EN', (WidgetTester tester) async {
    await testModelType(tester, TextToSpeech.MODEL_TYPE_GPT_SOVITS_V3_EN, "v3_en");
  });

  testWidgets('GPT-SoVITS V3 ZH', (WidgetTester tester) async {
    await testModelType(tester, TextToSpeech.MODEL_TYPE_GPT_SOVITS_V3_ZH, "v3_zh");
  });

  testWidgets('GPT-SoVITS V2Pro JA', (WidgetTester tester) async {
    await testModelType(tester, TextToSpeech.MODEL_TYPE_GPT_SOVITS_V2_PRO_JA, "v2pro_ja");
  });

  testWidgets('GPT-SoVITS V2Pro EN', (WidgetTester tester) async {
    await testModelType(tester, TextToSpeech.MODEL_TYPE_GPT_SOVITS_V2_PRO_EN, "v2pro_en");
  });

  testWidgets('GPT-SoVITS V2Pro ZH', (WidgetTester tester) async {
    await testModelType(tester, TextToSpeech.MODEL_TYPE_GPT_SOVITS_V2_PRO_ZH, "v2pro_zh");
  });
}
