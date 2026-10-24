import 'package:example/examples/anime_vn_navigator/domain/models/vn_character_models.dart';
import 'package:example/examples/anime_vn_navigator/domain/models/vn_sdk_chapter.dart';
import 'package:example/examples/anime_vn_navigator/ui/anime_vn_navigator_screen.dart';
import 'package:example/examples/anime_vn_navigator/ui/view_models/anime_vn_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:example/main.dart';

void main() {
  testWidgets('home screen shows demo entries including Anime Visual Novel', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Gemini Live API Examples'), findsOneWidget);
    expect(
      find.text('🌸 Tokimeki☆Gemini Live (Anime Visual Novel Voice Navigator)'),
      findsOneWidget,
    );
    expect(find.text('✨ Live Vision Agent'), findsOneWidget);
    expect(find.text('Chat Interface'), findsOneWidget);
    expect(find.text('Live API Features'), findsOneWidget);
    expect(find.text('Function Calling'), findsOneWidget);
  });

  test(
    'AnimeVnViewModel updates dialogue beats, choice overlay, and affection on interactions',
    () {
      final vm = AnimeVnViewModel();
      addTearDown(vm.dispose);

      expect(vm.currentEmotion, VnCharacterEmotion.happy);
      expect(vm.affectionPoints, 70);
      expect(vm.currentChapterIndex, 0);
      expect(vm.currentBeatIndex, 0);
      expect(vm.isChoiceOverlayOpen, isFalse);

      // Advancing dialogue steps through all beats in Chapter 1 -> Choice Overlay
      for (var i = 1; i < vm.totalBeatsInChapter; i++) {
        vm.advanceDialogue();
        expect(vm.currentBeatIndex, i);
        expect(vm.isChoiceOverlayOpen, isFalse);
      }
      expect(vm.currentBeatIndex, vm.totalBeatsInChapter - 1);

      // Advancing on the final beat opens the centered choice overlay
      vm.advanceDialogue();
      expect(vm.isChoiceOverlayOpen, isTrue);

      // Headpat / character tap increases affection and triggers reaction
      vm.onCharacterTapped();
      expect(vm.affectionPoints, 74);
      expect(vm.currentEmotion, VnCharacterEmotion.surprised);
      expect(vm.heartBurstTick, greaterThan(0));

      // Manual emotion switch
      vm.setEmotionManually(VnCharacterEmotion.surprised);
      expect(vm.currentEmotion, VnCharacterEmotion.surprised);

      // Scene switch
      vm.setSceneManually(VnSceneBackground.sakuraSunset);
      expect(vm.currentScene, VnSceneBackground.sakuraSunset);

      // Showcase lookup
      final toolsShowcase = VnScenarioCatalog.showcaseById('ch6_tool_declare');
      expect(toolsShowcase.topicId, 'ch6_tool_declare');
    },
  );

  testWidgets(
    'AnimeVnNavigatorPage renders visual novel dialogue box, step indicator, and choices',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: AnimeVnNavigatorPage(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Text &&
              w.data != null &&
              (w.data!.contains('히카리') || w.data!.contains('ヒカリ')),
        ),
        findsWidgets,
      );
      expect(find.textContaining('STEP 1 /'), findsWidgets);
      expect(find.text('CHOICE'), findsOneWidget);
      expect(find.text('LOG'), findsOneWidget);
    },
  );
}
