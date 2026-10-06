/// Connection / playback status shown under the connection card.
///
/// The colour for each status is chosen by the view.
enum MusicStudioStatus {
  disconnected('Disconnected'),
  connecting('Connecting to Lyria...'),
  connected('Connected (Ready)'),
  failed('Connection failed'),
  streaming('Streaming Audio'),
  paused('Paused'),
  stopped('Stopped (Context Reset)');

  const MusicStudioStatus(this.text);

  final String text;
}
