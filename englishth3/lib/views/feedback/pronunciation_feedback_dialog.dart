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

  static Color getScoreColor(double score) {
    if (score >= 80) return const Color(0xFF10B981); // Xanh lá: Chuẩn
    if (score >= 50) return const Color(0xFFF59E0B); // Vàng: Gần đúng
    return const Color(0xFFEF4444); // Đỏ: Cần cải thiện
  }

  void _showWordDetails(BuildContext context, WordAnalysis word) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _WordDetailSheet(word: word),
    );
  }

  @override
  Widget build(BuildContext context) {
    final correctCount = result.words.where((w) => w.score >= 80).length;
    final almostCount = result.words.where((w) => w.score >= 50 && w.score < 80).length;
    final weakCount = result.words.where((w) => w.score < 50).length;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      elevation: 8,
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Khối Header Điểm số (Score Circles)
                _FeedbackHeader(result: result),
                const SizedBox(height: 18),

                // 2. Nhận xét tổng quan của AI
                _GeneralFeedbackCard(feedback: result.generalFeedback),
                const SizedBox(height: 14),

                // 3. AI Whisper nhận diện câu nói
                if (result.spokenText.isNotEmpty) ...[
                  _WhisperTranscriptCard(spokenText: result.spokenText),
                  const SizedBox(height: 16),
                ],

                // 4. Thanh tóm tắt nhanh số lượng từ
                _WordSummaryBadges(
                  correctCount: correctCount,
                  almostCount: almostCount,
                  weakCount: weakCount,
                ),
                const SizedBox(height: 14),

                // 5. Danh sách các từ có phân loại màu sắc & chi tiết
                _WordGridSection(
                  words: result.words,
                  onWordTap: (word) => _showWordDetails(context, word),
                ),
                const SizedBox(height: 22),

                // 6. Nút hành động
                _ActionButtons(
                  onRemedialPractice: onRemedialPractice,
                  hasWeakWords: weakCount > 0 || almostCount > 0,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// -------------------- CÁC WIDGET THÀNH PHẦN TÁCH NHỎ --------------------

class _FeedbackHeader extends StatelessWidget {
  final PronunciationResult result;

  const _FeedbackHeader({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ScoreCircle(score: result.overallScore, size: 88, label: 'Tổng điểm'),
          ScoreCircle(score: result.accuracyScore, size: 70, label: 'Chính xác'),
          ScoreCircle(score: result.fluencyScore, size: 70, label: 'Lưu loát'),
        ],
      ),
    );
  }
}

class _GeneralFeedbackCard extends StatelessWidget {
  final String feedback;

  const _GeneralFeedbackCard({required this.feedback});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC7D2FE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_awesome, size: 20, color: Color(0xFF4F46E5)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              feedback,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF312E81),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WhisperTranscriptCard extends StatelessWidget {
  final String spokenText;

  const _WhisperTranscriptCard({required this.spokenText});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.mic, size: 20, color: Color(0xFF64748B)),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
                children: [
                  const TextSpan(
                    text: 'AI nghe thấy: ',
                    style: TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
                  ),
                  TextSpan(
                    text: '"$spokenText"',
                    style: const TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF0F172A),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WordSummaryBadges extends StatelessWidget {
  final int correctCount;
  final int almostCount;
  final int weakCount;

  const _WordSummaryBadges({
    required this.correctCount,
    required this.almostCount,
    required this.weakCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildPill('Chuẩn ($correctCount)', const Color(0xFF10B981), Icons.check_circle_outline),
        const SizedBox(width: 8),
        _buildPill('Gần đúng ($almostCount)', const Color(0xFFF59E0B), Icons.info_outline),
        const SizedBox(width: 8),
        _buildPill('Cần sửa ($weakCount)', const Color(0xFFEF4444), Icons.error_outline),
      ],
    );
  }

  Widget _buildPill(String text, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                text,
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: color),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WordGridSection extends StatelessWidget {
  final List<WordAnalysis> words;
  final void Function(WordAnalysis) onWordTap;

  const _WordGridSection({required this.words, required this.onWordTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text(
              'Chi tiết từng từ',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
            ),
            Spacer(),
            Text(
              'Chạm vào từ để xem mẹo khẩu hình',
              style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: words.map((w) => _WordChip(word: w, onTap: () => onWordTap(w))).toList(),
        ),
      ],
    );
  }
}

