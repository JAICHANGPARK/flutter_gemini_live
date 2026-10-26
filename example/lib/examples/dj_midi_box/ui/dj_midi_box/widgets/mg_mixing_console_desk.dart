import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../domain/models/midi_knob_data.dart';
import '../view_models/dj_midi_box_view_model.dart';
import 'edit_knob_dialog.dart';

/// Authentic Yamaha MG12XU / MG16XU Hardware Analog/Digital Mixing Console Desk.
///
/// Features per-channel vertical strips with color-coded rotary potentiometers:
/// - GAIN (White cap, +20..+64 dB)
/// - COMP (Yellow cap, 0..10)
/// - 3-Band EQ: HIGH 10kHz, MID 2.5kHz, LOW 100Hz (Green caps, -15..+15 dB)
/// - AUX1 (Cyan cap, 0..10) & AUX2/FX (White cap, 0..10)
/// - PAN/BAL (Red-Orange cap, L..R)
/// - Illuminated Amber [ON] toggle switch
/// - Signature Cyan-Blue horizontal ribbed separator bar
/// - Vertical Channel Fader with Silver ribbed cap, PEAK LED, and 1-2 / ST / PFL routing switches
/// - Right-hand SPX Digital Multi-Effect Processor (2-digit 7-segment Amber LED) +
///   Stereo L/R 12-segment Master Level Meter + GROUP 1-2 (Black fader) & STEREO (Red fader) master bay.
class MgMixingConsoleDesk extends StatelessWidget {
  final DjMidiBoxViewModel viewModel;
  final List<int> knobIndices;

  const MgMixingConsoleDesk({
    super.key,
    required this.viewModel,
    required this.knobIndices,
  });

