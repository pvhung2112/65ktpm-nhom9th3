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
import '../../services/tts_service.dart';

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
  Map<String, num> _todayGoal = {
    'practiced_minutes': 0.0,
    'target_minutes': 15,
    'practiced_sentences': 0,
    'target_sentences': 5,
  };
  List<double> _weeklyMinutes = List.filled(7, 0.0);
  bool _isLoading = true;

  // Trạng thái Tìm kiếm, Bộ lọc Danh mục & Phân trang
  String _searchQuery = '';
  String _selectedCategory = 'Tất cả';
  int _currentPage = 0;
  static const int _pageSize = 6; // Mỗi trang hiển thị 6 từ/câu ngắn

  List<String> get _categories {
    final cats = {'Tất cả'};
    for (var l in _lessons) {
      if (l.category.isNotEmpty) cats.add(l.category);
    }
    return cats.toList();
  }

  List<Lesson> get _filteredLessons {
    return _lessons.where((l) {
      final matchCat = _selectedCategory == 'Tất cả' || l.category == _selectedCategory;
      final q = _searchQuery.toLowerCase().trim();
      final matchQuery = q.isEmpty ||
          l.targetSentence.toLowerCase().contains(q) ||
          l.title.toLowerCase().contains(q) ||
          l.category.toLowerCase().contains(q);
      return matchCat && matchQuery;
    }).toList();
  }

  int get _totalPages => max(1, (_filteredLessons.length / _pageSize).ceil());

  List<Lesson> get _pagedLessons {
    final list = _filteredLessons;
    final start = _currentPage * _pageSize;
    if (start >= list.length) return [];
    return list.sublist(start, min(start + _pageSize, list.length));
  }

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
    final curStreak = _profile?.currentStreak ?? 0;
    _notifications.showStreakReminder(
      currentStreak: curStreak,
      title: '⏰ Đã đến giờ luyện nói tiếng Anh!',
      body: curStreak > 0
          ? 'Giữ vững chuỗi $curStreak ngày streak rực lửa của bạn nhé! 🔥'
          : 'Hãy bắt đầu luyện nói ngay hôm nay để thắp sáng chuỗi streak đầu tiên! 🔥',
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

    final streak = _profile?.currentStreak ?? 0;

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

                // Khu vực Ngân hàng Từ vựng (Tìm kiếm, Bộ lọc & Lưới thẻ phân trang)
                _buildLessonSection(),
                const SizedBox(height: 32),

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
    final practicedMinutes = (_todayGoal['practiced_minutes'] ?? 0.0).toDouble();
    final targetMinutes = (_todayGoal['target_minutes'] ?? 15.0).toDouble();
    final practicedSentences = (_todayGoal['practiced_sentences'] ?? 0).toInt();
    final targetSentences = (_todayGoal['target_sentences'] ?? 5).toInt();
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
                    backgroundColor: Colors.indigo.withValues(alpha: 0.1),
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
                    'Đã học ${practicedMinutes.toStringAsFixed(1)}/${targetMinutes.toInt()} phút • Đạt $practicedSentences/$targetSentences câu chuẩn (>= 80đ)',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isDone ? Colors.green : Colors.indigo).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isDone
                          ? '🎉 Chúc mừng! Bạn đã hoàn thành xuất sắc mục tiêu hôm nay!'
                          : (practicedSentences >= targetSentences
                              ? '🔥 Đã đạt $practicedSentences/$targetSentences câu chuẩn (>= 80đ)! Hãy luyện thêm ${(targetMinutes - practicedMinutes).clamp(0.1, targetMinutes).toStringAsFixed(1)} phút nữa để đạt 100% mục tiêu ngày!'
                              : (practicedSentences > 0
                                  ? '🔥 Tiếp tục phát huy! Cần thêm ${targetSentences - practicedSentences} câu đạt chuẩn (>= 80đ) để hoàn thành mục tiêu!'
                                  : '💡 Bạn chưa có câu đạt chuẩn nào hôm nay. Hãy bắt đầu luyện nói ngay để kích hoạt Streak!')),
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

  Widget _buildLessonSection() {
    final filtered = _filteredLessons;
    final paged = _pagedLessons;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Ngân Hàng Từ & Câu Luyện Phát Âm',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.indigo.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${filtered.length} bài học',
                style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // 1. Ô Tìm Kiếm tức thì (Search Bar)
        TextField(
          onChanged: (val) {
            setState(() {
              _searchQuery = val;
              _currentPage = 0; // reset về trang 1
            });
          },
          decoration: InputDecoration(
            hintText: '🔍 Tìm kiếm từ hoặc câu ngắn (VD: hi, hello, hungry, coffee...)',
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // 2. Bộ lọc theo Danh mục (Category Filter Pills)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _categories.map((cat) {
              final isSelected = _selectedCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  selected: isSelected,
                  label: Text(cat),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF1E293B),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                  selectedColor: const Color(0xFF4F46E5),
                  backgroundColor: Colors.white,
                  checkmarkColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected ? const Color(0xFF4F46E5) : Colors.grey.withOpacity(0.25),
                    ),
                  ),
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategory = cat;
                      _currentPage = 0;
                    });
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),

        // 3. Grid Lưới thẻ bài học (2 hoặc 3 cột tùy độ rộng màn hình)
        if (paged.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                'Không tìm thấy từ nào phù hợp với tìm kiếm của bạn!',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          LayoutBuilder(
            builder: (ctx, constraints) {
              final isWide = constraints.maxWidth > 650;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: paged.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isWide ? 3 : 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  mainAxisExtent: 220,
                ),
                itemBuilder: (ctx, i) => _buildLessonGridCard(paged[i]),
              );
            },
          ),
        const SizedBox(height: 14),

        // 4. Thanh điều khiển Phân Trang (Pagination Control)
        if (_totalPages > 1)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 16),
                  onPressed: _currentPage > 0
                      ? () => setState(() => _currentPage--)
                      : null,
                ),
                const SizedBox(width: 8),
                Text(
                  'Trang ${_currentPage + 1} / $_totalPages  (${filtered.length} từ)',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, size: 16),
                  onPressed: _currentPage < _totalPages - 1
                      ? () => setState(() => _currentPage++)
                      : null,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildLessonGridCard(Lesson lesson) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Header: Category Tag & Nút Loa TTS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    lesson.category,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4F46E5),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.volume_up, color: Color(0xFF4F46E5), size: 18),
                  tooltip: 'Nghe phát âm bản xứ',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 18,
                  onPressed: () {
                    TtsService().speakNative(lesson.targetSentence);
                  },
                ),
              ],
            ),

            // Target Text (To, rõ ràng)
            Text(
              lesson.targetSentence,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
                height: 1.25,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            // IPA & Focus Phonemes
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lesson.standardIpa,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: Colors.indigo,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Âm: ${lesson.targetFocusPhonemes}',
                  style: const TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),

            // Nút Luyện nói
            SizedBox(
              width: double.infinity,
              height: 36,
              child: ElevatedButton.icon(
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
                icon: const Icon(Icons.mic, size: 16),
                label: const Text('Luyện nói ngay', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
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

