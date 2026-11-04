import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../models/lesson.dart';
import '../../models/pronunciation_result.dart';
import '../../models/user_profile.dart';
import '../../services/ai_speech_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/waveform_painter.dart';
import '../../services/tts_service.dart';
import '../feedback/pronunciation_feedback_dialog.dart';

@JS('startRealtimeMic')
external void _startRealtimeMic(
  JSString targetSentence,
  JSString firebaseUid,
  JSNumber lessonId,
  JSFunction onInterim,
  JSFunction onFinal,
  JSFunction onError,
  JSFunction onVolume,
);

@JS('stopRealtimeMic')
external void _stopRealtimeMic();

class PracticeScreen extends StatefulWidget {
  final Lesson lesson;
  final UserProfile profile;
  final Function(UserProfile) onStreakUpdated;

  const PracticeScreen({
    super.key,
    required this.lesson,
    required this.profile,
    required this.onStreakUpdated,
  });

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  final AiSpeechService _speechService = AiSpeechService();
  final SupabaseService _supabaseService = SupabaseService();

  bool _isRecording = false;
  bool _isAnalyzing = false;
  double _amplitude = 0.0;
  Timer? _ampTimer;
  int _recordingSeconds = 0;
  Timer? _secTimer;

  String _liveTranscript = '';
  Completer<PronunciationResult>? _finalResultCompleter;

  // Checklist 7: Mẫu giọng nói thử nghiệm đa accent
  String _selectedAccentMode = 'Mic Thật (Real Mic)';
  final List<String> _accentModes = [
    'Mic Thật (Real Mic)',
    'Giọng Mỹ chuẩn (US Native - 95%)',
    'Giọng Anh chuẩn (UK Native - 90%)',
    'Giọng Việt chuẩn (VN Good - 80%)',
    'Giọng Việt lỗi âm /θ/ & âm đuôi (VN Error - 55%)',
  ];

  @override
  void dispose() {
    _ampTimer?.cancel();
    _secTimer?.cancel();
    if (_isRecording) {
      try {
        _stopRealtimeMic();
      } catch (_) {}
    }
    super.dispose();
  }

