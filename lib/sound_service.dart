import 'package:audioplayers/audioplayers.dart';

class SoundService {

  static final AudioPlayer _player = AudioPlayer();

  static Future<void> playDangerSound() async {
  await _player.setReleaseMode(ReleaseMode.loop);
  await _player.play(AssetSource('sounds/siren.mp3'));
}

  static Future<void> stopDangerSound() async {
    await _player.stop();
  }

}