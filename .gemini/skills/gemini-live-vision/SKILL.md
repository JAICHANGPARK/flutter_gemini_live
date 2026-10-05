---
name: gemini-live-vision
description: Implement real-time camera vision streaming, video frame processing, and viewfinder HUD overlays in Flutter using the Gemini Live API. Use when streaming live camera frames (1-2 FPS JPEG), configuring GeminiLiveVisionOverlay, or performing Project Astra style multimodal visual QA and spatial reasoning.
---

# Gemini Live Vision & Camera Streaming Skill

This skill provides instructions and production patterns for streaming live camera frames to the Gemini Live API for real-time visual reasoning and multimodal dialogue.

---

## 📷 Vision Specifications & Performance Targets

Live video streaming requires balanced frame rates and resolution to ensure low latency and prevent WebSocket backpressure:

| Property | Recommended Value | Notes |
|---|---|---|
| **Frame Rate** | **1.0 – 2.0 FPS** (1 frame every 500–1000ms) | Higher FPS causes network saturation and rate limits without improving reasoning quality. |
| **Format / MIME** | `image/jpeg` | Low overhead compression. |
| **Resolution** | **640x480 (VGA)** or **720p (HD)** | Use `ResolutionPreset.medium` in `package:camera`. Avoid 4K/1080p. |
| **JPEG Quality** | **70% – 80%** | Balances visual clarity with small payload sizes (< 80 KB/frame). |
| **Companion Package** | [`camera`](https://pub.dev/packages/camera) `^0.11.0` | Official Flutter camera plugin. |

---

## ⚙️ Platform Permissions

### Android (`android/app/src/main/AndroidManifest.xml`)
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-feature android:name="android.hardware.camera" />
```

### iOS / macOS (`ios/Runner/Info.plist` & `macos/Runner/Info.plist`)
```xml
<key>NSCameraUsageDescription</key>
<string>This app requires camera access to stream real-time video to Gemini Live.</string>
```

---

## 🚀 Complete Camera Streaming Pattern

```dart
import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:gemini_live/gemini_live.dart';

class LiveVisionController {
  final GeminiLiveSessionController sessionController;
  CameraController? _cameraController;
  Timer? _frameTimer;
  bool _isStreamingFrames = false;

  LiveVisionController({required this.sessionController});

  /// Initialize the camera and prepare for frame extraction
  Future<void> initializeCamera(List<CameraDescription> cameras) async {
    final backCamera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      backCamera,
      ResolutionPreset.medium, // 720p or VGA recommended
      enableAudio: false,       // Audio is handled separately by package:record
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    await _cameraController!.initialize();
  }

  /// Start streaming video frames to Gemini Live at the given interval
  void startVideoStream({Duration interval = const Duration(milliseconds: 1000)}) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    _isStreamingFrames = true;

    _frameTimer?.cancel();
    _frameTimer = Timer.periodic(interval, (_) async {
      if (!_isStreamingFrames || _cameraController == null) return;
      if (!_cameraController!.value.isInitialized || _cameraController!.value.isTakingPicture) return;

      try {
        // Take a low-latency picture frame
        final xFile = await _cameraController!.takePicture();
        final bytes = await xFile.readAsBytes();

        // Send JPEG bytes directly to the live session
        sessionController.sendRealtimeMediaChunks(
          mimeType: 'image/jpeg',
          data: bytes,
        );
      } catch (e) {
        debugPrint('Camera frame capture error: $e');
      }
    });
  }

  /// Stop streaming camera frames
  void stopVideoStream() {
    _isStreamingFrames = false;
    _frameTimer?.cancel();
    _frameTimer = null;
  }

  Future<void> dispose() async {
    stopVideoStream();
    await _cameraController?.dispose();
  }
}
```

---

## 🎯 Project Astra Style HUD: `GeminiLiveVisionOverlay`

The package provides `GeminiLiveVisionOverlay` to wrap any camera preview with futuristic scanning reticles, radar scanlines, and an analyzing badge:

```dart
Widget buildCameraHUD(BuildContext context, CameraController camera) {
  return Stack(
    children: [
      // 1. Raw Camera Preview
      CameraPreview(camera),

      // 2. Futuristic Project Astra HUD Overlay
      GeminiLiveVisionOverlay(
        isAnalyzing: controller.isModelSpeaking || isCameraActive,
        analyzingText: 'GEMINI LIVE VISION ACTIVE',
        accentColor: const Color(0xFF38BDF8),
        showScanlines: true,
        showReticles: true,
      ),

      // 3. Floating Call Controls
      Positioned(
        bottom: 30,
        left: 20,
        right: 20,
        child: GeminiLiveControlBar(
          isMicMuted: isMicMuted,
          isVideoEnabled: isVideoStreaming,
          onToggleMic: toggleMic,
          onToggleVideo: toggleVideo,
          onHangUp: endSession,
        ),
      ),
    ],
  );
}
```

---

## 🚨 Critical Vision Guidelines

1. **Do not use `startImageStream` directly without downsampling/throttling:**
   `startImageStream` yields 30–60 raw YUV420/BGRA frames per second. Sending uncompressed raw frames will immediately crash the app with Out-of-Memory (OOM) or saturate the WebSocket connection.
2. **Keep resolution moderate:**
   `ResolutionPreset.medium` (~720x480 or 1280x720) is ideal. High resolution (1080p, 4K) drastically increases latency without improving text or object recognition.
3. **Always separate audio and video pipelines:**
   Disable audio on `CameraController` (`enableAudio: false`). Microphones should be captured using `package:record` at 16,000 Hz linear PCM mono.
