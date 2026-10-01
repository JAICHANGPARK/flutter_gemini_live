import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemini_live/gemini_live.dart';

void main() {
  group('GeminiLiveAudioUtils', () {
    test('calculateRms and calculatePeak return 0 for empty or short buffers', () {
      expect(GeminiLiveAudioUtils.calculateRms(Uint8List(0)), 0.0);
      expect(GeminiLiveAudioUtils.calculateRms(Uint8List(1)), 0.0);
      expect(GeminiLiveAudioUtils.calculatePeak(Uint8List(0)), 0.0);
      expect(GeminiLiveAudioUtils.calculatePeak(Uint8List(1)), 0.0);
      expect(GeminiLiveAudioUtils.calculateDecibels(Uint8List(0)), -96.0);
    });

    test('calculateRms, calculatePeak, and calculateDecibels compute correct values for 16-bit PCM', () {
      // 4 samples: 0, 16384 (half-scale), 32767 (full-scale), -32768 (full-scale negative)
      final byteData = ByteData(8);
      byteData.setInt16(0, 0, Endian.little);
      byteData.setInt16(2, 16384, Endian.little);
      byteData.setInt16(4, 32767, Endian.little);
      byteData.setInt16(6, -32768, Endian.little);

      final pcm = byteData.buffer.asUint8List();

      final rms = GeminiLiveAudioUtils.calculateRms(pcm);
      expect(rms, greaterThan(0.5));
      expect(rms, lessThanOrEqualTo(1.0));

      final peak = GeminiLiveAudioUtils.calculatePeak(pcm);
      expect(peak, closeTo(1.0, 0.001));

      final db = GeminiLiveAudioUtils.calculateDecibels(pcm);
      expect(db, greaterThan(-10.0));
      expect(db, lessThanOrEqualTo(0.0));
    });

    test('toVisualScale scales amplitude smoothly with custom factor', () {
      expect(GeminiLiveAudioUtils.toVisualScale(0.0), 0.0);
      expect(GeminiLiveAudioUtils.toVisualScale(1.0), 1.0);
      final mid = GeminiLiveAudioUtils.toVisualScale(0.25, factor: 2.0);
      expect(mid, closeTo(0.5, 0.01));
    });
  });

  group('GeminiLiveWaveform Widget', () {
    testWidgets('renders waveform bars with default configuration', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GeminiLiveWaveform(
              amplitude: 0.5,
              barCount: 5,
            ),
          ),
        ),
      );

      expect(find.byType(GeminiLiveWaveform), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('updates smoothly when amplitudeStream emits values', (tester) async {
      final controller = StreamController<double>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GeminiLiveWaveform(
              amplitudeStream: controller.stream,
              barCount: 7,
            ),
          ),
        ),
      );

      controller.add(0.8);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(GeminiLiveWaveform), findsOneWidget);
      await controller.close();
    });

    testWidgets('updates smoothly when raw PCM audioStream emits chunks', (tester) async {
      final audioController = StreamController<Uint8List>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GeminiLiveWaveform(
              audioStream: audioController.stream,
              barCount: 9,
            ),
          ),
        ),
      );

      final byteData = ByteData(4);
      byteData.setInt16(0, 10000, Endian.little);
      byteData.setInt16(2, 20000, Endian.little);
      audioController.add(byteData.buffer.asUint8List());

      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(GeminiLiveWaveform), findsOneWidget);

      await audioController.close();
    });
  });

  group('GeminiLiveCaptionBubble Widget', () {
    testWidgets('renders text, speaker tag, and style correctly for model', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GeminiLiveCaptionBubble(
              text: 'Hello from Gemini Live!',
              role: 'model',
              speaker: 'Charon',
              style: 'whispering',
              isStreaming: true,
            ),
          ),
        ),
      );

      expect(find.text('Hello from Gemini Live!'), findsOneWidget);
      expect(find.text('Charon'), findsOneWidget);
      expect(find.text('• whispering'), findsOneWidget);
    });

    testWidgets('renders user role badge correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GeminiLiveCaptionBubble(
              text: 'Can you hear me?',
              role: 'user',
            ),
          ),
        ),
      );

      expect(find.text('Can you hear me?'), findsOneWidget);
      expect(find.text('You'), findsOneWidget);
    });

    testWidgets('handles autoDismissDuration callback', (tester) async {
      bool dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GeminiLiveCaptionBubble(
              text: 'Temporary notice',
              autoDismissDuration: const Duration(milliseconds: 100),
              onDismissed: () {
                dismissed = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Temporary notice'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump(const Duration(milliseconds: 300));

      expect(dismissed, isTrue);
    });

    testWidgets('respects showSpeakerTag: false and enableBlur: false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GeminiLiveCaptionBubble(
              text: 'Clean subtitle without tag',
              showSpeakerTag: false,
              enableBlur: false,
            ),
          ),
        ),
      );

      expect(find.text('Clean subtitle without tag'), findsOneWidget);
      expect(find.text('Gemini'), findsNothing);
      expect(find.text('You'), findsNothing);
    });
  });
}