  Future<void> _startRecording() async {
    setState(() {
      _isRecording = true;
      _recordingSeconds = 0;
      _amplitude = 0.0;
      _liveTranscript = 'Đang lắng nghe... Hãy nói vào Micro';
    });

    // Bắt đầu đếm giây
    _secTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) setState(() => _recordingSeconds++);
    });

    if (_selectedAccentMode == 'Mic Thật (Real Mic)') {
      _finalResultCompleter = Completer<PronunciationResult>();

      // Callback nhận biên độ âm lượng thực tế từ Micro (khi im lặng = 0, khi nói nảy lên)
      final onVolumeJS = ((JSNumber vol) {
        if (mounted && _isRecording) {
          setState(() {
            _amplitude = vol.toDartDouble;
          });
        }
      }).toJS;

      // Callback nhận chữ thời gian thực (Interim ASR từ Faster-Whisper)
      final onInterimJS = ((JSString text) {
        final t = text.toDart;
        if (mounted && t.isNotEmpty) {
          setState(() {
            _liveTranscript = t; // CẬP NHẬT CHỮ REAL-TIME NGAY KHI ĐANG NÓI!
          });
        }
      }).toJS;

      // Callback nhận kết quả đánh giá âm vị cuối cùng khi bấm Dừng
      final onFinalJS = ((JSString jsonStr) {
        try {
          final data = jsonDecode(jsonStr.toDart);
          final res = PronunciationResult.fromJson(data);
          if (!_finalResultCompleter!.isCompleted) {
            _finalResultCompleter!.complete(res);
          }
        } catch (e) {
          debugPrint('[Practice] Lỗi parse kết quả final: $e');
        }
      }).toJS;

      final onErrorJS = ((JSString err) {
        debugPrint('[Practice] Lỗi mic stream: ${err.toDart}');
      }).toJS;

      try {
        _startRealtimeMic(
          widget.lesson.targetSentence.toJS,
          widget.profile.firebaseUid.toJS,
          widget.lesson.id.toJS,
          onInterimJS,
          onFinalJS,
          onErrorJS,
          onVolumeJS,
        );
      } catch (e) {
        debugPrint('[Practice] Lỗi gọi _startRealtimeMic: $e');
      }
    }
  }

  Future<void> _testCustomSpokenText(String customText) async {
    setState(() {
      _liveTranscript = customText;
      _isAnalyzing = true;
    });

    final evalResult = await _speechService.analyzeText(
      targetSentence: widget.lesson.targetSentence,
      spokenText: customText,
      firebaseUid: widget.profile.firebaseUid,
      lessonId: widget.lesson.id,
    );

    await _supabaseService.savePracticeHistory(
      uid: widget.profile.firebaseUid,
      lessonId: widget.lesson.id,
      overallScore: evalResult.overallScore,
      accuracyScore: evalResult.accuracyScore,
      fluencyScore: evalResult.fluencyScore,
      completenessScore: evalResult.completenessScore,
      recognizedText: evalResult.spokenText.isNotEmpty ? evalResult.spokenText : customText,
      aiFeedback: evalResult.generalFeedback,
      durationSeconds: 5,
    );

    final updatedProfile = await _supabaseService.updateStreak(widget.profile);
    widget.onStreakUpdated(updatedProfile);

    setState(() => _isAnalyzing = false);

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => PronunciationFeedbackDialog(
          result: evalResult,
          onRemedialPractice: () {},
        ),
      );
    }
  }

  void _showCustomInputDialog() {
    final textCtrl = TextEditingController(text: 'alo 123');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thử nghiệm giọng nói tùy ý'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gõ bất kỳ câu nào bạn muốn thử (ví dụ: "alo 123", "three", "three thousand"):',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textCtrl,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Câu bạn nói',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _testCustomSpokenText(textCtrl.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
            ),
            child: const Text('Chấm điểm ngay'),
          ),
        ],
      ),
    );
  }

  Future<void> _stopRecordingAndAnalyze() async {
    _ampTimer?.cancel();
    _secTimer?.cancel();

    setState(() {
      _isRecording = false;
      _isAnalyzing = true;
      _amplitude = 0.0;
    });

    PronunciationResult evalResult;
    String recognizedText = '';

    if (_selectedAccentMode == 'Mic Thật (Real Mic)') {
      try {
        _stopRealtimeMic();

        // Chờ kết quả chấm điểm cuối cùng từ WebSocket (timeout 8s)
        evalResult = await _finalResultCompleter!.future.timeout(
          const Duration(seconds: 8),
          onTimeout: () => throw TimeoutException('Quá thời gian phản hồi WebSocket'),
        );
        recognizedText = evalResult.spokenText.isNotEmpty ? evalResult.spokenText : '...';
      } catch (e) {
        debugPrint('[Practice] Gọi analyzeText dự phòng: $e');
        evalResult = await _speechService.analyzeText(
          targetSentence: widget.lesson.targetSentence,
          spokenText: _liveTranscript.isNotEmpty ? _liveTranscript : '...',
          firebaseUid: widget.profile.firebaseUid,
          lessonId: widget.lesson.id,
        );
        recognizedText = evalResult.spokenText;
      }
    } else {
      // Giả lập giọng nói theo chế độ kiểm thử (Checklist 7)
      if (_selectedAccentMode.contains('US Native')) {
        recognizedText = widget.lesson.targetSentence;
      } else if (_selectedAccentMode.contains('UK Native')) {
        recognizedText = widget.lesson.targetSentence;
      } else if (_selectedAccentMode.contains('VN Good')) {
        recognizedText = widget.lesson.targetSentence;
      } else if (_selectedAccentMode.contains('VN Error')) {
        recognizedText = widget.lesson.targetSentence
            .replaceAll('think', 'tink')
            .replaceAll('that', 'dat')
            .replaceAll('likes', 'like')
            .replaceAll('three', 'tree');
      }

      evalResult = await _speechService.analyzeText(
        targetSentence: widget.lesson.targetSentence,
        spokenText: recognizedText,
        firebaseUid: widget.profile.firebaseUid,
        lessonId: widget.lesson.id,
      );
    }

    setState(() {
      _liveTranscript = recognizedText;
      _isAnalyzing = false;
    });

    // Nếu không có tiếng nói vào mic (người dùng im lặng)
    if (recognizedText.contains('Chưa nghe thấy') || recognizedText == '...' || evalResult.words.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ AI chưa nghe thấy giọng nói của bạn. Hãy kiểm tra Micro và nói to, rõ ràng hơn nhé!'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
      }
      return;
    }

    // Lưu kết quả vào Supabase và cập nhật Streak
    await _supabaseService.savePracticeHistory(
      uid: widget.profile.firebaseUid,
      lessonId: widget.lesson.id,
      overallScore: evalResult.overallScore,
      accuracyScore: evalResult.accuracyScore,
      fluencyScore: evalResult.fluencyScore,
      completenessScore: evalResult.completenessScore,
      recognizedText: recognizedText,
      aiFeedback: evalResult.generalFeedback,
      durationSeconds: max(5, _recordingSeconds),
    );

    final updatedProfile = await _supabaseService.updateStreak(widget.profile);
    widget.onStreakUpdated(updatedProfile);

    // Mở bảng phản hồi chi tiết (Checklist 5)
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => PronunciationFeedbackDialog(
          result: evalResult,
          onRemedialPractice: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đã chọn bài tập củng cố âm vị yếu! Hãy bấm nói lại nhé.'),
                backgroundColor: Color(0xFF4F46E5),
              ),
            );
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lesson.title),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        actions: [
          // Bộ chọn Accent kiểm thử (Checklist 7)
          DropdownButton<String>(
            value: _selectedAccentMode,
            underline: const SizedBox(),
            icon: const Icon(Icons.tune, color: Color(0xFF4F46E5)),
            items: _accentModes.map((acc) {
              return DropdownMenuItem(
                value: acc,
                child: Text(acc, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedAccentMode = val);
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650),
            child: Column(
              children: [
                // Thẻ câu luyện phát âm
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4F46E5).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                widget.lesson.category,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4F46E5),
                                ),
                              ),
                            ),
                            Text(
                              'Âm trọng tâm: ${widget.lesson.targetFocusPhonemes}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.orange),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Câu tiếng Anh
                        Text(
                          widget.lesson.targetSentence,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                            height: 1.3,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),

                        // Phiên âm IPA
                        Text(
                          widget.lesson.standardIpa,
                          style: const TextStyle(
                            fontSize: 17,
                            fontFamily: 'monospace',
                            color: Color(0xFF6366F1),
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),

                        // Nút nghe phát âm mẫu
                        ElevatedButton.icon(
                          onPressed: () {
                            TtsService().speakNative(widget.lesson.targetSentence);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('🔊 Đang phát âm bản xứ: "${widget.lesson.targetSentence}"'),
                                duration: const Duration(seconds: 2),
                                backgroundColor: const Color(0xFF4F46E5),
                              ),
                            );
                          },
                          icon: const Icon(Icons.volume_up, size: 22),
                          label: const Text('Nghe người bản xứ đọc mẫu (To & Rõ)', style: TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                            foregroundColor: const Color(0xFF4F46E5),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Canvas Sóng Âm Real-time (Waveform Canvas)
                Container(
                  height: 90,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.withOpacity(0.2)),
                  ),
                  child: CustomPaint(
                    painter: WaveformPainter(
                      amplitude: _amplitude,
                      isRecording: _isRecording,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Dòng hiển thị kết quả AI nhận diện được từ âm thanh (Real-time Streaming)
                if (_liveTranscript.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.indigo.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF4F46E5).withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isRecording)
                          const Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4F46E5)),
                            ),
                          ),
                        Flexible(
                          child: Text(
                            'AI Whisper: "$_liveTranscript"',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              fontStyle: FontStyle.italic,
                              color: Color(0xFF1E293B),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 32),

                // Nút Bấm Thu Âm Lớn
                if (_isAnalyzing)
                  const Column(
                    children: [
                      CircularProgressIndicator(color: Color(0xFF4F46E5)),
                      SizedBox(height: 12),
                      Text('AI Faster-Whisper đang hoàn tất chấm điểm âm vị...', style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  )
                else
                  Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (_isRecording) {
                            _stopRecordingAndAnalyze();
                          } else {
                            _startRecording();
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: _isRecording ? 95 : 85,
                          height: _isRecording ? 95 : 85,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isRecording ? const Color(0xFFEF4444) : const Color(0xFF4F46E5),
                            boxShadow: [
                              BoxShadow(
                                color: (_isRecording ? Colors.red : Colors.indigo).withOpacity(0.4),
                                blurRadius: 18,
                                spreadRadius: 4,
                              )
                            ],
                          ),
                          child: Icon(
                            _isRecording ? Icons.stop : Icons.mic,
                            size: 44,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _isRecording ? 'Đang stream giọng nói ($_recordingSeconds s) - Chạm để Dừng & Chấm điểm' : 'Chạm vào Micro để bắt đầu nói',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _isRecording ? Colors.red : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: _isRecording ? null : _showCustomInputDialog,
                        icon: const Icon(Icons.keyboard, size: 18, color: Color(0xFF4F46E5)),
                        label: const Text(
                          '⌨️ Thử gõ câu bất kỳ (VD: "three", "alo 123")',
                          style: TextStyle(color: Color(0xFF4F46E5), fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
