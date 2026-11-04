import 'package:flutter/material.dart';
import '../../models/pronunciation_result.dart';
import '../../services/tts_service.dart';
import '../../widgets/score_circle.dart';

class PronunciationFeedbackDialog extends StatelessWidget {
  final PronunciationResult result;
  final VoidCallback onRemedialPractice;

  const PronunciationFeedbackDialog({
    super.key,
    required this.result,
    required this.onRemedialPractice,
  });

  Color _getWordColor(double score) {
    if (score >= 80) return const Color(0xFF10B981); // Xanh lá: Chuẩn
    if (score >= 50) return const Color(0xFFF59E0B); // Vàng: Gần đúng
    return const Color(0xFFEF4444); // Đỏ: Sai âm / Nuốt âm
  }

  void _showWordDetails(BuildContext context, WordAnalysis word) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    word.word,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: _getWordColor(word.score),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getWordColor(word.score).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${word.score.toInt()} điểm (${word.errorType})',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getWordColor(word.score),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // So sánh phiên âm
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Phiên âm chuẩn:', style: TextStyle(color: Colors.grey, fontSize: 13)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(word.standardIpa, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                              const SizedBox(width: 6),
                              InkWell(
                                onTap: () => TtsService().speakNative(word.word),
                                child: const Icon(Icons.volume_up, size: 20, color: Colors.blueAccent),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Bạn đã phát âm:', style: TextStyle(color: Colors.grey, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text(word.userIpa, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _getWordColor(word.score))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Bảng âm vị chi tiết (Needleman-Wunsch Alignment)
              if (word.phonemes.isNotEmpty) ...[
                const Text('So khớp từng âm vị (Needleman-Wunsch Alignment):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: word.phonemes.map((p) {
                    final isOk = p.isCorrect;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isOk ? Colors.green.withOpacity(0.12) : Colors.red.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isOk ? Colors.green : Colors.red),
                      ),
                      child: Text(
                        '${p.standardPhoneme} → ${p.userPhoneme.isEmpty ? "-" : p.userPhoneme}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isOk ? Colors.green.shade700 : Colors.red.shade700,
                          fontSize: 13,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],

              // Hướng dẫn khẩu hình chi tiết (Checklist 5)
              const Text('Hướng dẫn điều chỉnh khẩu hình (Lưỡi & Môi):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade400),
                ),
                child: Text(
                  word.mouthTongueTip,
                  style: const TextStyle(fontSize: 14, height: 1.4, color: Color(0xFF78350F)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      elevation: 10,
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 550),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header Điểm số
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ScoreCircle(score: result.overallScore, size: 85, label: 'Tổng điểm'),
                    ScoreCircle(score: result.accuracyScore, size: 70, label: 'Chính xác'),
                    ScoreCircle(score: result.fluencyScore, size: 70, label: 'Lưu loát'),
                  ],
                ),
                const SizedBox(height: 20),

                // Lời nhận xét tổng quan
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    result.generalFeedback,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),

                // Hiển thị chính xác những gì người dùng vừa đọc qua mô hình Whisper
                if (result.spokenText.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.mic, size: 20, color: Color(0xFF4F46E5)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
                              children: [
                                const TextSpan(text: 'AI Whisper nghe được bạn đọc: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                TextSpan(
                                  text: '"${result.spokenText}"',
                                  style: const TextStyle(fontStyle: FontStyle.italic, color: Color(0xFF4F46E5), fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Bảng từ tô màu 3 cấp độ
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Chi tiết từng từ (Chạm vào từ để xem cách sửa khẩu hình):',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 10),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: result.words.map((w) {
                    final color = _getWordColor(w.score);
                    return InkWell(
                      onTap: () => _showWordDetails(context, w),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: color.withOpacity(0.4), width: 1.5),
                        ),
                        child: Column(
                          children: [
                            Text(
                              w.word,
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
                            ),
                            Text(
                              w.standardIpa,
                              style: TextStyle(fontSize: 11, color: color.withOpacity(0.8)),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Chú thích màu sắc
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegendItem('🟢 Đúng (≥80)', const Color(0xFF10B981)),
                    const SizedBox(width: 12),
                    _buildLegendItem('🟡 Gần đúng (50-79)', const Color(0xFFF59E0B)),
                    const SizedBox(width: 12),
                    _buildLegendItem('🔴 Sai (<50)', const Color(0xFFEF4444)),
                  ],
                ),
                const SizedBox(height: 24),

                // Nút hành động
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Luyện lại câu này'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          onRemedialPractice();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Luyện âm yếu'),
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

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
