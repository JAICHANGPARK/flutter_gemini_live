/// What kind of transient message the view model wants the screen to show.
enum VisionCallNoticeKind {
  /// Plain text snackbar.
  info,

  /// Floating "camera flip on/off" snackbar with an icon.
  cameraFlip,
}

class VisionCallNotice {
  const VisionCallNotice(this.message, this.kind, {this.flipped = false});

  final String message;
  final VisionCallNoticeKind kind;

  /// Only meaningful for [VisionCallNoticeKind.cameraFlip].
  final bool flipped;
}
