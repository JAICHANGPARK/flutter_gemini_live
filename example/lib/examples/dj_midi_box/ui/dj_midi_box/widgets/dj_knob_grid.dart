import 'package:flutter/material.dart';

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
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const BouncingScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 18,
            crossAxisSpacing: 18,
            childAspectRatio: 0.82,
          ),
          itemCount: knobIndices.length,
          itemBuilder: (context, i) {
            final index = knobIndices[i];
            final knob = vm.knobs[index];
            return MidiKnobWidget(
              data: knob,
              rmsLevel: vm.isPlaying ? vm.rmsLevel : 0.0,
              onChanged: (newVal) => vm.onKnobChanged(index, newVal),
              onTap: () => vm.onKnobTapped(index),
              onLongPress: () => showEditKnobDialog(context, vm, knob),
            );
          },
        ),
      ),
    );
  }
}