class _WordChip extends StatelessWidget {
  final WordAnalysis word;
  final VoidCallback onTap;

  const _WordChip({required this.word, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = PronunciationFeedbackDialog.getScoreColor(word.score);
    final isCorrect = word.score >= 80;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.45), width: 1.4),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.08),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        word.word,
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        isCorrect ? Icons.check_circle : Icons.help_outline,
                        size: 14,
                        color: color,
                      ),
                    ],
                  ),
                  Text(
                    word.standardIpa,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: color.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${word.score.toInt()}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final VoidCallback onRemedialPractice;
  final bool hasWeakWords;

  const _ActionButtons({
    required this.onRemedialPractice,
    required this.hasWeakWords,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            child: const Text(
              'Luyện lại câu',
              style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF334155)),
            ),
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
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.flash_on, size: 18),
                const SizedBox(width: 4),
                Text(
                  hasWeakWords ? 'Luyện âm yếu' : 'Tiếp tục',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _WordDetailSheet extends StatelessWidget {
  final WordAnalysis word;

  const _WordDetailSheet({required this.word});

  String _formatErrorType(String type) {
    switch (type.toUpperCase()) {
      case 'CORRECT':
        return 'Chuẩn xác';
      case 'SUBSTITUTION':
        return 'Sai âm thay thế';
      case 'OMISSION':
        return 'Nuốt âm / Bỏ sót';
      case 'INSERTION':
        return 'Thừa âm';
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = PronunciationFeedbackDialog.getScoreColor(word.score);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header: Tên từ và điểm
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                word.word,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Text(
                  '${word.score.toInt()} điểm • ${_formatErrorType(word.errorType)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // So sánh phiên âm IPA
          Row(
            children: [
              Expanded(
                child: _buildIpaCard(
                  title: 'Phiên âm chuẩn',
                  ipa: word.standardIpa,
                  color: const Color(0xFF2563EB),
                  hasSpeaker: true,
                  onSpeak: () => TtsService().speakNative(word.word),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildIpaCard(
                  title: 'Bạn đã phát âm',
                  ipa: word.userIpa.isEmpty ? '-' : word.userIpa,
                  color: color,
                  hasSpeaker: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Đối chiếu âm vị (Alignment)
          if (word.phonemes.isNotEmpty) ...[
            const Text(
              'So khớp từng âm vị (Phoneme Alignment):',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155)),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: word.phonemes.map((p) {
                final isOk = p.isCorrect;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isOk ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isOk ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5)),
                  ),
                  child: Text(
                    '${p.standardPhoneme} → ${p.userPhoneme.isEmpty ? "-" : p.userPhoneme}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isOk ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                      fontSize: 12.5,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
          ],

          // Hướng dẫn khẩu hình miệng & lưỡi
          const Text(
            'Hướng dẫn điều chỉnh khẩu hình (Lưỡi & Môi):',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.record_voice_over, size: 20, color: Color(0xFFD97706)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    word.mouthTongueTip.isEmpty ? 'Phát âm chuẩn xác, hãy duy trì!' : word.mouthTongueTip,
                    style: const TextStyle(
                      fontSize: 13.5,
                      height: 1.4,
                      color: Color(0xFF92400E),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIpaCard({
    required String title,
    required String ipa,
    required Color color,
    required bool hasSpeaker,
    VoidCallback? onSpeak,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  ipa,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (hasSpeaker && onSpeak != null)
                IconButton(
                  onPressed: onSpeak,
                  icon: const Icon(Icons.volume_up, size: 22, color: Color(0xFF2563EB)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 18,
                  tooltip: 'Nghe phát âm chuẩn',
                ),
            ],
          ),
        ],
      ),
    );
  }
}
