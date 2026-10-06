/// Visual category of a transient notice; the view maps it to color/duration.
enum ProDjConsoleNoticeKind { connected, error, hardDrop }

/// A one-shot message the view model asks the view to show (snackbar).
class ProDjConsoleNotice {
  final String message;
  final ProDjConsoleNoticeKind kind;

  const ProDjConsoleNotice(this.message, this.kind);
}
