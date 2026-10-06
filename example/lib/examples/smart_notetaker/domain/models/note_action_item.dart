/// An extracted action item with checkbox state.
class NoteActionItem {
  final String title;
  bool isCompleted;

  NoteActionItem({required this.title, this.isCompleted = false});
}
