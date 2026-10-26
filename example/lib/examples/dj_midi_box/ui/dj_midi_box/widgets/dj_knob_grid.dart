import 'package:flutter/material.dart';

import '../dj_midi_box_i18n.dart';
import '../view_models/dj_midi_box_view_model.dart';
import 'edit_knob_dialog.dart';
import 'midi_knob_widget.dart';

class DjKnobGrid extends StatelessWidget {
  final DjMidiBoxViewModel viewModel;
  final List<int> knobIndices;
  final int crossAxisCount;
  final double maxWidth;

  const DjKnobGrid({
    super.key,
    required this.viewModel,
    required this.knobIndices,
    required this.crossAxisCount,
    this.maxWidth = 680,
  });

  @override
  Widget build(BuildContext context) {
    final vm = viewModel;
    final i18n = DjMidiBoxI18n.current;
    final activeCount = knobIndices
        .where((idx) => vm.knobs[idx].weight > 0.02)
        .length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final hasBoundedHeight = constraints.hasBoundedHeight;

        final gridWidget = GridView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: hasBoundedHeight
              ? const BouncingScrollPhysics()
              : const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.78,
          ),
          itemCount: knobIndices.length,
          itemBuilder: (context, i) {
            final index = knobIndices[i];
            final knob = vm.knobs[index];
            return MidiKnobWidget(
              channelNumber: index + 1,
              data: knob,
              rmsLevel: vm.isPlaying ? vm.rmsLevel : 0.0,
              onChanged: (newVal) => vm.onKnobChanged(index, newVal),
              onTap: () => vm.onKnobTapped(index),
              onLongPress: () => showEditKnobDialog(context, vm, knob),
            );
          },
        );

        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1A1F2B), // Brushed gunmetal top bezel
                  Color(0xFF11151E), // Dark anodized mixer body
                  Color(0xFF0C0F16), // Deep chassis shadow
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2D3648), width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black87,
                  blurRadius: 14,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Hardware Faceplate Silk-Screen & Corner Hex Screws
                Row(
                  children: [
                    const _HardwareScrew(),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        i18n.matrixSectionLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w900,
                          fontSize: 9.5,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF090C12),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFF283244)),
                      ),
                      child: Text(
                        'ON $activeCount/${knobIndices.length}',
                        style: TextStyle(
                          color: activeCount > 0
                              ? const Color(0xFF10B981)
                              : const Color(0xFF64748B),
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          fontSize: 9,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const _HardwareScrew(),
                  ],
                ),
                const SizedBox(height: 6),

                // Silk-screened divider rule
                Container(height: 1, color: const Color(0xFF252D3D)),
                const SizedBox(height: 8),

                // 16-Channel Rotary Strip Matrix
                if (hasBoundedHeight)
                  Flexible(child: gridWidget)
                else
                  gridWidget,

                const SizedBox(height: 6),
                // Bottom Faceplate Screw Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const _HardwareScrew(),
                    Flexible(
                      child: Text(
                        'DIRECT BALANCED SUMMING BUS // ±18V ANALOG HEADROOM',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withAlpha(55),
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          fontSize: 8,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    const _HardwareScrew(),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HardwareScrew extends StatelessWidget {
  const _HardwareScrew();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF475569), Color(0xFF1E293B)],
        ),
        border: Border.all(color: const Color(0xFF0F172A), width: 1),
      ),
      child: Center(
        child: Container(
          width: 4.5,
          height: 1.2,
          color: const Color(0xFF090D16),
        ),
      ),
    );
  }
}
