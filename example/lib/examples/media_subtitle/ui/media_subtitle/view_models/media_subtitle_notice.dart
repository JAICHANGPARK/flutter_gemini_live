/// Visual category of a transient notice; the view maps it to snackbar style.
enum MediaSubtitleNoticeKind {
  /// Default snackbar (framework default duration and colors).
  plain,

  /// Short (2s) confirmation, e.g. a video was loaded.
  brief,

  /// Red-accent error snackbar.
  error,

  /// Indigo 4s snackbar shown when playback starts in the browser.
  playing,
}

/// A one-shot message the view model asks the view to show (snackbar).
class MediaSubtitleNotice {
  final String message;
  final MediaSubtitleNoticeKind kind;

  const MediaSubtitleNotice(this.message, this.kind);
}
