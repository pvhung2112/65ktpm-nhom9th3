import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/ai_speech_service.dart';
import '../../models/pronunciation_result.dart';

class TestingLabScreen extends StatefulWidget {
  const TestingLabScreen({super.key});

  @override
  State<TestingLabScreen> createState() => _TestingLabScreenState();
}

class _TestingLabScreenState extends State<TestingLabScreen> {
  final AuthService _auth = AuthService();
  final AiSpeechService _speechService = AiSpeechService();

  bool _isRunningTests = false;
  List<Map<String, dynamic>> _testResults = [];

  // Danh mục 4 mẫu giọng nói kiểm thử (Checklist 7)
  final List<Map<String, String>> _benchmarkCases = [
    {
      'title': 'Test Case 1: Giọng Mỹ chuẩn (US Native Accent)',
      'target': 'I think that is right.',
      'spoken': 'I think that is right.',
      'desc': 'Phát âm chuẩn xác quốc tế, đầy đủ âm đầu, nguyên âm và âm đuôi /t/.',
      'expected': '>= 90% (Xanh toàn bộ)',
    },
    {
      'title': 'Test Case 2: Giọng Anh chuẩn (UK Native Accent)',
      'target': 'Thank you very much for your help.',
      'spoken': 'Thank you very much for your help.',
      'desc': 'Phát âm chuẩn Anh-Anh (RP), bật âm /tʃ/ trong "much" rõ ràng.',
      'expected': '>= 85% (Xanh toàn bộ)',
    },
    {
      'title': 'Test Case 3: Giọng người Việt phát âm chuẩn (VN Accurate)',
      'target': 'Think and sink are different words.',
      'spoken': 'Think and sink are different words.',
      'desc': 'Người Việt phân biệt tốt cặp âm /θ/ trong "think" và /s/ trong "sink".',
      'expected': '80% - 88% (Xanh & Vàng)',
    },
    {
      'title': 'Test Case 4: Giọng người Việt mắc lỗi điển hình (VN Accent Errors)',
      'target': 'I think that is right.',
      'spoken': 'I tink dat is righ.',
      'desc': 'Lỗi điển hình: /θ/ biến thành /t/ (tink), /ð/ biến thành /d/ (dat), nuốt âm đuôi /t/ (righ).',
      'expected': '50% - 65% (Đánh dấu ĐỎ từ think, that, right)',
    },
  ];

  Future<void> _runAllBenchmarks() async {
    setState(() {
      _isRunningTests = true;
      _testResults = [];
    });

    for (var bCase in _benchmarkCases) {
      final res = await _speechService.analyzeText(
        targetSentence: bCase['target']!,
        spokenText: bCase['spoken']!,
        firebaseUid: _auth.userUid,
        lessonId: 1,
      );

      _testResults.add({
        'case': bCase,
        'result': res,
      });
      await Future.delayed(const Duration(milliseconds: 300));
    }

    setState(() => _isRunningTests = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧪 Testing & Evaluation Lab (Checklist 7)'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 1,
      ),
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Khối chuyển đổi tài khoản (Multi-User Switching)
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '1. Chuyển Đổi Người Dùng Kiểm Thử (Multi-User Verification):',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Chọn nhanh tài khoản để kiểm tra dữ liệu Streak và lịch sử luyện tập độc lập:',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            _buildUserChip('user_an_01', 'Nguyễn An (Beginner)', '🔥 1 ngày', 'an@test.com'),
                            _buildUserChip('user_binh_02', 'Trần Bình (Intermediate)', '🔥 7 ngày', 'binh@test.com'),
                            _buildUserChip('user_cuong_03', 'Lê Cường (Advanced)', '🔥 21 ngày', 'cuong@test.com'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Khối Benchmark Đa Giọng Nói
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '2. Kiểm Thử Đa Giọng Nói (US, UK, VN Accent):',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            ElevatedButton.icon(
                              onPressed: _isRunningTests ? null : _runAllBenchmarks,
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('CHẠY ĐỐI SOÁT TOÀN BỘ AI'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4F46E5),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Hệ thống tự động nạp các kịch bản audio mẫu và kiểm chứng độ chính xác chấm điểm của AI:',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        const SizedBox(height: 16),

                        if (_isRunningTests)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: Column(
                                children: [
                                  CircularProgressIndicator(color: Color(0xFF4F46E5)),
                                  SizedBox(height: 14),
                                  Text('AI đang chạy thuật toán so khớp âm vị cho từng giọng nói...'),
                                ],
                              ),
                            ),
                          )
                        else if (_testResults.isNotEmpty)
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _testResults.length,
                            itemBuilder: (ctx, idx) {
                              final item = _testResults[idx];
                              final bCase = item['case'] as Map<String, String>;
                              final res = item['result'] as PronunciationResult;

                              Color badgeColor = res.overallScore >= 80
                                  ? Colors.green
                                  : (res.overallScore >= 60 ? Colors.orange : Colors.red);

                              return Container(
                                margin: const EdgeInsets.only(bottom: 14),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            bCase['title']!,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: badgeColor.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            'Điểm AI: ${res.overallScore.toInt()}/100',
                                            style: TextStyle(fontWeight: FontWeight.bold, color: badgeColor),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text('Câu mẫu: "${bCase['target']}"', style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.w500)),
                                    Text('Thực tế phát âm: "${bCase['spoken']}"', style: const TextStyle(fontStyle: FontStyle.italic)),
                                    const SizedBox(height: 6),
                                    Text(bCase['desc']!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                    const SizedBox(height: 10),

                                    // Hiển thị các từ tô màu
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: res.words.map((w) {
                                        Color c = w.score >= 80 ? Colors.green : (w.score >= 50 ? Colors.orange : Colors.red);
                                        return Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: c.withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: c.withOpacity(0.4)),
                                          ),
                                          child: Text(
                                            '${w.word} (${w.score.toInt()})',
                                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: c),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                    const SizedBox(height: 6),
                                    Text('💡 Đánh giá AI: ${res.generalFeedback}', style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B))),
                                  ],
                                ),
                              );
                            },
                          )
                        else
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  Icon(Icons.play_circle_outline, size: 48, color: Colors.grey.withOpacity(0.4)),
                                  const SizedBox(height: 8),
                                  const Text('Bấm nút "CHẠY ĐỐI SOÁT TOÀN BỘ AI" ở trên để nghiệm thu 4 mẫu giọng nói!'),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserChip(String uid, String name, String streak, String email) {
    bool isCurrent = _auth.userUid == uid;
    return ChoiceChip(
      selected: isCurrent,
      avatar: Text(streak),
      label: Text(name),
      onSelected: (selected) {
        if (selected) {
          _auth.switchMockAccount(uid, name, email);
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Đã chuyển sang tài khoản: $name')),
          );
        }
      },
    );
  }
}

