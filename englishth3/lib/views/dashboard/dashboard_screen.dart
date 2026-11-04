import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../models/lesson.dart';
import '../../models/practice_history.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/score_circle.dart';
import '../practice/practice_screen.dart';
import '../test_lab/testing_lab_screen.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const DashboardScreen({super.key, required this.onLogout});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AuthService _auth = AuthService();
  final SupabaseService _supabase = SupabaseService();
  final NotificationService _notifications = NotificationService();

  UserProfile? _profile;
  List<Lesson> _lessons = [];
  List<PracticeHistory> _histories = [];
  Map<String, int> _todayGoal = {
    'practiced_minutes': 0,
    'target_minutes': 15,
    'practiced_sentences': 0,
    'target_sentences': 5,
  };
  List<double> _weeklyMinutes = List.filled(7, 0.0);
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _notifications.init();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final profile = await _supabase.getUserProfile(
      _auth.userUid,
      _auth.userEmail,
      _auth.userDisplayName,
    );
    final lessons = await _supabase.getLessons();
    final histories = await _supabase.getRecentHistories(_auth.userUid);
    final todayGoal = await _supabase.getTodayGoal(
      _auth.userUid,
      defaultTargetMinutes: profile.dailyTargetMinutes,
      defaultTargetSentences: profile.dailyTargetSentences,
    );
    final weeklyMinutes = await _supabase.getWeeklyStudyMinutes(_auth.userUid);

    if (mounted) {
      setState(() {
        _profile = profile;
        _lessons = lessons;
        _histories = histories;
        _todayGoal = todayGoal;
        _weeklyMinutes = weeklyMinutes;
        _isLoading = false;
      });
    }
  }

  void _triggerReminderTest() {
    _notifications.showStreakReminder(
      currentStreak: _profile?.currentStreak ?? 1,
      title: '⏰ Đã đến giờ luyện nói tiếng Anh!',
      body: 'Giữ vững chuỗi ${_profile?.currentStreak ?? 1} ngày streak rực lửa của bạn nhé! 🔥',
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔔 Đã bắn thông báo nhắc nhở luyện tập hàng ngày!'),
        backgroundColor: Colors.indigo,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5))),
      );
    }

    final streak = _profile?.currentStreak ?? 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Row(
          children: [
            const Icon(Icons.school, color: Color(0xFF4F46E5)),
            const SizedBox(width: 8),
            Text(
              'Xin chào, ${_profile?.displayName ?? "Học viên"}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
          ],
        ),
        actions: [
          // Huy hiệu Streak rực lửa (Checklist 2)
          StreakBadge(streakDays: streak),
          const SizedBox(width: 8),

          // Nút chuông nhắc nhở (Checklist 6)
          IconButton(
            tooltip: 'Bắn thông báo nhắc nhở hàng ngày',
            icon: const Icon(Icons.notifications_active, color: Color(0xFFF59E0B)),
            onPressed: _triggerReminderTest,
          ),

          // Nút Lab kiểm thử (Checklist 7)
          IconButton(
            tooltip: 'Phòng Lab Kiểm Thử Đa Giọng (Checklist 7)',
            icon: const Icon(Icons.science, color: Color(0xFF4F46E5)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TestingLabScreen()),
              ).then((_) => _loadData());
            },
          ),

          // Đăng xuất
          IconButton(
            tooltip: 'Đăng xuất',
            icon: const Icon(Icons.logout, color: Colors.grey),
            onPressed: () async {
              await _auth.signOut();
              widget.onLogout();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thẻ Mục Tiêu Ngày & Kỷ Luật Học Tập (Checklist 2)
                _buildDailyGoalCard(),
                const SizedBox(height: 24),

                // Biểu đồ Thời Gian Học 7 Ngày (fl_chart)
                _buildStudyChartCard(),
                const SizedBox(height: 28),

                // Danh sách bài học phát âm
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Ngân Hàng Câu Luyện Phát Âm AI',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                    Text(
                      '${_lessons.length} bài học',
                      style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _lessons.length,
                  itemBuilder: (context, idx) {
                    final lesson = _lessons[idx];
                    return _buildLessonCard(lesson);
                  },
                ),
                const SizedBox(height: 28),

                // Lịch sử luyện tập gần đây (Lưu Supabase)
                const Text(
                  'Lịch Sử Luyện Tập Gần Đây (Lưu Supabase)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 12),
                if (_histories.isNotEmpty)
                  ...(_histories.map((h) => _buildHistoryItem(h)).toList())
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_toggle_off, color: Colors.grey, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'Tài khoản này chưa có lịch sử luyện tập nào trên CSDL.\nHãy bấm "Luyện nói" ở trên để ghi nhận bài học đầu tiên!',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDailyGoalCard() {
    final practicedMinutes = _todayGoal['practiced_minutes'] ?? 0;
    final targetMinutes = _todayGoal['target_minutes'] ?? 15;
    final practicedSentences = _todayGoal['practiced_sentences'] ?? 0;
    final targetSentences = _todayGoal['target_sentences'] ?? 5;
    final percent = targetMinutes > 0 ? (practicedMinutes / targetMinutes).clamp(0.0, 1.0) : 0.0;
    final isDone = practicedSentences >= targetSentences && practicedMinutes >= targetMinutes;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 70,
                  height: 70,
                  child: CircularProgressIndicator(
                    value: percent,
                    strokeWidth: 7,
                    backgroundColor: Colors.indigo.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDone ? Colors.green : const Color(0xFF4F46E5),
                    ),
                  ),
                ),
                Text(
                  '${(percent * 100).toInt()}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDone ? Colors.green : const Color(0xFF4F46E5),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mục Tiêu Luyện Tập Hôm Nay',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Đã học $practicedMinutes/$targetMinutes phút • Đạt $practicedSentences/$targetSentences câu nói',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isDone ? Colors.green : Colors.indigo).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isDone
                          ? '🎉 Chúc mừng! Bạn đã hoàn thành xuất sắc mục tiêu hôm nay!'
                          : (practicedSentences > 0
                              ? '🔥 Tiếp tục phát huy! Hãy hoàn thành $targetSentences câu để bảo toàn kỷ luật!'
                              : '💡 Bạn chưa luyện câu nào hôm nay. Hãy bắt đầu ngay để kích hoạt Streak!'),
                      style: TextStyle(
                        color: isDone ? Colors.green : const Color(0xFF4F46E5),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudyChartCard() {
    final totalMinutes = _weeklyMinutes.fold(0.0, (sum, m) => sum + m);
    final now = DateTime.now();
    final todayIndex = now.weekday - 1; // 0: Thứ 2 -> 6: Chủ nhật
    final maxVal = _weeklyMinutes.isEmpty ? 10.0 : _weeklyMinutes.reduce(max);
    final maxY = max(10.0, (maxVal + 5).ceilToDouble());

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Thống Kê Thời Gian Học 7 Ngày (Phút)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                Text(
                  'Tổng: ${totalMinutes.toStringAsFixed(1)} phút',
                  style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 160,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, meta) {
                          const days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
                          if (val.toInt() >= 0 && val.toInt() < days.length) {
                            final isToday = val.toInt() == todayIndex;
                            return Text(
                              days[val.toInt()],
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                                color: isToday ? const Color(0xFFF59E0B) : Colors.grey,
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(7, (i) {
                    final isToday = (i == todayIndex);
                    return _makeBarGroup(i, _weeklyMinutes[i], isToday: isToday);
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _makeBarGroup(int x, double y, {bool isToday = false}) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: isToday ? const Color(0xFFF59E0B) : const Color(0xFF4F46E5),
          width: 18,
          borderRadius: BorderRadius.circular(6),
        ),
      ],
    );
  }

  Widget _buildLessonCard(Lesson lesson) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF4F46E5).withOpacity(0.1),
          child: const Icon(Icons.mic, color: Color(0xFF4F46E5)),
        ),
        title: Text(
          lesson.targetSentence,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(lesson.standardIpa, style: const TextStyle(fontFamily: 'monospace', color: Colors.indigo)),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: Colors.grey.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                  child: Text(lesson.category, style: const TextStyle(fontSize: 11)),
                ),
                const SizedBox(width: 8),
                Text('Âm: ${lesson.targetFocusPhonemes}', style: const TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PracticeScreen(
                  lesson: lesson,
                  profile: _profile!,
                  onStreakUpdated: (updated) => setState(() => _profile = updated),
                ),
              ),
            ).then((_) => _loadData());
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4F46E5),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Luyện nói'),
        ),
      ),
    );
  }

  Widget _buildHistoryItem(PracticeHistory history) {
    Color scoreColor = history.overallScore >= 80 ? Colors.green : (history.overallScore >= 50 ? Colors.orange : Colors.red);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: scoreColor.withOpacity(0.15),
          child: Text('${history.overallScore.toInt()}', style: TextStyle(color: scoreColor, fontWeight: FontWeight.bold)),
        ),
        title: Text(history.recognizedText.isNotEmpty ? history.recognizedText : 'Luyện tập phát âm'),
        subtitle: Text(history.aiFeedbackText, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
        trailing: Text(
          '${history.practicedAt.hour}:${history.practicedAt.minute.toString().padLeft(2, '0')}',
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ),
    );
  }
}

