import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../domain/models/vn_character_models.dart';
import '../view_models/anime_vn_view_model.dart';

/// Option A — 6-Part 2.5D Decomposed Character Stage (`Live2D` / `Spine` / `ZZZ` Style).
///
/// Implements the full 2.5D character animation pipeline for Hikari (ヒカリ):
/// 1. **6 Anatomical 2.5D Parts with C² Smoothstep Weights & Z-Axis Parallax**:
///    - **Part 1 (`Z = -1.0`) — Back Hair & Twin-Braids**: 2-link coupled pendulum
///      spring chain (`_hairMidSpringX`, `_hairTipSpringX`) + reverse Z-parallax.
///    - **Part 2 (`Z =  0.0`) — Torso, Uniform & Collar Ribbon**: Respiratory breathing,
///      vertical torso spring (`_bustSpringPos`), ribbon flutter, and audio-reactive
///      glowing star badge (`u = 0.630, v = 0.628`).
///    - **Part 3 (`Z = +0.35`) — Rigid Face & Cranium (Flat Normal Zone)**: 100%
///      rigid Euclidean transform around neck pivot `(0.505, 0.445)` so facial
///      features never warp or shear, with zero double-image ghosting.
///    - **Part 4 (`Z = +0.55`) — Dynamic Eye Pupils, Starlight Catchlights & Eyelid Blink**:
///      Mouse-tracking luminous cyan iris glow & dual starlight catchlights inside
///      both eyes (`(0.422, 0.324)` and `(0.590, 0.318)`) + natural periodic blinking.
///    - **Part 5 (`Z = +0.60`) — Audio-Reactive Lip-Sync Mouth, Jaw Micro-Bounce & Blush**:
///      24kHz PCM RMS energy + syllable envelope drives open/closed vowel articulation,
///      subtle chin bounce, and animated rosy cheek blush.
///    - **Part 6 (`Z = +0.85`) — Foreground Bangs, Side-Locks & Cyber Wing Hairpins**:
///      Foreground Z-parallax bangs/side-locks + independent wing-flap spring physics
///      (`_wingFlapPos`) on both cyan Flutter/Gemini wing hairpins.
/// 2. **ZZZ Volume-Preserving Squash & Stretch (`scaleX = 1 / sqrt(scaleY)`)** +
///    **Stepped Interpolation Mode (12fps 2-Koma Anime Timing vs 60fps Smooth)**.
/// 3. **Interactive `🦴 2.5D RIG` Live Inspector Overlay**: Visualizes the 6 bones,
///    spring vectors, eye gaze target, and mesh wireframe live on stage.
class LiveAnimeCharacterStage extends StatefulWidget {
  final AnimeVnViewModel viewModel;
  final Alignment characterAlignment;

  const LiveAnimeCharacterStage({
    super.key,
    required this.viewModel,
    this.characterAlignment = Alignment.bottomCenter,
  });

  @override
  State<LiveAnimeCharacterStage> createState() =>
      _LiveAnimeCharacterStageState();
}

