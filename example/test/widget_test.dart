import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ailia_voice_example/main.dart';

void main() {
  testWidgets('App renders with dropdown and run button', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.byType(DropdownButton<int>), findsOneWidget);
    expect(find.text('Run'), findsOneWidget);
    expect(find.text('Model Type:'), findsOneWidget);
  });

  testWidgets('Dropdown contains all model types', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.byType(DropdownButton<int>));
    await tester.pumpAndSettle();

    expect(find.text('Tacotron2', skipOffstage: false), findsWidgets);
    expect(find.text('GPT-SoVITS V1 (JA)', skipOffstage: false), findsWidgets);
    expect(find.text('GPT-SoVITS V1 (EN)', skipOffstage: false), findsWidgets);
    expect(find.text('GPT-SoVITS V1 (ZH)', skipOffstage: false), findsWidgets);
    expect(find.text('GPT-SoVITS V2 (JA)', skipOffstage: false), findsWidgets);
    expect(find.text('GPT-SoVITS V2 (EN)', skipOffstage: false), findsWidgets);
    expect(find.text('GPT-SoVITS V2 (ZH)', skipOffstage: false), findsWidgets);
    expect(find.text('GPT-SoVITS V3 (JA)', skipOffstage: false), findsWidgets);
    expect(find.text('GPT-SoVITS V3 (EN)', skipOffstage: false), findsWidgets);
    expect(find.text('GPT-SoVITS V3 (ZH)', skipOffstage: false), findsWidgets);
    expect(find.text('GPT-SoVITS V2Pro (JA)', skipOffstage: false), findsWidgets);
    expect(find.text('GPT-SoVITS V2Pro (EN)', skipOffstage: false), findsWidgets);
    expect(find.text('GPT-SoVITS V2Pro (ZH)', skipOffstage: false), findsWidgets);
  });
}
