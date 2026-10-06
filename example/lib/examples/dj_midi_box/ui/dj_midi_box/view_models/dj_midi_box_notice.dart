/// Visual category of a transient notice; the view maps it to a snackbar.
enum DjMidiBoxNoticeKind { connected, connectionFailed }

/// A one-shot message the view model asks the view to show (snackbar).
class DjMidiBoxNotice {
  final String message;
  final DjMidiBoxNoticeKind kind;

  const DjMidiBoxNotice(this.message, this.kind);
}
