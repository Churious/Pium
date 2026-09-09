import 'package:flutter_tts/flutter_tts.dart';

/// 한국어 TTS — speechRate 0.45, 중복 재생 방지
class TtsService {
  TtsService._();

  static final FlutterTts _tts = FlutterTts();
  static bool _ready = false;
  static Future<void> _queue = Future<void>.value();

  static Future<void> init() async {
    if (_ready) return;
    await _tts.setLanguage('ko-KR');
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);
    _ready = true;
  }

  static Future<void> speak(String text) async {
    await init();
    _queue = _queue.then((_) async {
      await _tts.stop();
      await _tts.speak(text);
    });
    await _queue;
  }
}

/// 기존 키오스크 코드 호환
class PiumTts {
  PiumTts._();
  static Future<void> init() => TtsService.init();
  static Future<void> speak(String text) => TtsService.speak(text);
}