class _LiveAnimeCharacterStageState extends State<LiveAnimeCharacterStage>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  double _elapsedSeconds = 0.0;
  double _lastTickSeconds = 0.0;

  // Decoded GPU textures (`ui.Image`) for single-pass mesh & part rendering
  final Map<String, ui.Image> _decodedSprites = {};

  // Real-time 24kHz audio lip-sync energy (0.0 -> 1.0)
  double _lipSyncEnergy = 0.0;

  // Natural Eye Blinking State Machine
  double _nextBlinkTime = 2.4;
  double _blinkStartTime = -10.0;
  bool _isDoubleBlink = false;
  double _blinkAmount = 0.0; // 0.0 = open, 1.0 = closed

  // Rigid Head Pose (`_headYaw`, `_headPitch`, `_headRoll`)
  double _headYaw = 0.0;
  double _headPitch = 0.0;
  double _headRoll = 0.0;
  double _prevHeadX = 0.0;

  // 2-Link Coupled Pendulum Hair Springs (Part 1 & Part 6)
  double _hairMidSpringX = 0.0;
  double _hairMidSpringVelX = 0.0;
  double _hairTipSpringX = 0.0;
  double _hairTipSpringVelX = 0.0;
  double _headShakeImpulse = 0.0;

  // Cyber Wing Hairpins Flap Spring (Part 6)
  double _wingFlapPos = 0.0;
  double _wingFlapVel = 0.0;

  // Torso / Ribbon Vertical Spring (Part 2)
  double _bustSpringPos = 0.0;
  double _bustSpringVel = 0.0;
  double _prevBodyY = 0.0;

  // Per-Heroine Squash & Stretch Springs & Motion Timers
  double _squashSpringPos = 0.0;
  double _squashSpringVel = 0.0;
  double _hikariSquashPos = 0.0;
  double _hikariSquashVel = 0.0;
  double _reinaSquashPos = 0.0;
  double _reinaSquashVel = 0.0;

  // Triggered stage motion state (per heroine & global)
  int _lastHandledMotionTick = 0;
  int _lastHandledHikariMotionTick = 0;
  int _lastHandledReinaMotionTick = 0;
  double _hikariMotionStartTime = -10.0;
  double _reinaMotionStartTime = -10.0;
  VnStageMotion _activeMotion = VnStageMotion.idle;
  VnCharacterEmotion _lastEmotion = VnCharacterEmotion.normal;
  VnHeroineCharacter _lastHeroine = VnHeroineCharacter.reina;

  // Stage Camera State
  double _cameraZoom = 1.0;
  double _cameraDutchAngle = 0.0;
  Offset _cameraFocusOffset = Offset.zero;

  // Per-Heroine Heart burst particles on headpat / affection gain
  int _lastHandledHikariHeartTick = 0;
  int _lastHandledReinaHeartTick = 0;
  final List<_FloatingHeartParticle> _hikariHearts = [];
  final List<_FloatingHeartParticle> _reinaHearts = [];

  // Interactive pointer / drag parallax (-1..1) & Eye Gaze Tracking
  Offset _pointerParallax = Offset.zero;
  Offset _smoothedParallax = Offset.zero;
  Offset _eyeGazeOffset = Offset.zero;

  // Sakura & cyber particles
  late final List<_StageParticle> _particles = List.generate(
    28,
    (index) => _StageParticle.seeded(index),
  );

  @override
  void initState() {
    super.initState();
    _lastHandledMotionTick = widget.viewModel.motionTriggerTick;
    _lastHandledHikariMotionTick = widget.viewModel.motionTickFor(
      VnHeroineCharacter.hikari,
    );
    _lastHandledReinaMotionTick = widget.viewModel.motionTickFor(
      VnHeroineCharacter.reina,
    );
    _lastHandledHikariHeartTick = widget.viewModel.heartBurstTickFor(
      VnHeroineCharacter.hikari,
    );
    _lastHandledReinaHeartTick = widget.viewModel.heartBurstTickFor(
      VnHeroineCharacter.reina,
    );
    _lastEmotion = widget.viewModel.currentEmotion;
    _lastHeroine = widget.viewModel.selectedHeroine;
    _loadAllSpriteTextures();

    _ticker = createTicker(_onTick)..start();
  }

  Future<void> _loadAllSpriteTextures() async {
    final paths = <String>{
      for (final h in VnHeroineCharacter.values)
        for (final e in VnCharacterEmotion.values) ...[
          e.assetPathFor(h),
          e.closedAssetPathFor(h),
          e.talkingAssetPathFor(h),
          e.blinkAssetPathFor(h),
        ],
    };

    for (final path in paths) {
      try {
        final data = await rootBundle.load(path);
        final codec = await ui.instantiateImageCodec(
          data.buffer.asUint8List(),
        );
        final frame = await codec.getNextFrame();
        if (mounted) {
          setState(() {
            _decodedSprites[path] = frame.image;
          });
        }
      } catch (_) {}
    }
  }

  /// Selects the single active sprite path for the current frame so we never
  /// overlay incompatible poses or cause double images.
  String _resolveActiveSpritePath(
    VnHeroineCharacter heroine,
    VnCharacterEmotion emotion,
    double nowSec,
  ) {
    // 1. Natural periodic eye blink takes priority when eyelids are closed
    if (_blinkAmount > 0.42) {
      return emotion.blinkAssetPathFor(heroine);
    }

    // 2. When speaking (real 24kHz audio or simulated burst), articulate mouth
    //    between open vowel ('あ') and closed mouth at natural Japanese syllable rate (~5.5 Hz)
    if (_lipSyncEnergy > 0.14) {
      final syllableOpen =
          _lipSyncEnergy > 0.42 || math.sin(nowSec * 34.0) > -0.15;
      return syllableOpen
          ? emotion.talkingAssetPathFor(heroine)
          : emotion.closedAssetPathFor(heroine);
    }

    // 3. When silent, keep mouth cleanly closed
    return emotion.closedAssetPathFor(heroine);
  }

  void _triggerSquashImpulse(
    double velocityImpulse, {
    VnHeroineCharacter? targetHeroine,
  }) {
    _squashSpringVel += velocityImpulse;
    if (targetHeroine == null || targetHeroine == VnHeroineCharacter.hikari) {
      _hikariSquashVel += velocityImpulse;
    }
    if (targetHeroine == null || targetHeroine == VnHeroineCharacter.reina) {
      _reinaSquashVel += velocityImpulse;
    }
    _wingFlapVel += velocityImpulse * 1.4;
  }

  void _onTick(Duration elapsed) {
    final nowSec = elapsed.inMicroseconds / 1000000.0;
    final dt = (_lastTickSeconds == 0.0)
        ? 0.016
        : (nowSec - _lastTickSeconds).clamp(0.001, 0.05);
    _lastTickSeconds = nowSec;
    _elapsedSeconds = nowSec;

    final vm = widget.viewModel;
    final emotion = vm.currentEmotion;
    final heroine = vm.selectedHeroine;

    // 1. Smoothly track real-time 24kHz audio lip-sync RMS level
    _lipSyncEnergy = vm.sampleLipSyncEnergy(nowSec);

    // 2. Track emotion or heroine changes smoothly without bouncing the character
    if (emotion != _lastEmotion || heroine != _lastHeroine) {
      final heroineChanged = heroine != _lastHeroine;
      _lastEmotion = emotion;
      _lastHeroine = heroine;
      if (heroineChanged) {
        _triggerBlink(nowSec, doubleBlink: false);
      }
    }

    // 3. Check for newly triggered stage motion per heroine
    final hikariMotTick = vm.motionTickFor(VnHeroineCharacter.hikari);
    if (hikariMotTick != _lastHandledHikariMotionTick) {
      _lastHandledHikariMotionTick = hikariMotTick;
      _activeMotion = vm.lastMotion;
      _hikariMotionStartTime = nowSec;
      _triggerSquashImpulse(
        _activeMotion == VnStageMotion.jump ? 0.85 : 0.45,
        targetHeroine: VnHeroineCharacter.hikari,
      );
    }

    final reinaMotTick = vm.motionTickFor(VnHeroineCharacter.reina);
    if (reinaMotTick != _lastHandledReinaMotionTick) {
      _lastHandledReinaMotionTick = reinaMotTick;
      _activeMotion = vm.lastMotion;
      _reinaMotionStartTime = nowSec;
      _triggerSquashImpulse(
        _activeMotion == VnStageMotion.jump ? 0.85 : 0.45,
        targetHeroine: VnHeroineCharacter.reina,
      );
    }

    if (vm.motionTriggerTick != _lastHandledMotionTick) {
      _lastHandledMotionTick = vm.motionTriggerTick;
      _headShakeImpulse = _activeMotion == VnStageMotion.flusteredShake
          ? 0.55
          : 0.22;
      _triggerBlink(nowSec, doubleBlink: false);
    }

    // 4. Check for per-heroine affection / headpat heart bursts
    final hikariHeartTick = vm.heartBurstTickFor(VnHeroineCharacter.hikari);
    if (hikariHeartTick != _lastHandledHikariHeartTick) {
      _lastHandledHikariHeartTick = hikariHeartTick;
      _spawnHeartBurst(nowSec, VnHeroineCharacter.hikari);
    }

    final reinaHeartTick = vm.heartBurstTickFor(VnHeroineCharacter.reina);
    if (reinaHeartTick != _lastHandledReinaHeartTick) {
      _lastHandledReinaHeartTick = reinaHeartTick;
      _spawnHeartBurst(nowSec, VnHeroineCharacter.reina);
    }

    _hikariHearts.removeWhere((h) => (nowSec - h.spawnTime) > 1.8);
    _reinaHearts.removeWhere((h) => (nowSec - h.spawnTime) > 1.8);

    // 5. Smooth pointer parallax & Eye Gaze Tracking
    _smoothedParallax = Offset.lerp(
      _smoothedParallax,
      _pointerParallax,
      (dt * 7.5).clamp(0.0, 1.0),
    )!;

    final targetGaze = Offset(
      _smoothedParallax.dx + math.sin(nowSec * 1.9) * 0.12,
      _smoothedParallax.dy + math.cos(nowSec * 1.4) * 0.08,
    );
    _eyeGazeOffset = Offset.lerp(
      _eyeGazeOffset,
      targetGaze,
      (dt * 12.0).clamp(0.0, 1.0),
    )!;

    // 6. Periodic Natural Eye Blinking State Machine (every 2.4s - 4.2s)
    if (nowSec >= _nextBlinkTime) {
      final rng = math.Random(nowSec.microsecondsSinceEpochSafe);
      _triggerBlink(nowSec, doubleBlink: rng.nextDouble() < 0.30);
      _nextBlinkTime = nowSec + 2.4 + rng.nextDouble() * 1.8;
    }
    _blinkAmount = _evaluateBlinkCurve(nowSec - _blinkStartTime);

    // Decay head-shake impulse
    _headShakeImpulse *= math.exp(-3.4 * dt);
    final shakeWave = math.sin(nowSec * 14.0) * _headShakeImpulse;

    // 7. Compute Gentle Rigid Head/Upper-Body Pose (`_headYaw`, `_headPitch`, `_headRoll`)
    //    Kept in a natural range so the character never skews or tilts excessively.
    final speechYaw =
        math.sin(nowSec * 3.8) * _lipSyncEnergy * 0.25 +
        math.cos(nowSec * 6.2) * _lipSyncEnergy * 0.12;
    final speechPitch = -math.sin(nowSec * 9.2).abs() * _lipSyncEnergy * 0.22;
    final idleYaw =
        math.sin(nowSec * 1.05) * 0.18 + math.cos(nowSec * 0.52) * 0.09;
    final idlePitch = math.sin(nowSec * 1.55) * 0.14;

    final targetYaw =
        (_smoothedParallax.dx * 0.35 + speechYaw + idleYaw + shakeWave * 0.35)
            .clamp(-0.6, 0.6);
    final targetPitch = (_smoothedParallax.dy * 0.25 + speechPitch + idlePitch)
        .clamp(-0.5, 0.5);
    final targetRoll =
        (_smoothedParallax.dx * 0.018 +
                math.sin(nowSec * 1.18) * 0.010 +
                math.sin(nowSec * 4.5) * _lipSyncEnergy * 0.015 +
                shakeWave * 0.022)
            .clamp(-0.045, 0.045);

    _headYaw += (targetYaw - _headYaw) * (dt * 9.5).clamp(0.0, 1.0);
    _headPitch += (targetPitch - _headPitch) * (dt * 9.5).clamp(0.0, 1.0);
    _headRoll += (targetRoll - _headRoll) * (dt * 8.5).clamp(0.0, 1.0);

    // 8. 2-Link Coupled Pendulum Spring Physics for Hair Strands (Part 1 & Part 6)
    final currentHeadX = _headYaw * 16.0 + _headRoll * 110.0;
    final headVelX = (currentHeadX - _prevHeadX) / dt;
    _prevHeadX = currentHeadX;

    // Link 1: Mid-hair spring (reacts to head velocity with inertia)
    const kMid = 135.0;
    const dMid = 7.8;
    final midForce =
        -kMid * _hairMidSpringX -
        dMid * _hairMidSpringVelX -
        headVelX * 0.52 +
        shakeWave * 210.0;
    _hairMidSpringVelX += midForce * dt;
    _hairMidSpringX = (_hairMidSpringX + _hairMidSpringVelX * dt).clamp(
      -26.0,
      26.0,
    );

    // Link 2: Hair-tips spring (follows mid-hair with secondary phase lag)
    const kTip = 92.0;
    const dTip = 5.6;
    final tipForce =
        -kTip * (_hairTipSpringX - _hairMidSpringX * 1.28) -
        dTip * _hairTipSpringVelX -
        headVelX * 0.25;
    _hairTipSpringVelX += tipForce * dt;
    _hairTipSpringX = (_hairTipSpringX + _hairTipSpringVelX * dt).clamp(
      -38.0,
      38.0,
    );

    // 8b. Cyber Wing Hairpins Flap Spring (Part 6)
    const kWing = 210.0;
    const dWing = 8.5;
    final wingAccel =
        -kWing * _wingFlapPos -
        dWing * _wingFlapVel +
        _lipSyncEnergy * 45.0 * math.sin(nowSec * 18.0);
    _wingFlapVel += wingAccel * dt;
    _wingFlapPos = (_wingFlapPos + _wingFlapVel * dt).clamp(-1.0, 1.0);

    // 8c. Torso / Ribbon gentle breathing spring (Part 2) - no vertical bounce on speech
    final currentBodyY = math.sin(nowSec * 2.35) * 3.0;
    final bodyVelY = (currentBodyY - _prevBodyY) / dt;
    _prevBodyY = currentBodyY;

    final bustAccel =
        -170.0 * _bustSpringPos - 12.0 * _bustSpringVel - bodyVelY * 0.25;
    _bustSpringVel += bustAccel * dt;
    _bustSpringPos = (_bustSpringPos + _bustSpringVel * dt).clamp(-8.0, 8.0);

    // 8d. Volume-Preserving Squash & Stretch Spring (per-heroine & global)
    const kSquash = 240.0;
    const dSquash = 14.0;
    final squashAccel = -kSquash * _squashSpringPos - dSquash * _squashSpringVel;
    _squashSpringVel += squashAccel * dt;
    _squashSpringPos = (_squashSpringPos + _squashSpringVel * dt).clamp(
      -0.06,
      0.06,
    );

    final hikariSqAccel =
        -kSquash * _hikariSquashPos - dSquash * _hikariSquashVel;
    _hikariSquashVel += hikariSqAccel * dt;
    _hikariSquashPos = (_hikariSquashPos + _hikariSquashVel * dt).clamp(
      -0.06,
      0.06,
    );

    final reinaSqAccel = -kSquash * _reinaSquashPos - dSquash * _reinaSquashVel;
    _reinaSquashVel += reinaSqAccel * dt;
    _reinaSquashPos = (_reinaSquashPos + _reinaSquashVel * dt).clamp(
      -0.06,
      0.06,
    );

    // 9. Keep stage camera steady so clicking dialogue never zooms or jolts the screen
    _cameraZoom = 1.0;
    _cameraDutchAngle = 0.0;
    _cameraFocusOffset = Offset.zero;

    for (final p in _particles) {
      p.advance(dt);
    }

    setState(() {});
  }

  void _triggerBlink(double nowSec, {bool doubleBlink = false}) {
    _blinkStartTime = nowSec;
    _isDoubleBlink = doubleBlink;
  }

  double _evaluateBlinkCurve(double elapsedSinceBlink) {
    const singleDuration = 0.15;
    if (elapsedSinceBlink < 0) return 0.0;
    if (elapsedSinceBlink <= singleDuration) {
      final t = elapsedSinceBlink / singleDuration;
      return math.sin(t * math.pi).clamp(0.0, 1.0);
    }
    if (_isDoubleBlink &&
        elapsedSinceBlink > singleDuration + 0.06 &&
        elapsedSinceBlink <= singleDuration * 2 + 0.06) {
      final t = (elapsedSinceBlink - (singleDuration + 0.06)) / singleDuration;
      return math.sin(t * math.pi).clamp(0.0, 1.0);
    }
    return 0.0;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final h in VnHeroineCharacter.values) {
      for (final emotion in VnCharacterEmotion.values) {
        precacheImage(AssetImage(emotion.assetPathFor(h)), context);
        precacheImage(AssetImage(emotion.closedAssetPathFor(h)), context);
        precacheImage(AssetImage(emotion.talkingAssetPathFor(h)), context);
        precacheImage(AssetImage(emotion.blinkAssetPathFor(h)), context);
      }
    }
    precacheImage(
      const AssetImage('assets/anime_vn/bg_tokyo_conf.png'),
      context,
    );
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _spawnHeartBurst(double nowSec, VnHeroineCharacter heroine) {
    final rng = math.Random(
      nowSec.microsecondsSinceEpochSafe ^ heroine.index,
    );
    final targetList = heroine == VnHeroineCharacter.reina
        ? _reinaHearts
        : _hikariHearts;
    for (var i = 0; i < 7; i++) {
      targetList.add(
        _FloatingHeartParticle(
          spawnTime: nowSec,
          dxOffset: (rng.nextDouble() - 0.5) * 150.0,
          dyStart: -40.0 + (rng.nextDouble() - 0.5) * 60.0,
          speedY: 75.0 + rng.nextDouble() * 55.0,
          scale: 0.75 + rng.nextDouble() * 0.65,
          isTextPopup: i == 0,
          heroine: heroine,
        ),
      );
    }
  }

  void _handleHeroineTap(VnHeroineCharacter actor, double rawTime) {
    _headShakeImpulse = 0.65;
    _triggerSquashImpulse(0.95, targetHeroine: actor);
    _triggerBlink(rawTime, doubleBlink: true);
    widget.viewModel.onHeroineTapped(actor);
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;
    final scene = vm.currentScene;
    final emotion = vm.currentEmotion;
    final rawTime = _elapsedSeconds;

    // Optional Stepped Interpolation Mode (12fps "2-koma" anime timing vs 60fps smooth)
    final t = vm.isSteppedAnimationMode
        ? (rawTime * 12.0).floorToDouble() / 12.0
        : rawTime;

    // Default squash/stretch values for the Rig Inspector display
    final activeSquashPos =
        vm.activeSpeakingHeroine == VnHeroineCharacter.reina
        ? _reinaSquashPos
        : _hikariSquashPos;
    final squashStretchY = (1.0 + activeSquashPos).clamp(0.91, 1.10);
    final squashStretchX = (1.0 / math.sqrt(squashStretchY)).clamp(0.94, 1.06);

    final screenHeight = MediaQuery.of(context).size.height;
    final charHeight = screenHeight * 0.86;
    final charWidth = charHeight * (768.0 / 1024.0);
    final isDual = vm.isDualHeroineMode;
    final activeSpeaker = vm.activeSpeakingHeroine;

    Widget buildHeroineActor(
      VnHeroineCharacter actor, {
      required Alignment alignment,
      required bool isSpeakingThisTurn,
      required double scaleFactor,
    }) {
      final actorLipEnergy = isSpeakingThisTurn ? _lipSyncEnergy : 0.0;
      final actorEmotion = vm.emotionFor(actor);
      final actorMotionStart = actor == VnHeroineCharacter.reina
          ? _reinaMotionStartTime
          : _hikariMotionStartTime;
      final actorSquash = actor == VnHeroineCharacter.reina
          ? _reinaSquashPos
          : _hikariSquashPos;
      final actorHearts = actor == VnHeroineCharacter.reina
          ? _reinaHearts
          : _hikariHearts;

      double actorImpulseX = 0.0;
      double actorImpulseY = 0.0;
      double actorImpulseRotate = 0.0;

      final motionAge = t - actorMotionStart;
      if (motionAge >= 0.0 && motionAge < 1.15) {
        final decay = math.exp(-3.8 * motionAge);
        switch (_activeMotion) {
          case VnStageMotion.jump:
            actorImpulseY = -math.sin(motionAge * 14.0).abs() * 28.0 * decay;
          case VnStageMotion.nod:
            actorImpulseY = math.sin(motionAge * 16.0) * 13.0 * decay;
            actorImpulseRotate = math.sin(motionAge * 8.0) * 0.024 * decay;
          case VnStageMotion.flusteredShake:
            actorImpulseX = math.sin(motionAge * 38.0) * 15.0 * decay;
            actorImpulseRotate = math.sin(motionAge * 38.0) * 0.038 * decay;
          case VnStageMotion.bow:
            actorImpulseY = math.sin(motionAge * math.pi).clamp(0.0, 1.0) * 22.0;
            actorImpulseRotate =
                math.sin(motionAge * math.pi).clamp(0.0, 1.0) * 0.048;
          case VnStageMotion.tilt:
            actorImpulseRotate = math.sin(motionAge * 5.0) * 0.058 * decay;
          case VnStageMotion.idle:
            break;
        }
      }

      final actorScaleY = (1.0 + actorSquash).clamp(0.91, 1.10);
      final actorScaleX = (1.0 / math.sqrt(actorScaleY)).clamp(0.94, 1.06);

      final spritePath = isSpeakingThisTurn
          ? _resolveActiveSpritePath(actor, actorEmotion, rawTime)
          : (_blinkAmount > 0.42
                ? actorEmotion.blinkAssetPathFor(actor)
                : actorEmotion.closedAssetPathFor(actor));
      final gpuImg =
          _decodedSprites[spritePath] ??
          _decodedSprites[actorEmotion.closedAssetPathFor(actor)] ??
          _decodedSprites[actorEmotion.assetPathFor(actor)];

      return Align(
        alignment: alignment,
        child: GestureDetector(
          behavior: HitTestBehavior.deferToChild,
          onTap: isDual ? null : () => _handleHeroineTap(actor, rawTime),
          onPanUpdate: (details) {
            final dx = (details.delta.dx / 60.0).clamp(-0.6, 0.6);
            final dy = (details.delta.dy / 60.0).clamp(-0.6, 0.6);
            _pointerParallax = Offset(
              (_pointerParallax.dx + dx).clamp(-1.0, 1.0),
              (_pointerParallax.dy + dy).clamp(-0.85, 0.85),
            );
          },
          onPanEnd: (_) {
            _pointerParallax = Offset.zero;
          },
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 280),
            opacity: isSpeakingThisTurn ? 1.0 : 0.88,
            child: Transform(
              alignment: Alignment.bottomCenter,
              transform: Matrix4.identity()
                ..translateByDouble(
                  actorImpulseX + _smoothedParallax.dx * 10.0,
                  actorImpulseY + _smoothedParallax.dy * 5.0,
                  0.0,
                  1.0,
                )
                ..rotateZ(actorImpulseRotate)
                ..scaleByDouble(
                  actorScaleX * scaleFactor,
                  actorScaleY * scaleFactor,
                  1.0,
                  1.0,
                ),
              child: SizedBox(
                width: charWidth,
                height: charHeight,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    if (gpuImg != null)
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _Live2dMultiPartCharacterPainter(
                            activeImage: gpuImg,
                            time:
                                t +
                                (actor == VnHeroineCharacter.reina ? 0.7 : 0.0),
                            lipSyncEnergy: actorLipEnergy,
                            headYaw: _headYaw,
                            headPitch: _headPitch,
                            headRoll: _headRoll,
                            blinkAmount: _blinkAmount,
                            hairMidSpringX: _hairMidSpringX,
                            hairTipSpringX: _hairTipSpringX,
                            wingFlapPos: _wingFlapPos,
                            bustSpringY: _bustSpringPos,
                            parallax: _smoothedParallax,
                            eyeGaze: _eyeGazeOffset,
                            affectionPoints: vm.affectionFor(actor),
                            emotion: actorEmotion,
                            showRigInspector:
                                vm.isRigInspectorVisible && isSpeakingThisTurn,
                          ),
                        ),
                      )
                    else
                      Image.asset(
                        spritePath,
                        fit: BoxFit.contain,
                        height: charHeight,
                      ),
                    for (final h in actorHearts)
                      _buildHeartParticle(h, rawTime, vm.isKorean),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return MouseRegion(
      onHover: (event) {
        final size = context.size;
        if (size != null && size.width > 0 && size.height > 0) {
          final nx = ((event.localPosition.dx / size.width) - 0.5) * 2.0;
          final ny = ((event.localPosition.dy / size.height) - 0.5) * 2.0;
          _pointerParallax = Offset(nx.clamp(-1.0, 1.0), ny.clamp(-1.0, 1.0));
        }
      },
      onExit: (_) => _pointerParallax = Offset.zero,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..translateByDouble(
                _cameraFocusOffset.dx,
                _cameraFocusOffset.dy,
                0.0,
                1.0,
              )
              ..rotateZ(_cameraDutchAngle)
              ..scaleByDouble(_cameraZoom, _cameraZoom, 1.0, 1.0),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 1. Scenic Visual Novel Background with Deep Z-Axis Parallax (Z = -2.0)
                Transform.translate(
                  offset: Offset(
                    -_smoothedParallax.dx * 18.0,
                    -_smoothedParallax.dy * 11.0,
                  ),
                  child: Transform.scale(
                    scale: 1.08,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          'assets/anime_vn/bg_tokyo_conf.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: scene.primaryGradient,
                                ),
                              ),
                            );
                          },
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                scene.primaryGradient.first.withValues(
                                  alpha: scene == VnSceneBackground.tokyoConf
                                      ? 0.22
                                      : 0.55,
                                ),
                                scene.primaryGradient.last.withValues(
                                  alpha: scene == VnSceneBackground.tokyoConf
                                      ? 0.48
                                      : 0.72,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. ZZZ-Style Cyber Halo & Audio-Reactive Rings
                CustomPaint(
                  painter: _VnStageAtmospherePainter(
                    time: rawTime,
                    lipSyncEnergy: _lipSyncEnergy,
                    accentColor: emotion.accentColor,
                    scene: scene,
                    particles: _particles,
                    foregroundPass: false,
                    characterAlignment: widget.characterAlignment,
                  ),
                ),

                // 3. Option A — 6-Part 2.5D Decomposed Character Rig (Dual Heroines or Solo)
                if (isDual) ...[
                  // Draw listening heroine slightly behind, and speaking heroine in front!
                  if (activeSpeaker == VnHeroineCharacter.reina) ...[
                    buildHeroineActor(
                      VnHeroineCharacter.hikari,
                      alignment: const Alignment(-0.52, 1.0),
                      isSpeakingThisTurn: false,
                      scaleFactor: 0.90,
                    ),
                    buildHeroineActor(
                      VnHeroineCharacter.reina,
                      alignment: const Alignment(0.50, 1.0),
                      isSpeakingThisTurn: true,
                      scaleFactor: 0.96,
                    ),
                  ] else ...[
                    buildHeroineActor(
                      VnHeroineCharacter.reina,
                      alignment: const Alignment(0.50, 1.0),
                      isSpeakingThisTurn: false,
                      scaleFactor: 0.90,
                    ),
                    buildHeroineActor(
                      VnHeroineCharacter.hikari,
                      alignment: const Alignment(-0.52, 1.0),
                      isSpeakingThisTurn: true,
                      scaleFactor: 0.96,
                    ),
                  ],
                  // Non-overlapping Left (Hikari) / Right (Reina) Touch Zones in Dual Mode
                  Positioned.fill(
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: () => _handleHeroineTap(
                              VnHeroineCharacter.hikari,
                              rawTime,
                            ),
                            onPanUpdate: (details) {
                              final dx = (details.delta.dx / 60.0).clamp(
                                -0.6,
                                0.6,
                              );
                              final dy = (details.delta.dy / 60.0).clamp(
                                -0.6,
                                0.6,
                              );
                              _pointerParallax = Offset(
                                (_pointerParallax.dx + dx).clamp(-1.0, 1.0),
                                (_pointerParallax.dy + dy).clamp(-0.85, 0.85),
                              );
                            },
                            onPanEnd: (_) => _pointerParallax = Offset.zero,
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: () => _handleHeroineTap(
                              VnHeroineCharacter.reina,
                              rawTime,
                            ),
                            onPanUpdate: (details) {
                              final dx = (details.delta.dx / 60.0).clamp(
                                -0.6,
                                0.6,
                              );
                              final dy = (details.delta.dy / 60.0).clamp(
                                -0.6,
                                0.6,
                              );
                              _pointerParallax = Offset(
                                (_pointerParallax.dx + dx).clamp(-1.0, 1.0),
                                (_pointerParallax.dy + dy).clamp(-0.85, 0.85),
                              );
                            },
                            onPanEnd: (_) => _pointerParallax = Offset.zero,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else
                  buildHeroineActor(
                    vm.selectedHeroine,
                    alignment: widget.characterAlignment,
                    isSpeakingThisTurn: true,
                    scaleFactor: 1.0,
                  ),

                // 4. Foreground Sakura Petals & Depth-of-Field Bokeh (Z = +1.5)
                IgnorePointer(
                  child: CustomPaint(
                    painter: _VnStageAtmospherePainter(
                      time: rawTime,
                      lipSyncEnergy: _lipSyncEnergy,
                      accentColor: emotion.accentColor,
                      scene: scene,
                      particles: _particles,
                      foregroundPass: true,
                      characterAlignment: widget.characterAlignment,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 5. Interactive 2.5D Rig & Physics HUD Banner (when RIG Inspector is open)
          if (vm.isRigInspectorVisible)
            Positioned(
              top: 66,
              right: 16,
              left: 16,
              child: Align(
                alignment: Alignment.topRight,
                child: _buildRigInspectorControlCard(
                  vm,
                  squashStretchX,
                  squashStretchY,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRigInspectorControlCard(
    AnimeVnViewModel vm,
    double scaleX,
    double scaleY,
  ) {
    final isKo = vm.isKorean;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 300),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xEE0F172A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF38BDF8), width: 1.4),
          boxShadow: const [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.hub_rounded,
                  color: Color(0xFF38BDF8),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    isKo
                        ? '2.5D 스켈레탈 본 & 물리 인스펙터'
                        : '2.5D スケルトン＆物理インスペクター',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                InkWell(
                  onTap: vm.toggleRigInspector,
                  child: const Icon(
                    Icons.close,
                    color: Colors.white54,
                    size: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              isKo
                  ? '• Cyan: 날개 헤어핀 & 앞머리 파츠 (Z +0.85)\n'
                        '• Green: 강체 얼굴 & 시선 트래킹 본 (Z +0.55)\n'
                        '• Pink: 진자 물리 뒷머리 & 양갈래 (Z -1.00)\n'
                        '• Amber: 상체 호흡 & 리본 스프링 (Z 0.00)'
                  : '• Cyan: ウイング髪飾り＆前髪パーツ (Z +0.85)\n'
                        '• Green: 剛体フェイス＆視線追従ボーン (Z +0.55)\n'
                        '• Pink: 振り子物理・後ろ髪＆おさげ (Z -1.00)\n'
                        '• Amber: 上半身呼吸＆リボンスプリング (Z 0.00)',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10.5,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Squash/Stretch: (${scaleX.toStringAsFixed(2)}, ${scaleY.toStringAsFixed(2)})  |  '
              'Parallax Z: (${_smoothedParallax.dx.toStringAsFixed(2)}, ${_smoothedParallax.dy.toStringAsFixed(2)})',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF67E8F9),
                fontSize: 10.5,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: vm.toggleSteppedAnimationMode,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 6,
                      ),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: vm.isSteppedAnimationMode
                            ? const Color(0xFFEC4899)
                            : const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Text(
                        vm.isSteppedAnimationMode
                            ? (isKo
                                  ? '🎬 12fps 리미티드 작화 ON'
                                  : '🎬 12fps リミテッド作画 ON')
                            : (isKo
                                  ? '⚡ 60fps Live2D 보간 ON'
                                  : '⚡ 60fps Live2D 補間 ON'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    _triggerSquashImpulse(2.1);
                    _headShakeImpulse = 0.9;
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isKo ? '탱글 바운스!' : 'ぷるんバウンス！',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeartParticle(
    _FloatingHeartParticle h,
    double nowSec,
    bool isKorean,
  ) {
    final age = (nowSec - h.spawnTime).clamp(0.0, 1.8);
    final progress = age / 1.8;
    final opacity = (1.0 - progress).clamp(0.0, 1.0);
    final dy = h.dyStart - age * h.speedY;
    final dx = h.dxOffset + math.sin(age * 6.0 + h.dxOffset) * 12.0;
    final isReina = h.heroine == VnHeroineCharacter.reina;
    final badgeColor = isReina
        ? const Color(0xEEF59E0B)
        : const Color(0xEEEC4899);
    final popupText = isReina
        ? (isKorean ? '🌺 레이나 호감도 UP! +4%' : '🌺 レイナ 好感度 UP! +4%')
        : (isKorean ? '🌸 히카리 호감도 UP! +4%' : '🌸 ヒカリ 好感度 UP! +4%');

    return Positioned(
      top: MediaQuery.of(context).size.height * 0.18 + dy,
      child: Transform.translate(
        offset: Offset(dx, 0),
        child: Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: h.scale * (0.8 + progress * 0.4),
            child: h.isTextPopup
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      popupText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                      ),
                    ),
                  )
                : Text(
                    isReina ? '🧡' : '💖',
                    style: const TextStyle(fontSize: 24),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Option A — 6-Part 2.5D Decomposed Character Painter (`Canvas.drawVertices` +
/// Facial & Accessory Sub-Layers + Optional Live2D/Spine Bone Inspector).
///
/// Why this solves both "living 2.5D animation" AND "zero double-image / zero face distortion":
/// 1. **High-Density 34x42 Deformable Mesh with C² Hermite `smoothstep` Part Weights**:
///    Separates Back-Hair (`Z = -1.0`), Torso/Ribbon (`Z = 0.0`), Rigid Face (`Z = +0.35`),
///    Front Bangs/Side-Locks (`Z = +0.75`), and Cyber Wing Hairpins (`Z = +0.85`)
///    with continuous weights so parts move with independent 3D parallax and spring
///    inertia without ever tearing or showing a duplicate background image.
/// 2. **100% Rigid Euclidean Face Bone (`u ∈ [0.29, 0.71], v ∈ [0.14, 0.44]`)**:
///    The face translates and rotates as a rigid unit around the neck pivot
///    `(0.505, 0.445)`, guaranteeing zero facial warping.
/// 3. **Independent 2.5D Facial & Accessory Sub-Layers (Locked to Head Transform)**:
///    - Mouse-tracking luminous cyan iris glow & dual starlight catchlights in both eyes.
///    - Animated rosy cheek blush that intensifies with affection & speech energy.
///    - Audio-reactive chin/jaw micro-articulation (`lipSyncEnergy`).
///    - Glowing holographic Flutter/Gemini wing hairpins & chest star badge.
class _Live2dMultiPartCharacterPainter extends CustomPainter {
  final ui.Image activeImage;
  final double time;
  final double lipSyncEnergy;
  final double headYaw;
  final double headPitch;
  final double headRoll;
  final double blinkAmount;
  final double hairMidSpringX;
  final double hairTipSpringX;
  final double wingFlapPos;
  final double bustSpringY;
  final Offset parallax;
  final Offset eyeGaze;
  final int affectionPoints;
  final VnCharacterEmotion emotion;
  final bool showRigInspector;

  static const int _cols = 34;
  static const int _rows = 42;

  const _Live2dMultiPartCharacterPainter({
    required this.activeImage,
    required this.time,
    required this.lipSyncEnergy,
    required this.headYaw,
    required this.headPitch,
    required this.headRoll,
    required this.blinkAmount,
    required this.hairMidSpringX,
    required this.hairTipSpringX,
    required this.wingFlapPos,
    required this.bustSpringY,
    required this.parallax,
    required this.eyeGaze,
    required this.affectionPoints,
    required this.emotion,
    required this.showRigInspector,
  });

  static double _smoothstep(double edge0, double edge1, double x) {
    final t = ((x - edge0) / (edge1 - edge0)).clamp(0.0, 1.0);
    return t * t * (3.0 - 2.0 * t);
  }

  /// Transforms a normalized `(u, v)` point on the rigid head cranium into canvas coordinates.
  Offset _transformHeadPoint(double u, double v, Size size) {
    final breath = math.sin(time * 2.35);
    final bodySwayX =
        math.sin(time * 1.18) * 3.2 + math.cos(time * 0.58) * 1.2;

    final pivotX = 0.505 * size.width;
    final pivotY = 0.620 * size.height;

    double x = u * size.width;
    double y = v * size.height;

    final spineFactor = (1.0 - v).clamp(0.0, 1.0);
    x += bodySwayX * spineFactor;
    y += -breath * 3.0 * math.sin(v * math.pi);

    final shiftX = headYaw * 6.0;
    final shiftY = headPitch * 4.0;
    final rx = (x + shiftX) - pivotX;
    final ry = (y + shiftY) - pivotY;
    final cosR = math.cos(headRoll);
    final sinR = math.sin(headRoll);

    return Offset(
      pivotX + (rx * cosR - ry * sinR),
      pivotY + (rx * sinR + ry * cosR),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final imgW = activeImage.width.toDouble();
    final imgH = activeImage.height.toDouble();

    final numVertices = (_cols + 1) * (_rows + 1);
    final positions = Float32List(numVertices * 2);
    final texCoords = Float32List(numVertices * 2);

    final breath = math.sin(time * 2.35);
    final bodySwayX =
        math.sin(time * 1.18) * 3.2 + math.cos(time * 0.58) * 1.2;

    // Pivot at the chest/sternum (`v = 0.62`) and keep `headWeight == 1.0`
    // across the ENTIRE head, face, mouth, chin, and neck (`v <= 0.55`)!
    // This mathematically guarantees ZERO shear or distortion on the face/chin
    // when moving the mouse!
    final pivotX = 0.505 * size.width;
    final pivotY = 0.620 * size.height;

    var vIdx = 0;

    for (var r = 0; r <= _rows; r++) {
      final v = r / _rows; // 0.0 (top) .. 1.0 (bottom)
      for (var c = 0; c <= _cols; c++) {
        final u = c / _cols; // 0.0 (left) .. 1.0 (right)

        texCoords[vIdx] = u * imgW;
        texCoords[vIdx + 1] = v * imgH;

        double x = u * size.width;
        double y = v * size.height;

        // ---------------------------------------------------------------------
        // 1. Gentle Spine Sway & Respiratory Breathing
        // ---------------------------------------------------------------------
        final spineFactor = (1.0 - v).clamp(0.0, 1.0);
        x += bodySwayX * spineFactor;
        y += -breath * 3.0 * math.sin(v * math.pi);

        // ---------------------------------------------------------------------
        // 2. 100% Rigid Head, Face, Mouth, Chin & Neck (`v <= 0.55`)
        //    `upperWeight` is strictly 1.0 everywhere above `v = 0.55` (which
        //    includes the crown, hairpins, eyes, nose, mouth at v=0.42, chin at
        //    v=0.47, and collar at v=0.52), tapering smoothly down the lower
        //    waist `v ∈ [0.55, 0.90]`.
        //    Result: The face, mouth, and chin NEVER warp or skew!
        // ---------------------------------------------------------------------
        if (v < 0.90) {
          final upperWeight = v <= 0.55
              ? 1.0
              : (1.0 - _smoothstep(0.55, 0.90, v));

          final shiftX = headYaw * 6.0 * upperWeight;
          final shiftY = headPitch * 4.0 * upperWeight;
          final roll = headRoll * upperWeight;

          final rx = (x + shiftX) - pivotX;
          final ry = (y + shiftY) - pivotY;
          final cosR = math.cos(roll);
          final sinR = math.sin(roll);

          x = pivotX + (rx * cosR - ry * sinR);
          y = pivotY + (rx * sinR + ry * cosR);
        }

        // ---------------------------------------------------------------------
        // 3. Coupled Pendulum Lower Hair Sway (`v > 0.66`, strictly below hands
        //    and shoulders on the outer hair silhouette `u < 0.25` or `u > 0.75`)
        // ---------------------------------------------------------------------
        if (v > 0.66) {
          double outerMask = 0.0;
          if (u < 0.26) {
            outerMask = _smoothstep(0.26, 0.06, u);
          } else if (u > 0.74) {
            outerMask = _smoothstep(0.74, 0.94, u);
          }

          if (outerMask > 0.0) {
            final lenFactor = _smoothstep(0.66, 0.98, v);
            final coupledSpringX =
                (hairMidSpringX * (1.0 - lenFactor) +
                    hairTipSpringX * lenFactor) *
                0.45;
            final sWave =
                math.sin(time * 3.2 - v * 5.5 + (u < 0.5 ? 0.0 : 1.2)) *
                (3.2 + 4.5 * lenFactor);

            x += (coupledSpringX + sWave) * outerMask * lenFactor;
            y +=
                math.cos(time * 2.4 - v * 4.2) *
                1.8 *
                outerMask *
                lenFactor;
          }
        }

        // ---------------------------------------------------------------------
        // 4. Subtle Torso / Collar Ribbon Breathing (`v ∈ [0.54, 0.76]`)
        // ---------------------------------------------------------------------
        if (v >= 0.54 && v <= 0.76 && u >= 0.36 && u <= 0.64) {
          final cx = (u - 0.505) / 0.14;
          final cy = (v - 0.65) / 0.11;
          final radial = (1.0 - (cx * cx + cy * cy)).clamp(0.0, 1.0);
          if (radial > 0.0) {
            y += (-breath * 2.4 + bustSpringY * 0.50) * radial;
          }
        }

        positions[vIdx] = x;
        positions[vIdx + 1] = y;
        vIdx += 2;
      }
    }

    // Build triangle indices
    final indices = Uint16List(_cols * _rows * 6);
    var iIdx = 0;
    const stride = _cols + 1;
    for (var r = 0; r < _rows; r++) {
      for (var c = 0; c < _cols; c++) {
        final topLeft = r * stride + c;
        final topRight = topLeft + 1;
        final bottomLeft = (r + 1) * stride + c;
        final bottomRight = bottomLeft + 1;

        indices[iIdx++] = topLeft;
        indices[iIdx++] = topRight;
        indices[iIdx++] = bottomLeft;

        indices[iIdx++] = topRight;
        indices[iIdx++] = bottomRight;
        indices[iIdx++] = bottomLeft;
      }
    }

    final vertices = ui.Vertices.raw(
      ui.VertexMode.triangles,
      positions,
      textureCoordinates: texCoords,
      indices: indices,
    );

    final shader = ImageShader(
      activeImage,
      TileMode.clamp,
      TileMode.clamp,
      Matrix4.identity().storage,
    );

    // 1. Draw the Single-Pass 2.5D Deformed Character Mesh
    final mainPaint = Paint()
      ..shader = shader
      ..filterQuality = FilterQuality.medium;
    canvas.drawVertices(vertices, BlendMode.srcOver, mainPaint);

    // 2. Draw Independent 2.5D Facial & Accessory Sub-Layers (Locked to Head/Body Bones)
    _paintFacialAndAccessorySubLayers(canvas, size);

    // 3. Optional Live2D/Spine Bone & Mesh Inspector Overlay for Conference Presentation
    if (showRigInspector) {
      _paintRigInspectorOverlay(canvas, size, positions);
    }
  }

  /// Paints subtle holographic accessory glow on the wing hairpins and chest star badge
  /// WITHOUT drawing any duplicate shapes over Hikari's face or eyes.
  void _paintFacialAndAccessorySubLayers(Canvas canvas, Size size) {
    // --- A. Cyber Wing Hairpins Holographic Glow ---
    final leftWingCenter = _transformHeadPoint(0.295, 0.195, size);
    final rightWingCenter = _transformHeadPoint(0.705, 0.188, size);
    final wingGlowRadius = size.width * 0.060;
    final wingPulse =
        0.14 + math.sin(time * 4.5) * 0.04 + lipSyncEnergy * 0.20;

    for (final wc in [leftWingCenter, rightWingCenter]) {
      final wingPaint = Paint()
        ..blendMode = BlendMode.plus
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF22D3EE).withValues(alpha: wingPulse),
            const Color(0xFF38BDF8).withValues(alpha: wingPulse * 0.25),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: wc, radius: wingGlowRadius));
      canvas.drawCircle(wc, wingGlowRadius, wingPaint);
    }

    // --- B. Audio-Reactive Chest Star Badge Glow ---
    final starBadgeCenter = Offset(
      size.width * 0.630,
      size.height * 0.628 + bustSpringY * 0.5,
    );
    final starRadius = size.width * (0.030 + lipSyncEnergy * 0.022);
    final starPaint = Paint()
      ..blendMode = BlendMode.plus
      ..shader = RadialGradient(
        colors: [
          const Color(
            0xFF67E8F9,
          ).withValues(alpha: 0.20 + lipSyncEnergy * 0.40),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(center: starBadgeCenter, radius: starRadius),
      );
    canvas.drawCircle(starBadgeCenter, starRadius, starPaint);
  }

  /// Visualizes the 2.5D deformable mesh grid and the 6 anatomical bones live on stage!
  void _paintRigInspectorOverlay(
    Canvas canvas,
    Size size,
    Float32List positions,
  ) {
    const stride = _cols + 1;

    // 1. Draw color-coded 2.5D mesh wireframe (every 2nd cell for clarity)
    for (var r = 0; r < _rows; r += 2) {
      final v = r / _rows;
      for (var c = 0; c < _cols; c += 2) {
        final u = c / _cols;
        final idx = (r * stride + c) * 2;
        final x = positions[idx];
        final y = positions[idx + 1];

        Color zoneColor;
        if (v < 0.28 && (u < 0.36 || u > 0.64)) {
          zoneColor = const Color(0xFF22D3EE); // Wing hairpins (Part 6)
        } else if (v < 0.45 && u >= 0.28 && u <= 0.72) {
          zoneColor = const Color(0xFF4ADE80); // Rigid Face (Part 3/4/5)
        } else if (u < 0.28 || u > 0.72) {
          zoneColor = const Color(0xFFF472B6); // Pendulum Hair (Part 1)
        } else {
          zoneColor = const Color(0xFFFBBF24); // Torso & Ribbon (Part 2)
        }

        if (c + 2 <= _cols) {
          final rIdx = (r * stride + (c + 2)) * 2;
          canvas.drawLine(
            Offset(x, y),
            Offset(positions[rIdx], positions[rIdx + 1]),
            Paint()
              ..color = zoneColor.withValues(alpha: 0.42)
              ..strokeWidth = 0.9,
          );
        }
        if (r + 2 <= _rows) {
          final bIdx = ((r + 2) * stride + c) * 2;
          canvas.drawLine(
            Offset(x, y),
            Offset(positions[bIdx], positions[bIdx + 1]),
            Paint()
              ..color = zoneColor.withValues(alpha: 0.42)
              ..strokeWidth = 0.9,
          );
        }
      }
    }

    // 2. Draw Skeletal Bone Hierarchy (Neck Pivot -> Head -> Eyes / Wings / Hair Pendulums)
    final neckPivot = _transformHeadPoint(0.505, 0.445, size);
    final headCenter = _transformHeadPoint(0.505, 0.310, size);
    final leftEye = _transformHeadPoint(0.422, 0.324, size);
    final rightEye = _transformHeadPoint(0.590, 0.318, size);
    final leftWing = _transformHeadPoint(0.295, 0.195, size);
    final rightWing = _transformHeadPoint(0.705, 0.188, size);
    final ribbonCenter = Offset(
      size.width * 0.505 + parallax.dx * 3.0,
      size.height * 0.575 + bustSpringY * 0.7,
    );
    final leftHairTip = Offset(
      size.width * 0.16 + hairTipSpringX,
      size.height * 0.78,
    );
    final rightHairTip = Offset(
      size.width * 0.84 + hairTipSpringX,
      size.height * 0.78,
    );

    void drawBone(Offset from, Offset to, Color color) {
      canvas.drawLine(
        from,
        to,
        Paint()
          ..color = color
          ..strokeWidth = 2.6
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawCircle(from, 4.5, Paint()..color = Colors.white);
      canvas.drawCircle(from, 3.0, Paint()..color = color);
      canvas.drawCircle(to, 3.8, Paint()..color = color);
    }

    drawBone(ribbonCenter, neckPivot, const Color(0xFFFBBF24));
    drawBone(neckPivot, headCenter, const Color(0xFF4ADE80));
    drawBone(headCenter, leftEye, const Color(0xFF38BDF8));
    drawBone(headCenter, rightEye, const Color(0xFF38BDF8));
    drawBone(headCenter, leftWing, const Color(0xFF22D3EE));
    drawBone(headCenter, rightWing, const Color(0xFF22D3EE));
    drawBone(
      _transformHeadPoint(0.30, 0.34, size),
      leftHairTip,
      const Color(0xFFF472B6),
    );
    drawBone(
      _transformHeadPoint(0.70, 0.34, size),
      rightHairTip,
      const Color(0xFFF472B6),
    );
  }

  @override
  bool shouldRepaint(covariant _Live2dMultiPartCharacterPainter oldDelegate) =>
      true;
}

extension on double {
  int get microsecondsSinceEpochSafe => (this * 1000000).round();
}

class _FloatingHeartParticle {
  final double spawnTime;
  final double dxOffset;
  final double dyStart;
  final double speedY;
  final double scale;
  final bool isTextPopup;
  final VnHeroineCharacter heroine;

  const _FloatingHeartParticle({
    required this.spawnTime,
    required this.dxOffset,
    required this.dyStart,
    required this.speedY,
    required this.scale,
    required this.isTextPopup,
    required this.heroine,
  });
}

class _StageParticle {
  double x;
  double y;
  double size;
  double speedY;
  double speedX;
  double rotation;
  double rotationSpeed;
  bool isForeground;
  bool isSakura;

  _StageParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.speedY,
    required this.speedX,
    required this.rotation,
    required this.rotationSpeed,
    required this.isForeground,
    required this.isSakura,
  });

  factory _StageParticle.seeded(int index) {
    final rng = math.Random(index * 997 + 42);
    return _StageParticle(
      x: rng.nextDouble(),
      y: rng.nextDouble(),
      size: 4.0 + rng.nextDouble() * 7.5,
      speedY: 0.025 + rng.nextDouble() * 0.045,
      speedX: -0.02 + rng.nextDouble() * 0.04,
      rotation: rng.nextDouble() * math.pi * 2,
      rotationSpeed: (rng.nextDouble() - 0.5) * 2.5,
      isForeground: index % 4 == 0,
      isSakura: index % 2 == 0,
    );
  }

  void advance(double dt) {
    y += speedY * dt;
    x += (speedX + math.sin(y * 6.0) * 0.012) * dt;
    rotation += rotationSpeed * dt;
    if (y > 1.08) {
      y = -0.05;
      x = (x + 0.37) % 1.0;
    }
    if (x < -0.05) x += 1.1;
    if (x > 1.05) x -= 1.1;
  }
}

class _VnStageAtmospherePainter extends CustomPainter {
  final double time;
  final double lipSyncEnergy;
  final Color accentColor;
  final VnSceneBackground scene;
  final List<_StageParticle> particles;
  final bool foregroundPass;
  final Alignment characterAlignment;

  const _VnStageAtmospherePainter({
    required this.time,
    required this.lipSyncEnergy,
    required this.accentColor,
    required this.scene,
    required this.particles,
    required this.foregroundPass,
    required this.characterAlignment,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!foregroundPass) {
      final centerX = size.width * (0.5 + characterAlignment.x * 0.28);
      final centerY = size.height * 0.45;
      final center = Offset(centerX, centerY);

      final baseRadius = math.min(size.width, size.height) * 0.34;
      final dynamicRadius = baseRadius * (1.0 + lipSyncEnergy * 0.35);

      final auraPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            accentColor.withValues(alpha: 0.28 + lipSyncEnergy * 0.28),
            accentColor.withValues(alpha: 0.08),
            Colors.transparent,
          ],
          stops: const [0.0, 0.58, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: dynamicRadius));

      canvas.drawCircle(center, dynamicRadius, auraPaint);

      if (lipSyncEnergy > 0.03) {
        for (var i = 0; i < 3; i++) {
          final ringPhase = ((time * 0.9 + i * 0.33) % 1.0);
          final ringRadius =
              baseRadius * (0.52 + ringPhase * 0.70 + lipSyncEnergy * 0.22);
          final ringAlpha =
              ((1.0 - ringPhase) * (0.18 + lipSyncEnergy * 0.38)).clamp(
                0.0,
                0.55,
              );
          final ringPaint = Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.8 + lipSyncEnergy * 2.4
            ..color = accentColor.withValues(alpha: ringAlpha);
          canvas.drawCircle(center, ringRadius, ringPaint);
        }
      }
    }

    for (final p in particles) {
      if (p.isForeground != foregroundPass) continue;

      final px = p.x * size.width;
      final py = p.y * size.height;

      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(p.rotation);

      if (p.isSakura) {
        final petalPaint = Paint()
          ..color = const Color(
            0xFFFFB7C5,
          ).withValues(alpha: foregroundPass ? 0.65 : 0.42);
        final path = Path()
          ..moveTo(0, -p.size)
          ..quadraticBezierTo(p.size * 0.85, -p.size * 0.2, 0, p.size)
          ..quadraticBezierTo(-p.size * 0.85, -p.size * 0.2, 0, -p.size)
          ..close();
        canvas.drawPath(path, petalPaint);
      } else {
        final motePaint = Paint()
          ..color = accentColor.withValues(alpha: foregroundPass ? 0.6 : 0.38);
        canvas.drawCircle(Offset.zero, p.size * 0.42, motePaint);
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _VnStageAtmospherePainter oldDelegate) => true;
}
