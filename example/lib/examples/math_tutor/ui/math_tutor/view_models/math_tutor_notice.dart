/// Visual category of a transient notice; the view maps it to icon + color.
enum MathTutorNoticeKind {
  keyOff,
  error,
  sync,
  cloudOff,
  camera,
  gallery,
  info,
  copy,
  success,
}

/// A one-shot message the view model asks the view to show (snackbar).
class MathTutorNotice {
  final String message;
  final MathTutorNoticeKind kind;

  const MathTutorNotice(this.message, this.kind);
}
