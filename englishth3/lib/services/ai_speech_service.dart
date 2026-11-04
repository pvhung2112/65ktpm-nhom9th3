import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/pronunciation_result.dart';

/// Dịch vụ kết nối trực tiếp mô hình AI mã nguồn mở (OpenAI Faster-Whisper & NLTK CMUdict)
/// Xử lý qua REST API và WebSocket Real-time Streaming, tương thích hoàn toàn 100% môi trường Web.
class AiSpeechService {
  static final AiSpeechService _instance = AiSpeechService._internal();
  factory AiSpeechService() => _instance;
  AiSpeechService._internal();

  final String _backendBaseUrl = 'http://127.0.0.1:8000';

  /// Gửi trực tiếp mảng bytes file âm thanh thu từ mic sang Faster-Whisper để nhận diện và so khớp âm vị
  Future<PronunciationResult> analyzeAudio({
    required Uint8List audioBytes,
    required String targetSentence,
    required String firebaseUid,
    required int lessonId,
  }) async {
    debugPrint('[AI Engine] Gửi ${audioBytes.length} bytes âm thanh tới Faster-Whisper ASR...');
    try {
      final uri = Uri.parse('$_backendBaseUrl/api/analyze_audio');
      final request = http.MultipartRequest('POST', uri)
        ..fields['target_sentence'] = targetSentence
        ..fields['firebase_uid'] = firebaseUid
        ..fields['lesson_id'] = lessonId.toString()
        ..files.add(
          http.MultipartFile.fromBytes(
            'audio',
            audioBytes,
            filename: 'user_speech.wav',
          ),
        );

      final streamedResp = await request.send();
      final resp = await http.Response.fromStream(streamedResp);

      if (resp.statusCode == 200) {
        final data = jsonDecode(utf8.decode(resp.bodyBytes));
        debugPrint('[AI Engine - Whisper] Nhận diện thành công: "${data['spoken_text']}"');
        return PronunciationResult.fromJson(data);
      } else {
        throw Exception('Server trả về mã lỗi: ${resp.statusCode} - ${resp.body}');
      }
    } catch (e) {
      debugPrint('[AI Engine] Lỗi kết nối tới AI Backend: $e');
      return _buildErrorResult(
        targetSentence,
        'Lỗi phân tích AI: Không thể kết nối tới Backend AI (http://127.0.0.1:8000). Vui lòng đảm bảo server AI Python đang chạy!',
      );
    }
  }

  /// Phân tích và chấm điểm âm vị từ văn bản nói (dùng cho các mẫu kiểm thử Accent)
  Future<PronunciationResult> analyzeText({
    required String targetSentence,
    required String spokenText,
    required String firebaseUid,
    required int lessonId,
  }) async {
    String spoken = spokenText.trim();
    if (spoken.isEmpty) spoken = '...';

    debugPrint('[AI Engine] Phân tích âm vị: Target="$targetSentence" | Spoken="$spoken"');

    try {
      final uri = Uri.parse('$_backendBaseUrl/api/analyze_text');
      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'target_sentence': targetSentence,
          'spoken_text': spoken,
          'firebase_uid': firebaseUid,
          'lesson_id': lessonId,
        }),
      );

      if (resp.statusCode == 200) {
        final data = jsonDecode(utf8.decode(resp.bodyBytes));
        return PronunciationResult.fromJson(data);
      } else {
        throw Exception('Server trả về mã lỗi: ${resp.statusCode}');
      }
    } catch (e) {
      debugPrint('[AI Engine] Lỗi kết nối tới AI Backend: $e');
      return _buildErrorResult(
        targetSentence,
        'Không thể kết nối tới Backend AI (http://127.0.0.1:8000). Hãy kiểm tra server Python đã bật!',
      );
    }
  }

  PronunciationResult _buildErrorResult(String targetSentence, String errorMsg) {
    return PronunciationResult(
      overallScore: 0.0,
      accuracyScore: 0.0,
      fluencyScore: 0.0,
      completenessScore: 0.0,
      generalFeedback: errorMsg,
      weakPhonemes: [],
      words: targetSentence
          .split(' ')
          .map((w) => WordAnalysis(
                word: w,
                standardIpa: '',
                userIpa: '',
                score: 0.0,
                errorType: 'ERROR',
                mouthTongueTip: errorMsg,
                phonemes: [],
              ))
          .toList(),
      spokenText: '',
    );
  }
}