  @override
  Widget build(BuildContext context) {
    final vm = viewModel;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF101318),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF283242), width: 2),
        boxShadow: const [
          BoxShadow(
            color: Colors.black87,
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Chassis Side Rail with Hex Screws
                const _ChassisSideRail(),

                // 16 Vertical Hardware Channel Strips
                for (final index in knobIndices)
                  _MgChannelStrip(
                    channelNumber: index + 1,
                    data: vm.knobs[index],
                    rmsLevel: vm.isPlaying ? vm.rmsLevel : 0.0,
                    onFaderChanged: (v) => vm.onKnobChanged(index, v),
                    onToggleOn: () => vm.onKnobTapped(index),
                    onEditPrompt: () =>
                        showEditKnobDialog(context, vm, vm.knobs[index]),
                    onParamChanged: ({
                      gain,
                      comp,
                      high,
                      mid,
                      low,
                      aux1,
                      aux2,
                      pan,
                      groupAssigned,
                      stAssigned,
                      pflActive,
                    }) => vm.updateChannelParam(
                      index,
                      gain: gain,
                      comp: comp,
                      high: high,
                      mid: mid,
                      low: low,
                      aux1: aux1,
                      aux2: aux2,
                      pan: pan,
                      groupAssigned: groupAssigned,
                      stAssigned: stAssigned,
                      pflActive: pflActive,
                    ),
                  ),

                // Right-Hand Master Section (PHANTOM +48V, SPX 24 LED, Master VU, GROUP 1-2 & STEREO Faders)
                _MgMasterSection(viewModel: vm),

                // Right Chassis Side Rail with Hex Screws
                const _ChassisSideRail(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Individual Vertical Channel Strip (MG-Series)
// ============================================================================

class _MgChannelStrip extends StatelessWidget {
  final int channelNumber;
  final MidiKnobData data;
  final double rmsLevel;
  final ValueChanged<double> onFaderChanged;
  final VoidCallback onToggleOn;
  final VoidCallback onEditPrompt;
  final void Function({
    double? gain,
    double? comp,
    double? high,
    double? mid,
    double? low,
    double? aux1,
    double? aux2,
    double? pan,
    bool? groupAssigned,
    bool? stAssigned,
    bool? pflActive,
  }) onParamChanged;

  const _MgChannelStrip({
    required this.channelNumber,
    required this.data,
    required this.rmsLevel,
    required this.onFaderChanged,
    required this.onToggleOn,
    required this.onEditPrompt,
    required this.onParamChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isOn = data.weight > 0.02;
    final isPeak = isOn && (data.weight * (0.6 + rmsLevel * 0.6)) > 0.85;

    return Container(
      width: 72,
      decoration: const BoxDecoration(
        color: Color(0xFF14181F),
        border: Border(
          right: BorderSide(color: Color(0xFF0084D6), width: 1.4),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Stem Name / Input Jack Header (Tap/Long-press to edit stem prompt)
          GestureDetector(
            onTap: onEditPrompt,
            onLongPress: onEditPrompt,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
              decoration: const BoxDecoration(
                color: Color(0xFF0C0F14),
                border: Border(
                  bottom: BorderSide(color: Color(0xFF263040), width: 1),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'CH $channelNumber',
                    style: const TextStyle(
                      color: Color(0xFF0095FF),
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w900,
                      fontSize: 8.5,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    data.title.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isOn ? Colors.white : const Color(0xFF94A3B8),
                      fontWeight: FontWeight.w800,
                      fontSize: 8.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),

          // 1. GAIN Knob (White cap, +20..+64)
          _MgRotaryPot(
            label: 'GAIN',
            subLabelLeft: '+20',
            subLabelRight: '+64',
            value: data.gain,
            capColor: const Color(0xFFF1F5F9),
            pointerColor: const Color(0xFF0F172A),
            onChanged: (v) => onParamChanged(gain: v),
          ),

          // 2. COMP Knob (Yellow cap, 0..10)
          _MgRotaryPot(
            label: 'COMP',
            subLabelLeft: '0',
            subLabelRight: '10',
            value: data.comp,
            capColor: const Color(0xFFEAB308),
            onChanged: (v) => onParamChanged(comp: v),
          ),

          // Divider for 3-Band EQ
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            height: 0.8,
            color: const Color(0xFF283244),
          ),

          // 3. HIGH 10kHz EQ Knob (Green cap, -15..+15)
          _MgRotaryPot(
            label: 'HIGH',
            freqLabel: '10kHz',
            subLabelLeft: '-15',
            subLabelRight: '+15',
            value: data.high,
            capColor: const Color(0xFF00C853),
            centerDetent: true,
            onChanged: (v) => onParamChanged(high: v),
          ),

          // 4. MID 2.5kHz EQ Knob (Green cap, -15..+15)
          _MgRotaryPot(
            label: 'MID',
            freqLabel: '2.5kHz',
            subLabelLeft: '-15',
            subLabelRight: '+15',
            value: data.mid,
            capColor: const Color(0xFF00C853),
            centerDetent: true,
            onChanged: (v) => onParamChanged(mid: v),
          ),

          // 5. LOW 100Hz EQ Knob (Green cap, -15..+15)
          _MgRotaryPot(
            label: 'LOW',
            freqLabel: '100Hz',
            subLabelLeft: '-15',
            subLabelRight: '+15',
            value: data.low,
            capColor: const Color(0xFF00C853),
            centerDetent: true,
            onChanged: (v) => onParamChanged(low: v),
          ),

          Container(
            margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            height: 0.8,
            color: const Color(0xFF283244),
          ),

          // 6. AUX1 Knob (Cyan-Blue cap, 0..10)
          _MgRotaryPot(
            label: 'AUX1',
            subLabelLeft: '0',
            subLabelRight: '10',
            value: data.aux1,
            capColor: const Color(0xFF00B0FF),
            onChanged: (v) => onParamChanged(aux1: v),
          ),

          // 7. AUX2 / FX Knob (White cap, 0..10)
          _MgRotaryPot(
            label: 'AUX2/FX',
            subLabelLeft: '0',
            subLabelRight: '10',
            value: data.aux2,
            capColor: const Color(0xFFF8FAFC),
            pointerColor: const Color(0xFF0F172A),
            onChanged: (v) => onParamChanged(aux2: v),
          ),

          // 8. PAN Knob (Red-Orange cap, L..R)
          _MgRotaryPot(
            label: 'PAN',
            subLabelLeft: 'L',
            subLabelRight: 'R',
            value: data.pan,
            capColor: const Color(0xFFFF3D00),
            centerDetent: true,
            onChanged: (v) => onParamChanged(pan: v),
          ),

          const SizedBox(height: 4),

          // 9. Illuminated Amber Square [ON] Push Button
          _MgAmberOnButton(isOn: isOn, onTap: onToggleOn),

          const SizedBox(height: 5),

          // 10. Signature Yamaha Blue Horizontal Ribbed Band
          const _MgBlueRibbedBand(),

          const SizedBox(height: 5),

          // 11. Channel Fader Bay (PEAK LED + Vertical Fader + 1-2 / ST / PFL switches)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              children: [
                // PEAK LED row
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text(
                      'PEAK',
                      style: TextStyle(
                        color: Colors.white70,
                        fontFamily: 'monospace',
                        fontSize: 6.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isPeak
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF3B1219),
                        boxShadow: isPeak
                            ? const [
                                BoxShadow(
                                  color: Color(0xFFEF4444),
                                  blurRadius: 5,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
                const SizedBox(height: 2),

                // Fader Track + Routing Mini Push-Buttons (1-2, ST, PFL)
                SizedBox(
                  height: 132,
                  child: Row(
                    children: [
                      // Left Fader Track + Silver Ribbed Fader Cap
                      Expanded(
                        child: _MgVerticalFader(
                          value: data.weight,
                          capStyle: _MgFaderCapStyle.silverChannel,
                          onChanged: onFaderChanged,
                        ),
                      ),
                      const SizedBox(width: 2),
                      // Right Mini Routing Switches (1-2, ST, PFL)
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SizedBox(height: 8),
                          Column(
                            children: [
                              _MgMiniPushSwitch(
                                label: '1-2',
                                active: data.groupAssigned,
                                buttonColor: const Color(0xFF64748B),
                                onTap: () => onParamChanged(
                                  groupAssigned: !data.groupAssigned,
                                ),
                              ),
                              const SizedBox(height: 6),
                              _MgMiniPushSwitch(
                                label: 'ST',
                                active: data.stAssigned,
                                buttonColor: const Color(0xFFDC2626),
                                onTap: () => onParamChanged(
                                  stAssigned: !data.stAssigned,
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: _MgMiniPushSwitch(
                              label: 'PFL',
                              active: data.pflActive,
                              buttonColor: const Color(0xFF64748B),
                              onTap: () =>
                                  onParamChanged(pflActive: !data.pflActive),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),

          // 12. Bottom Silk-Screened Channel Number Scribble Strip
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 3),
            decoration: const BoxDecoration(
              color: Color(0xFF0B0E13),
              border: Border(
                top: BorderSide(color: Color(0xFF0084D6), width: 1.2),
              ),
            ),
            child: Column(
              children: [
                Text(
                  '$channelNumber',
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                ),
                Text(
                  data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isOn ? data.color : const Color(0xFF64748B),
                    fontSize: 7.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Right-Hand Master & SPX Digital Multi Effect Processor Section (MG16XU)
// ============================================================================

class _MgMasterSection extends StatelessWidget {
  final DjMidiBoxViewModel viewModel;

  const _MgMasterSection({required this.viewModel});

  static const List<String> _spxPresetsLeft = [
    '1 REV HALL 1',
    '2 REV HALL 2',
    '3 REV ROOM 1',
    '4 REV ROOM 2',
    '5 REV STAGE 1',
    '6 REV STAGE 2',
    '7 REV PLATE',
    '8 DRUM AMB',
    '9 EARLY REF',
    '10 GATE REVERB',
    '11 SINGLE DELAY',
    '12 DELAY',
  ];

  static const List<String> _spxPresetsRight = [
    '13 VOCAL ECHO',
    '14 KARAOKE',
    '15 PHASER',
    '16 FLANGER',
    '17 CHORUS 1',
    '18 CHORUS 2',
    '19 SYMPHONIC',
    '20 TREMOLO',
    '21 AUTO WAH',
    '22 RADIO VOICE',
    '23 DISTORTION',
    '24 PITCH CHANGE',
  ];

  @override
  Widget build(BuildContext context) {
    final vm = viewModel;
    final activeLevel = vm.isPlaying
        ? (vm.rmsLevel * vm.stereoMasterLevel).clamp(0.0, 1.0)
        : 0.0;
    final leftMeter = (activeLevel * 1.04).clamp(0.0, 1.0);
    final rightMeter = (activeLevel * 0.96).clamp(0.0, 1.0);

    return Container(
      width: 248,
      decoration: const BoxDecoration(
        color: Color(0xFF13171F),
        border: Border(
          left: BorderSide(color: Color(0xFF0084D6), width: 2.0),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Top Brand Silk-Screen + PHANTOM +48V Switch
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            color: const Color(0xFF0B0E14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MIXING CONSOLE',
                      style: TextStyle(
                        color: Colors.white54,
                        fontFamily: 'monospace',
                        fontSize: 7,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'MG16XU',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'monospace',
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                // PHANTOM +48V Red Switch Box
                GestureDetector(
                  onTap: vm.togglePhantom48v,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141923),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(
                        color: const Color(0xFF0084D6),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'PHANTOM +48V\nCH 1-16 MIC',
                          style: TextStyle(
                            color: Colors.white70,
                            fontFamily: 'monospace',
                            fontSize: 6.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: vm.phantom48v
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF3F151B),
                            boxShadow: vm.phantom48v
                                ? const [
                                    BoxShadow(
                                      color: Color(0xFFEF4444),
                                      blurRadius: 4,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          width: 11,
                          height: 9,
                          decoration: BoxDecoration(
                            color: vm.phantom48v
                                ? const Color(0xFFDC2626)
                                : const Color(0xFF7F1D1D),
                            borderRadius: BorderRadius.circular(1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. SPX Digital Multi Effect Processor + Stereo L/1 R/2 12-Segment LED Meter
          Padding(
            padding: const EdgeInsets.all(6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: SPX Digital Multi Effect Processor Unit
                Expanded(
                  flex: 6,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A0C10),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFF263042)),
                    ),
                    child: Column(
                      children: [
                        // 2-Digit Amber 7-Segment LED Display ("24")
                        GestureDetector(
                          onTap: vm.cycleSpxProgram,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF050608),
                              borderRadius: BorderRadius.circular(3),
                              border: Border.all(
                                color: const Color(0xFF1F2633),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                vm.spxProgram.toString().padLeft(2, '0'),
                                style: const TextStyle(
                                  color: Color(0xFFFF9800),
                                  fontFamily: 'monospace',
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 3,
                                  shadows: [
                                    Shadow(
                                      color: Color(0xFFFF6D00),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),

                        // 24 SPX Preset Silk-Screen Table
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: _spxPresetsLeft
                                    .map(
                                      (p) => Text(
                                        p,
                                        maxLines: 1,
                                        overflow: TextOverflow.clip,
                                        style: const TextStyle(
                                          color: Colors.white60,
                                          fontFamily: 'monospace',
                                          fontSize: 4.8,
                                          height: 1.25,
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: _spxPresetsRight
                                    .map(
                                      (p) => Text(
                                        p,
                                        maxLines: 1,
                                        overflow: TextOverflow.clip,
                                        style: const TextStyle(
                                          color: Colors.white60,
                                          fontFamily: 'monospace',
                                          fontSize: 4.8,
                                          height: 1.25,
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // PROGRAM Encoder + PARAMETER Potentiometer
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _MgRotaryPot(
                              label: 'PROGRAM',
                              subLabelLeft: '-',
                              subLabelRight: '+',
                              value: (vm.spxProgram - 1) / 23.0,
                              capColor: const Color(0xFF1E293B),
                              pointerColor: Colors.white70,
                              onChanged: (v) {
                                final target = (v * 23).round() + 1;
                                final delta = target - vm.spxProgram;
                                if (delta != 0) vm.cycleSpxProgram(delta);
                              },
                            ),
                            _MgRotaryPot(
                              label: 'PARAMETER',
                              subLabelLeft: 'MIN',
                              subLabelRight: 'MAX',
                              value: ((vm.guidance - 1.0) / 5.0).clamp(
                                0.0,
                                1.0,
                              ),
                              capColor: const Color(0xFFF8FAFC),
                              pointerColor: const Color(0xFF0F172A),
                              onChanged: (v) => vm.setGuidance(1.0 + v * 5.0),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),

                        // Brushed Silver SPX Badge
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF64748B), Color(0xFF94A3B8)],
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: const Text(
                            'SPX DIGITAL MULTI EFFECT',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF0F172A),
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w900,
                              fontSize: 5.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 5),

                // Right: POWER LED + 12-Segment Stereo L/1 R/2 Master Level Meter
                Expanded(
                  flex: 4,
                  child: _MgStereoMasterMeter(
                    isConnected: vm.isConnected,
                    isPlaying: vm.isPlaying,
                    leftLevel: leftMeter,
                    rightLevel: rightMeter,
                    pflActive: vm.knobs.any((k) => k.pflActive),
                  ),
                ),
              ],
            ),
          ),

          // 3. Blue-Framed SEND MASTER (AUX1, AUX2) & MONITOR / PHONES Section
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF0E1826),
              border: Border.all(color: const Color(0xFF0084D6), width: 1.5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    _MgRotaryPot(
                      label: 'AUX1',
                      subLabelLeft: '0',
                      subLabelRight: '10',
                      value: vm.density,
                      capColor: const Color(0xFF00B0FF),
                      onChanged: vm.setDensity,
                    ),
                    _MgRotaryPot(
                      label: 'AUX2',
                      subLabelLeft: '0',
                      subLabelRight: '10',
                      value: vm.brightness,
                      capColor: const Color(0xFF00B0FF),
                      onChanged: vm.setBrightness,
                    ),
                    const Text(
                      'SEND MASTER',
                      style: TextStyle(
                        color: Color(0xFF38BDF8),
                        fontFamily: 'monospace',
                        fontSize: 6.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 1,
                  height: 118,
                  color: const Color(0xFF0084D6),
                ),
                Column(
                  children: [
                    _MgRotaryPot(
                      label: 'MONITOR',
                      subLabelLeft: '0',
                      subLabelRight: '10',
                      value: vm.stereoMasterLevel,
                      capColor: const Color(0xFFF8FAFC),
                      pointerColor: const Color(0xFF0F172A),
                      onChanged: vm.setStereoMasterLevel,
                    ),
                    _MgRotaryPot(
                      label: 'PHONES',
                      subLabelLeft: '0',
                      subLabelRight: '10',
                      value: vm.groupBusLevel,
                      capColor: const Color(0xFFF8FAFC),
                      pointerColor: const Color(0xFF0F172A),
                      onChanged: vm.setGroupBusLevel,
                    ),
                    const Text(
                      'MONITOR',
                      style: TextStyle(
                        color: Color(0xFF38BDF8),
                        fontFamily: 'monospace',
                        fontSize: 6.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 5),

          // 4. Master Amber ON Buttons (GROUP 1-2 & STEREO ON/PLAY)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _MgAmberOnButton(
                isOn: !vm.muteBass,
                onTap: () => vm.setMuteBass(!vm.muteBass),
              ),
              _MgAmberOnButton(isOn: vm.isPlaying, onTap: vm.togglePlay),
            ],
          ),

          const SizedBox(height: 5),
          const _MgBlueRibbedBand(),
          const SizedBox(height: 5),

          // 5. Blue-Framed GROUP 1-2 (Black Fader Cap) & STEREO MASTER (Red Fader Cap)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF0E1B2E),
              border: Border.all(color: const Color(0xFF0084D6), width: 1.5),
            ),
            child: Row(
              children: [
                // GROUP 1-2 Black Fader
                Expanded(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 132,
                        child: _MgVerticalFader(
                          value: vm.groupBusLevel,
                          capStyle: _MgFaderCapStyle.blackGroup,
                          onChanged: vm.setGroupBusLevel,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'GROUP 1-2',
                        style: TextStyle(
                          color: Color(0xFF38BDF8),
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w900,
                          fontSize: 8.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1.2,
                  height: 150,
                  color: const Color(0xFF0084D6),
                ),
                // STEREO Master Red Fader
                Expanded(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 132,
                        child: _MgVerticalFader(
                          value: vm.stereoMasterLevel,
                          capStyle: _MgFaderCapStyle.redStereoMaster,
                          onChanged: vm.setStereoMasterLevel,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'STEREO',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w900,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ============================================================================
// Color-Coded Hardware Rotary Potentiometer (_MgRotaryPot)
// ============================================================================

class _MgRotaryPot extends StatelessWidget {
  final String label;
  final String? freqLabel;
  final String subLabelLeft;
  final String subLabelRight;
  final double value;
  final Color capColor;
  final Color pointerColor;
  final bool centerDetent;
  final ValueChanged<double> onChanged;

  const _MgRotaryPot({
    required this.label,
    this.freqLabel,
    required this.subLabelLeft,
    required this.subLabelRight,
    required this.value,
    required this.capColor,
    this.pointerColor = Colors.white,
    this.centerDetent = false,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: () => onChanged(0.5),
      onVerticalDragUpdate: (details) {
        final delta = -details.primaryDelta! / 75.0;
        onChanged((value + delta).clamp(0.0, 1.0));
      },
      child: SizedBox(
        width: 54,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 1.5, horizontal: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Silk-Screen Label + Optional Frequency
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'monospace',
                        fontSize: 6.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  if (freqLabel != null)
                    Text(
                      freqLabel!,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontFamily: 'monospace',
                        fontSize: 5.8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
              // Potentiometer Dial with Radial White Scale Ticks
              SizedBox(
                width: 38,
                height: 34,
                child: CustomPaint(
                  painter: _MgPotPainter(
                    value: value.clamp(0.0, 1.0),
                    capColor: capColor,
                    pointerColor: pointerColor,
                    centerDetent: centerDetent,
                  ),
                ),
              ),
              // Min / Max Silk-Screen Sub-labels
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      subLabelLeft,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontFamily: 'monospace',
                        fontSize: 5.8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subLabelRight,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontFamily: 'monospace',
                        fontSize: 5.8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MgPotPainter extends CustomPainter {
  final double value;
  final Color capColor;
  final Color pointerColor;
  final bool centerDetent;

  const _MgPotPainter({
    required this.value,
    required this.capColor,
    required this.pointerColor,
    required this.centerDetent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 1);
    final radius = math.min(size.width, size.height) / 2;

    const startAngle = 135.0 * (math.pi / 180.0);
    const totalSweep = 270.0 * (math.pi / 180.0);
    final currentAngle = startAngle + totalSweep * value;

    // 1. White Silk-Screened Radial Calibration Ticks (11 ticks)
    const tickCount = 11;
    for (var i = 0; i < tickCount; i++) {
      final t = i / (tickCount - 1);
      final angle = startAngle + totalSweep * t;
      final isMajor = i == 0 || (centerDetent && i == 5) || i == tickCount - 1;

      final r1 = radius * (isMajor ? 0.72 : 0.78);
      final r2 = radius * 0.96;

      canvas.drawLine(
        Offset(
          center.dx + r1 * math.cos(angle),
          center.dy + r1 * math.sin(angle),
        ),
        Offset(
          center.dx + r2 * math.cos(angle),
          center.dy + r2 * math.sin(angle),
        ),
        Paint()
          ..color = isMajor ? Colors.white : Colors.white70
          ..strokeWidth = isMajor ? 1.3 : 0.85,
      );
    }

    // 2. Dark Fluted Potentiometer Skirt
    final skirtRadius = radius * 0.66;
    canvas.drawCircle(
      center.translate(0, 1.5),
      skirtRadius,
      Paint()..color = Colors.black87,
    );
    canvas.drawCircle(
      center,
      skirtRadius,
      Paint()..color = const Color(0xFF1A1E26),
    );
    canvas.drawCircle(
      center,
      skirtRadius,
      Paint()
        ..color = Colors.white24
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );

    // 3. Colored Center Cap (Green / Cyan / Yellow / Red / White)
    final capRadius = radius * 0.46;
    canvas.drawCircle(center, capRadius, Paint()..color = capColor);

    // 4. Pointer Line extending from center to skirt edge
    final p1 = Offset(
      center.dx + (capRadius * 0.15) * math.cos(currentAngle),
      center.dy + (capRadius * 0.15) * math.sin(currentAngle),
    );
    final p2 = Offset(
      center.dx + (skirtRadius * 0.92) * math.cos(currentAngle),
      center.dy + (skirtRadius * 0.92) * math.sin(currentAngle),
    );
    canvas.drawLine(
      p1,
      p2,
      Paint()
        ..color = pointerColor
        ..strokeWidth = 1.9
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _MgPotPainter oldDelegate) {
    return oldDelegate.value != value || oldDelegate.capColor != capColor;
  }
}

// ============================================================================
// Illuminated Amber Square [ON] Push Button
// ============================================================================

class _MgAmberOnButton extends StatelessWidget {
  final bool isOn;
  final VoidCallback onTap;

  const _MgAmberOnButton({required this.isOn, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 34,
        height: 24,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isOn
                ? const [
                    Color(0xFFFFD54F),
                    Color(0xFFFFB300),
                    Color(0xFFFF8F00),
                  ]
                : const [Color(0xFF3A342A), Color(0xFF24201A)],
          ),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: isOn ? const Color(0xFFFFE082) : const Color(0xFF475569),
            width: 1.2,
          ),
          boxShadow: isOn
              ? const [
                  BoxShadow(
                    color: Color(0xAAFFB300),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : const [
                  BoxShadow(
                    color: Colors.black87,
                    blurRadius: 3,
                    offset: Offset(0, 1.5),
                  ),
                ],
        ),
        child: Center(
          child: Text(
            'ON',
            style: TextStyle(
              color: isOn ? const Color(0xFF1E1300) : Colors.white54,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w900,
              fontSize: 8.5,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Signature Cyan-Blue Horizontal Ribbed Strip
// ============================================================================

class _MgBlueRibbedBand extends StatelessWidget {
  const _MgBlueRibbedBand();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 2),
      color: const Color(0xFF0B192C),
      child: Column(
        children: List.generate(
          4,
          (_) => Container(
            height: 1.2,
            margin: const EdgeInsets.symmetric(vertical: 0.9),
            color: const Color(0xFF0084D6),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Vertical Channel / Group / Stereo Master Fader with Sculpted Ribbed Cap
// ============================================================================

enum _MgFaderCapStyle { silverChannel, blackGroup, redStereoMaster }

class _MgVerticalFader extends StatelessWidget {
  final double value;
  final _MgFaderCapStyle capStyle;
  final ValueChanged<double> onChanged;

  const _MgVerticalFader({
    required this.value,
    required this.capStyle,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        final delta = -details.primaryDelta! / 110.0;
        onChanged((clamped + delta).clamp(0.0, 1.0));
      },
      onTapDown: (details) {
        final next = (1.0 - (details.localPosition.dy / 132.0)).clamp(0.0, 1.0);
        onChanged(next);
      },
      child: SizedBox(
        width: double.infinity,
        height: 132,
        child: CustomPaint(
          painter: _MgFaderPainter(value: clamped, capStyle: capStyle),
        ),
      ),
    );
  }
}

class _MgFaderPainter extends CustomPainter {
  final double value;
  final _MgFaderCapStyle capStyle;

  const _MgFaderPainter({required this.value, required this.capStyle});

  static const List<String> _scaleLabels = [
    '10',
    '5',
    '0',
    '5',
    '10',
    '15',
    '20',
    '25',
    '30',
    '∞',
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final slotX = size.width * 0.56;
    const topY = 10.0;
    final bottomY = size.height - 12.0;
    final trackH = bottomY - topY;

    // 1. Silk-Screened White dB Scale Numbers & Graduation Lines
    for (var i = 0; i <= 18; i++) {
      final t = i / 18.0;
      final y = topY + trackH * t;
      final isMajor = i % 2 == 0;
      final tickPaint = Paint()
        ..color = isMajor ? Colors.white70 : Colors.white38
        ..strokeWidth = isMajor ? 1.1 : 0.7;

      // Left tick
      canvas.drawLine(
        Offset(slotX - (isMajor ? 10 : 6), y),
        Offset(slotX - 3, y),
        tickPaint,
      );
      // Right tick
      canvas.drawLine(
        Offset(slotX + 3, y),
        Offset(slotX + (isMajor ? 9 : 5), y),
        tickPaint,
      );

      if (isMajor) {
        final labelIdx = i ~/ 2;
        if (labelIdx < _scaleLabels.length) {
          final tp = TextPainter(
            text: TextSpan(
              text: _scaleLabels[labelIdx],
              style: const TextStyle(
                color: Colors.white70,
                fontFamily: 'monospace',
                fontSize: 6.2,
                fontWeight: FontWeight.bold,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          tp.paint(canvas, Offset(2, y - tp.height / 2));
        }
      }
    }

    // 2. Vertical Dark Recessed Fader Slot
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(slotX, size.height / 2),
          width: 4.0,
          height: trackH + 6,
        ),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFF040609),
    );

    // 3. Sculpted Ribbed Hardware Fader Cap (Silver / Black / Red)
    final capY = bottomY - trackH * value;
    final capRect = Rect.fromCenter(
      center: Offset(slotX, capY),
      width: 20,
      height: 26,
    );
    final capRRect = RRect.fromRectAndRadius(
      capRect,
      const Radius.circular(2.5),
    );

    // Drop Shadow
    canvas.drawRRect(
      capRRect.shift(const Offset(0, 2.5)),
      Paint()..color = Colors.black87,
    );

    final List<Color> gradientColors = switch (capStyle) {
      _MgFaderCapStyle.silverChannel => const [
        Color(0xFFF8FAFC),
        Color(0xFFCBD5E1),
        Color(0xFF94A3B8),
        Color(0xFFE2E8F0),
      ],
      _MgFaderCapStyle.blackGroup => const [
        Color(0xFF475569),
        Color(0xFF1E293B),
        Color(0xFF0F172A),
        Color(0xFF334155),
      ],
      _MgFaderCapStyle.redStereoMaster => const [
        Color(0xFFEF4444),
        Color(0xFFDC2626),
        Color(0xFF991B1B),
        Color(0xFFB91C1C),
      ],
    };

    canvas.drawRRect(
      capRRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: gradientColors,
        ).createShader(capRect),
    );

    // Ribbed Grip Grooves on the Fader Cap
    final ribPaint = Paint()
      ..color = Colors.black.withAlpha(75)
      ..strokeWidth = 0.9;
    for (final dy in [-7.0, -4.5, 4.5, 7.0]) {
      canvas.drawLine(
        Offset(capRect.left + 2, capY + dy),
        Offset(capRect.right - 2, capY + dy),
        ribPaint,
      );
    }

    // Center Fader Reference Line (Black on Silver, Red on Black, White on Red)
    final lineColor = switch (capStyle) {
      _MgFaderCapStyle.silverChannel => const Color(0xFF0F172A),
      _MgFaderCapStyle.blackGroup => const Color(0xFFEF4444),
      _MgFaderCapStyle.redStereoMaster => Colors.white,
    };
    canvas.drawLine(
      Offset(capRect.left + 1.5, capY),
      Offset(capRect.right - 1.5, capY),
      Paint()
        ..color = lineColor
        ..strokeWidth = 2.0,
    );
  }

  @override
  bool shouldRepaint(covariant _MgFaderPainter oldDelegate) {
    return oldDelegate.value != value || oldDelegate.capStyle != capStyle;
  }
}

// ============================================================================
// Routing Mini Push-Switch (1-2, ST, PFL)
// ============================================================================

class _MgMiniPushSwitch extends StatelessWidget {
  final String label;
  final bool active;
  final Color buttonColor;
  final VoidCallback onTap;

  const _MgMiniPushSwitch({
    required this.label,
    required this.active,
    required this.buttonColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 14,
            height: 12,
            decoration: BoxDecoration(
              color: active ? buttonColor : buttonColor.withAlpha(110),
              borderRadius: BorderRadius.circular(1.5),
              border: Border.all(
                color: active ? Colors.white70 : Colors.black87,
                width: 0.8,
              ),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: buttonColor.withAlpha(140),
                        blurRadius: 3,
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : Colors.white60,
              fontFamily: 'monospace',
              fontSize: 6.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 12-Segment Stereo L/1 R/2 Master Level Meter (MG12XU / MG16XU)
// ============================================================================

class _MgStereoMasterMeter extends StatelessWidget {
  final bool isConnected;
  final bool isPlaying;
  final double leftLevel;
  final double rightLevel;
  final bool pflActive;

  const _MgStereoMasterMeter({
    required this.isConnected,
    required this.isPlaying,
    required this.leftLevel,
    required this.rightLevel,
    required this.pflActive,
  });

  static const List<String> _meterDbLabels = [
    'PEAK',
    '+10',
    '+6',
    '+3',
    '0',
    '-3',
    '-6',
    '-10',
    '-15',
    '-20',
    '-25',
    '-30',
  ];

  @override
  Widget build(BuildContext context) {
    const totalSegs = 12;
    final activeL = (leftLevel * totalSegs).round();
    final activeR = (rightLevel * totalSegs).round();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0D12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF222B3A)),
      ),
      child: Column(
        children: [
          // POWER LED Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'POWER',
                style: TextStyle(
                  color: Colors.white70,
                  fontFamily: 'monospace',
                  fontSize: 6.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 10,
                height: 4,
                decoration: BoxDecoration(
                  color: isConnected || isPlaying
                      ? Colors.white
                      : const Color(0xFF475569),
                  borderRadius: BorderRadius.circular(1),
                  boxShadow: isConnected || isPlaying
                      ? const [BoxShadow(color: Colors.white, blurRadius: 5)]
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // 12-Row L / Scale / R LED Ladder
          ...List.generate(totalSegs, (idx) {
            final segFromBottom = totalSegs - 1 - idx;
            final isLitL = segFromBottom < activeL;
            final isLitR = segFromBottom < activeR;

            final Color segColor;
            if (idx <= 2) {
              segColor = const Color(0xFFEF4444); // PEAK, +10, +6 Red
            } else if (idx <= 4) {
              segColor = const Color(0xFFF59E0B); // +3, 0 Amber
            } else {
              segColor = const Color(0xFF10B981); // -3 .. -30 Green
            }

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 1.6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildLedSegment(isLitL, segColor),
                  Expanded(
                    child: Text(
                      _meterDbLabels[idx],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: idx == 4 ? Colors.amberAccent : Colors.white60,
                        fontFamily: 'monospace',
                        fontSize: 5.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildLedSegment(isLitR, segColor),
                ],
              ),
            );
          }),

          const SizedBox(height: 4),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'L/1',
                style: TextStyle(
                  color: Colors.white70,
                  fontFamily: 'monospace',
                  fontSize: 6.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'R/2',
                style: TextStyle(
                  color: Colors.white70,
                  fontFamily: 'monospace',
                  fontSize: 6.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // PFL Indicator
          Container(
            width: 14,
            height: 4,
            decoration: BoxDecoration(
              color: pflActive
                  ? const Color(0xFFF59E0B)
                  : const Color(0xFF28241C),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(height: 1),
          const Text(
            'PFL',
            style: TextStyle(
              color: Colors.white54,
              fontFamily: 'monospace',
              fontSize: 6.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLedSegment(bool isLit, Color color) {
    return Container(
      width: 13,
      height: 4.5,
      decoration: BoxDecoration(
        color: isLit ? color : color.withAlpha(35),
        borderRadius: BorderRadius.circular(0.8),
        boxShadow: isLit
            ? [BoxShadow(color: color.withAlpha(180), blurRadius: 3)]
            : null,
      ),
    );
  }
}

// ============================================================================
// Chassis Side Rail with Phillips/Hex Rack Screws
// ============================================================================

class _ChassisSideRail extends StatelessWidget {
  const _ChassisSideRail();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 670,
      color: const Color(0xFF0B0D12),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _RackScrew(),
          _RackScrew(),
          _RackScrew(),
          _RackScrew(),
        ],
      ),
    );
  }
}

class _RackScrew extends StatelessWidget {
  const _RackScrew();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF475569), Color(0xFF1E293B)],
        ),
        border: Border.all(color: Colors.black, width: 1),
      ),
      child: Center(
        child: Container(width: 5, height: 1.2, color: Colors.black87),
      ),
    );
  }
}
