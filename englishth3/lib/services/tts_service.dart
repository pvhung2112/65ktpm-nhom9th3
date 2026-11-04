import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:web/web.dart' as web;

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();

  /// Đọc câu tiếng Anh mẫu với âm lượng to và phát âm bản xứ chuẩn
  Future<void> speakNative(String text) async {
    if (text.trim().isEmpty) return;

    if (kIsWeb) {
      try {
        // Hủy bất kỳ đoạn đọc nào trước đó
        web.window.speechSynthesis.cancel();

        final utterance = web.SpeechSynthesisUtterance(text);
        utterance.lang = 'en-US';
        utterance.volume = 1.0; // Âm lượng 100% to rõ ràng
        utterance.rate = 0.82;   // Tốc độ chuẩn sư phạm, phát âm từng âm tiết sắc nét
        utterance.pitch = 1.0;

        web.window.speechSynthesis.speak(utterance);
        debugPrint('[TTS] Đang phát âm bản xứ qua Web SpeechSynthesis: "$text"');
        return;
      } catch (e) {
        debugPrint('[TTS Web] Lỗi SpeechSynthesis, chuyển sang AudioPlayer: $e');
      }
    }

    // Fallback cho Desktop / Mobile bằng AudioPlayer với audio chất lượng cao
    try {
      final encoded = Uri.encodeComponent(text);
      final url = 'https://translate.google.com/translate_tts?ie=UTF-8&tl=en-US&client=tw-ob&q=$encoded';
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.play(UrlSource(url));
      debugPrint('[TTS AudioPlayer] Đang phát audio: $url');
    } catch (e) {
      debugPrint('[TTS AudioPlayer] Error: $e');
    }
  }

  void stop() {
    if (kIsWeb) {
      try {
        web.window.speechSynthesis.cancel();
      } catch (_) {}
    }
    _audioPlayer.stop();
  }
}

