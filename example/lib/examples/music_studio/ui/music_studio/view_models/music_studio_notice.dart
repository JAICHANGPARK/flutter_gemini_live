/// A transient message (snackbar) the view model asks the view to show.
class MusicStudioNotice {
  const MusicStudioNotice(this.message, {this.duration});

  final String message;

  /// `null` keeps the default snackbar duration.
  final Duration? duration;
}
