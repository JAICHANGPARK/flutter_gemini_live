/// Immutable state holder for real-time audio & voice activity.
/// Used with [ValueNotifier] to completely avoid full-page [setState] calls.
class AudioActivity {
  const AudioActivity({
    this.isAiResponding = false,
    this.isUserSpeaking = false,
    this.userMicVolume = 0.0,
  });

  final bool isAiResponding;
  final bool isUserSpeaking;
  final double userMicVolume;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AudioActivity &&
          runtimeType == other.runtimeType &&
          isAiResponding == other.isAiResponding &&
          isUserSpeaking == other.isUserSpeaking &&
          (userMicVolume - other.userMicVolume).abs() < 0.005;

  @override
  int get hashCode => Object.hash(
    isAiResponding,
    isUserSpeaking,
    (userMicVolume * 100).round(),
  );
}
