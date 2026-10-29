import 'package:example/app_translations.dart';
import 'package:example/examples/anime_vn_navigator/domain/models/vn_character_models.dart';
import 'package:example/examples/anime_vn_navigator/domain/models/vn_sdk_chapter.dart';
import 'package:example/examples/anime_vn_navigator/ui/anime_vn_navigator_screen.dart';
import 'package:example/examples/anime_vn_navigator/ui/view_models/anime_vn_view_model.dart';
import 'package:example/examples/chat/ui/chat/chat_screen.dart';
import 'package:example/examples/dj_midi_box/ui/dj_midi_box/dj_midi_box_screen.dart';
import 'package:example/examples/function_calling/ui/function_calling/function_calling_screen.dart';
import 'package:example/examples/live_api/ui/live_api/live_api_screen.dart';
import 'package:example/examples/math_tutor/ui/math_tutor/math_tutor_screen.dart';
import 'package:example/examples/media_subtitle/ui/media_subtitle/media_subtitle_screen.dart';
import 'package:example/examples/music_studio/ui/music_studio/music_studio_screen.dart';
import 'package:example/examples/pro_dj_console/ui/pro_dj_console/pro_dj_console_screen.dart';
import 'package:example/examples/realtime_media/ui/realtime_media/realtime_media_screen.dart';
import 'package:example/examples/smart_notetaker/ui/smart_notetaker/smart_notetaker_screen.dart';
import 'package:example/examples/translation/ui/translation/translation_screen.dart';
import 'package:example/examples/vision_call/ui/vision_call/vision_call_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemini_live/gemini_live.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:example/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

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
              (w.data!.contains('히카리') ||
                  w.data!.contains('ヒカリ') ||
                  w.data!.contains('Hikari') ||
                  w.data!.contains('光')),
        ),
        findsWidgets,
      );
      expect(find.textContaining('STEP 1 /'), findsWidgets);
      expect(find.text('CHOICE'), findsOneWidget);
      expect(find.text('LOG'), findsOneWidget);
    },
  );

  testWidgets(
    'AnimeVnNavigatorPage renders cleanly without overflow on mobile portrait and landscape viewports',
    (WidgetTester tester) async {
      const mobileSizes = <Size>[
        Size(320, 568), // iPhone SE (narrowest mobile portrait)
        Size(360, 640), // Compact Android portrait
        Size(375, 812), // Standard iPhone portrait
        Size(667, 375), // Mobile landscape
      ];

      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      for (final size in mobileSizes) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          const MaterialApp(
            home: AnimeVnNavigatorPage(),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull, reason: 'No overflow at $size');

        // Toggle CHOICE overlay on mobile
        await tester.tap(find.text('CHOICE'));
        await tester.pump(const Duration(milliseconds: 100));
        expect(
          tester.takeException(),
          isNull,
          reason: 'No overflow with CHOICE open at $size',
        );

        // Close CHOICE overlay and open RIG inspector on mobile
        await tester.tap(find.text('CHOICE'));
        await tester.pump(const Duration(milliseconds: 50));
        await tester.tap(find.text('RIG'));
        await tester.pump(const Duration(milliseconds: 100));
        expect(
          tester.takeException(),
          isNull,
          reason: 'No overflow with RIG open at $size',
        );
        await tester.tap(find.text('RIG'));
        await tester.pump(const Duration(milliseconds: 50));

        // Open Backlog (LOG) bottom sheet on mobile
        await tester.tap(find.text('LOG'));
        await tester.pump(const Duration(milliseconds: 250));
        expect(
          tester.takeException(),
          isNull,
          reason: 'No overflow with LOG bottom sheet open at $size',
        );
        Navigator.of(tester.element(find.byType(AnimeVnNavigatorPage))).pop();
        await tester.pump(const Duration(milliseconds: 250));
      }
    },
  );

  testWidgets(
    'All 13 example screens render without overflow on mobile portrait and landscape viewports',
    (WidgetTester tester) async {
      const mobileSizes = <Size>[
        Size(320, 568), // iPhone SE
        Size(360, 640), // Compact Android
        Size(375, 812), // Standard iPhone
        Size(667, 375), // Mobile landscape
      ];

      final pages = <String, Widget Function()>{
        'HomePage': () => const HomePage(),
        'AnimeVnNavigatorPage': () => const AnimeVnNavigatorPage(),
        'LiveTranslationPage': () => const LiveTranslationPage(),
        'LiveMediaSubtitlePage': () => const LiveMediaSubtitlePage(),
        'LiveSmartNotePage': () => const LiveSmartNotePage(),
        'LiveMathTutorPage': () => const LiveMathTutorPage(),
        'LiveVisionCallPage': () => const LiveVisionCallPage(),
        'LiveMusicStudioPage': () => const LiveMusicStudioPage(),
        'ProDjConsolePage': () => const ProDjConsolePage(),
        'DjMidiBoxPage': () => const DjMidiBoxPage(),
        'ChatPage': () => const ChatPage(),
        'LiveAPIDemoPage': () => const LiveAPIDemoPage(),
        'FunctionCallingDemoPage': () => const FunctionCallingDemoPage(),
        'RealtimeMediaDemoPage': () => const RealtimeMediaDemoPage(),
      };

      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final failures = <String>[];
      for (final size in mobileSizes) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        for (final entry in pages.entries) {
          await tester.pumpWidget(
            MaterialApp(
              home: entry.value(),
            ),
          );
          await tester.pump(const Duration(milliseconds: 100));
          final err = tester.takeException();
          if (err != null) {
            failures.add('${entry.key} @ $size: $err');
          }
          if (entry.key != 'HomePage') {
            expect(
              find.byType(GeminiLiveUsageBadge),
              findsWidgets,
              reason: '${entry.key} should display GeminiLiveUsageBadge',
            );
          }
        }
      }
      expect(failures, isEmpty, reason: failures.join('\n'));
    },
  );

  testWidgets(
    'All 13 example screens support dynamic 4-language (en, ko, ja, zh) switching without overflow on 320x568',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(() {
        AppLanguageController.instance.setLanguage(AppLanguage.en);
      });

      final pages = <String, Widget Function()>{
        'HomePage': () => const HomePage(),
        'AnimeVnNavigatorPage': () => const AnimeVnNavigatorPage(),
        'LiveTranslationPage': () => const LiveTranslationPage(),
        'LiveMediaSubtitlePage': () => const LiveMediaSubtitlePage(),
        'LiveSmartNotePage': () => const LiveSmartNotePage(),
        'LiveMathTutorPage': () => const LiveMathTutorPage(),
        'LiveVisionCallPage': () => const LiveVisionCallPage(),
        'LiveMusicStudioPage': () => const LiveMusicStudioPage(),
        'ProDjConsolePage': () => const ProDjConsolePage(),
        'DjMidiBoxPage': () => const DjMidiBoxPage(),
        'ChatPage': () => const ChatPage(),
        'LiveAPIDemoPage': () => const LiveAPIDemoPage(),
        'FunctionCallingDemoPage': () => const FunctionCallingDemoPage(),
        'RealtimeMediaDemoPage': () => const RealtimeMediaDemoPage(),
      };

      final failures = <String>[];
      for (final entry in pages.entries) {
        await tester.pumpWidget(
          MaterialApp(
            home: entry.value(),
          ),
        );
        for (final lang in AppLanguage.values) {
          AppLanguageController.instance.setLanguage(lang);
          await tester.pump(const Duration(milliseconds: 80));
          final err = tester.takeException();
          if (err != null) {
            failures.add('${entry.key} [${lang.code}]: $err');
          }
        }
      }
      expect(failures, isEmpty, reason: failures.join('\n'));
    },
  );

  testWidgets(
    'DjMidiBoxPage (16-CH Mixer Desk & 4x4 Pad Matrix) and ProDjConsolePage hardware controls work without errors across viewports',
    (WidgetTester tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const testSizes = <Size>[
        Size(320, 568), // Mobile portrait
        Size(667, 375), // Mobile landscape
        Size(1280, 800), // Desktop wide
      ];

      for (final size in testSizes) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        // 1. DjMidiBoxPage in 16-CH Mixer Desk mode
        await tester.pumpWidget(const MaterialApp(home: DjMidiBoxPage()));
        await tester.pump(const Duration(milliseconds: 100));
        expect(
          tester.takeException(),
          isNull,
          reason: 'DjMidiBoxPage 16-CH Mixer mode at $size',
        );
        expect(find.text('16-CH MIXER'), findsOneWidget);

        // Toggle to 4x4 PAD Matrix mode and verify layout at all sizes
        await tester.tap(find.text('16-CH MIXER'));
        await tester.pump(const Duration(milliseconds: 150));
        expect(
          tester.takeException(),
          isNull,
          reason: 'DjMidiBoxPage 4x4 PAD mode at $size',
        );
        expect(find.text('4x4 PAD'), findsOneWidget);

        // Toggle back to 16-CH Mixer mode
        await tester.tap(find.text('4x4 PAD'));
        await tester.pump(const Duration(milliseconds: 150));
        expect(
          tester.takeException(),
          isNull,
          reason: 'DjMidiBoxPage back to 16-CH Mixer mode at $size',
        );

        // 2. ProDjConsolePage hardware mixer at all sizes
        await tester.pumpWidget(const MaterialApp(home: ProDjConsolePage()));
        await tester.pump(const Duration(milliseconds: 100));
        expect(
          tester.takeException(),
          isNull,
          reason: 'ProDjConsolePage at $size',
        );
        expect(find.text('CH 1 ON'), findsOneWidget);
        expect(find.text('CH 2 ON'), findsOneWidget);
      }
    },
  );
}
