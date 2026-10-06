import 'package:flutter/material.dart';

import '../view_models/smart_notetaker_view_model.dart';

/// Action item checklist.
///
/// Intentionally reads the view model without listening to it: the original
/// page rebuilt this panel only when its parent rebuilt (so the copy shown in
/// the modal bottom sheet is a snapshot that does not refresh on toggles).
class ActionItemsPanel extends StatelessWidget {
  const ActionItemsPanel({super.key, required this.viewModel});

  final SmartNotetakerViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final actionItems = viewModel.actionItems;

    return Container(
      color: const Color(0xFF131B2E),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.checklist_rtl_rounded,
                color: Colors.cyanAccent,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                '액션 아이템 & 할 일 체크리스트',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              Text(
                '${actionItems.where((a) => a.isCompleted).length} / ${actionItems.length} 완료',
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: actionItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.task_alt_rounded,
                          size: 40,
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '감지된 액션 아이템이 없습니다.\n회의 중 과제나 할 일이 언급되면 자동 추가됩니다.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: actionItems.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = actionItems[index];
                      return CheckboxListTile(
                        value: item.isCompleted,
                        title: Text(
                          item.title,
                          style: TextStyle(
                            color: item.isCompleted
                                ? Colors.white38
                                : Colors.white,
                            decoration: item.isCompleted
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                            fontSize: 13,
                          ),
                        ),
                        activeColor: Colors.cyanAccent,
                        checkColor: Colors.black,
                        tileColor: const Color(0xFF0F172A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        onChanged: (val) {
                          viewModel.setActionItemCompleted(item, val);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
