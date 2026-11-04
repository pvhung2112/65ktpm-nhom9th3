import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/user_profile.dart';
import '../models/lesson.dart';
import '../models/practice_history.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient get _client => Supabase.instance.client;

  // Danh mục từ vựng & câu ngắn dễ học hàng ngày
  final List<Lesson> _localLessons = [
    Lesson(
      id: 1,
      title: 'Chào hỏi: Hi',
      category: 'Chào hỏi',
      difficulty: 'Beginner',
      targetSentence: 'Hi',
      standardIpa: '/haɪ/',
      targetFocusPhonemes: '/aɪ/',
    ),
    Lesson(
      id: 2,
      title: 'Chào hỏi: Hello',
      category: 'Chào hỏi',
      difficulty: 'Beginner',
      targetSentence: 'Hello',
      standardIpa: '/həloʊ/',
      targetFocusPhonemes: '/h/, /oʊ/',
    ),
    Lesson(
      id: 3,
      title: 'Chào hỏi: Hello world',
      category: 'Chào hỏi',
      difficulty: 'Beginner',
      targetSentence: 'Hello world',
      standardIpa: '/həloʊwɜːrld/',
      targetFocusPhonemes: '/w/, /ɜːr/',
    ),
    Lesson(
      id: 4,
      title: 'Đời sống: I am hungry',
      category: 'Đời sống',
      difficulty: 'Beginner',
      targetSentence: 'I am hungry',
      standardIpa: '/aɪæmhʌŋɡriː/',
      targetFocusPhonemes: '/aɪ/, /ŋ/',
    ),
    Lesson(
      id: 5,
      title: 'Giao tiếp: Thank you',
      category: 'Giao tiếp',
      difficulty: 'Beginner',
      targetSentence: 'Thank you',
      standardIpa: '/θæŋkjuː/',
      targetFocusPhonemes: '/θ/, /ŋ/',
    ),
    Lesson(
      id: 6,
      title: 'Chào hỏi: Good morning',
      category: 'Chào hỏi',
      difficulty: 'Beginner',
      targetSentence: 'Good morning',
      standardIpa: '/ɡʊdmɔːrnɪŋ/',
      targetFocusPhonemes: '/ʊ/, /ŋ/',
    ),
    Lesson(
      id: 7,
      title: 'Chào hỏi: Goodbye',
      category: 'Chào hỏi',
      difficulty: 'Beginner',
      targetSentence: 'Goodbye',
      standardIpa: '/ɡʊdbaɪ/',
      targetFocusPhonemes: '/d/, /aɪ/',
    ),
    Lesson(
      id: 8,
      title: 'Giao tiếp: Good job',
      category: 'Giao tiếp',
      difficulty: 'Beginner',
      targetSentence: 'Good job',
      standardIpa: '/ɡʊddʒɑːb/',
      targetFocusPhonemes: '/dʒ/',
    ),
    Lesson(
      id: 9,
      title: 'Đời sống: I like it',
      category: 'Đời sống',
      difficulty: 'Beginner',
      targetSentence: 'I like it',
      standardIpa: '/aɪlaɪkɪt/',
      targetFocusPhonemes: '/aɪ/, /t/',
    ),
    Lesson(
      id: 10,
      title: 'Chào hỏi: How are you',
      category: 'Chào hỏi',
      difficulty: 'Beginner',
      targetSentence: 'How are you',
      standardIpa: '/haʊɑːrjuː/',
      targetFocusPhonemes: '/aʊ/',
    ),
    Lesson(
      id: 11,
      title: 'Chào hỏi: See you again',
      category: 'Chào hỏi',
      difficulty: 'Beginner',
      targetSentence: 'See you again',
      standardIpa: '/siːjuːəɡen/',
      targetFocusPhonemes: '/iː/',
    ),
    Lesson(
      id: 12,
      title: 'Ăn uống: Coffee',
      category: 'Ăn uống',
      difficulty: 'Beginner',
      targetSentence: 'Coffee',
      standardIpa: '/kɑːfiː/',
      targetFocusPhonemes: '/k/, /f/',
    ),
    Lesson(
      id: 13,
      title: 'Ăn uống: Water',
      category: 'Ăn uống',
      difficulty: 'Beginner',
      targetSentence: 'Water',
      standardIpa: '/wɔːtər/',
      targetFocusPhonemes: '/w/, /t/',
    ),
    Lesson(
      id: 14,
      title: 'Ăn uống: Apple',
      category: 'Ăn uống',
      difficulty: 'Beginner',
      targetSentence: 'Apple',
      standardIpa: '/æpəl/',
      targetFocusPhonemes: '/æ/, /l/',
    ),
    Lesson(
      id: 15,
      title: 'Giao tiếp: Yes please',
      category: 'Giao tiếp',
      difficulty: 'Beginner',
      targetSentence: 'Yes please',
      standardIpa: '/jespliːz/',
      targetFocusPhonemes: '/j/, /z/',
    ),
    Lesson(
      id: 16,
      title: 'Giao tiếp: No thank you',
      category: 'Giao tiếp',
      difficulty: 'Beginner',
      targetSentence: 'No thank you',
      standardIpa: '/noʊθæŋkjuː/',
      targetFocusPhonemes: '/θ/',
    ),
    Lesson(
      id: 17,
      title: 'Cảm xúc: I love you',
      category: 'Cảm xúc',
      difficulty: 'Beginner',
      targetSentence: 'I love you',
      standardIpa: '/aɪlʌvjuː/',
      targetFocusPhonemes: '/ʌ/, /v/',
    ),
    Lesson(
      id: 18,
      title: 'Số đếm: Three',
      category: 'Số đếm',
      difficulty: 'Beginner',
      targetSentence: 'Three',
      standardIpa: '/θriː/',
      targetFocusPhonemes: '/θ/, /r/',
    ),
    Lesson(
      id: 19,
      title: 'Số đếm: One two three',
      category: 'Số đếm',
      difficulty: 'Beginner',
      targetSentence: 'One two three',
      standardIpa: '/wʌntuːθriː/',
      targetFocusPhonemes: '/θ/',
    ),
    Lesson(
      id: 20,
      title: 'Giao tiếp: Have a nice day',
      category: 'Giao tiếp',
      difficulty: 'Beginner',
      targetSentence: 'Have a nice day',
      standardIpa: '/hævənaɪsdeɪ/',
      targetFocusPhonemes: '/v/, /s/',
    ),
  ];

  /// Lấy danh sách bài học
  Future<List<Lesson>> getLessons() async {
    try {
      final res = await _client.from('lessons').select().order('id');
      if (res.isNotEmpty) {
        return (res as List).map((e) => Lesson.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('[Supabase] Lỗi tải lessons, dùng danh sách fallback: $e');
    }
    return _localLessons;
  }

  /// Lấy hoặc tạo mới hồ sơ người dùng (kèm Streak thực tế từ CSDL)
  Future<UserProfile> getUserProfile(String uid, String email, String name) async {
    try {
      final res = await _client.from('profiles').select().eq('firebase_uid', uid).maybeSingle();
      if (res != null) {
        var profile = UserProfile.fromJson(res);
        // Kiểm tra xem chuỗi streak có bị đứt không (nếu bỏ lỡ > 1 ngày không học)
        if (profile.lastPracticeDate != null && profile.currentStreak > 0) {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final last = DateTime(
            profile.lastPracticeDate!.year,
            profile.lastPracticeDate!.month,
            profile.lastPracticeDate!.day,
          );
          final diff = today.difference(last).inDays;
          if (diff > 1) {
            // Đã quá 1 ngày không học -> reset streak về 0
            profile = UserProfile(
              firebaseUid: profile.firebaseUid,
              email: profile.email,
              displayName: profile.displayName,
              currentStreak: 0,
              maxStreak: profile.maxStreak,
              lastPracticeDate: profile.lastPracticeDate,
              dailyTargetMinutes: profile.dailyTargetMinutes,
              dailyTargetSentences: profile.dailyTargetSentences,
            );
            await _client.from('profiles').update({'current_streak': 0}).eq('firebase_uid', uid);
          }
        }
        return profile;
      } else {
        // Tài khoản mới toanh -> Khởi tạo với Streak = 0 (chưa học ngày nào)
        final newProfile = UserProfile(
          firebaseUid: uid,
          email: email,
          displayName: name,
          currentStreak: 0,
          maxStreak: 0,
          lastPracticeDate: null,
          dailyTargetMinutes: 15,
          dailyTargetSentences: 5,
        );
        await _client.from('profiles').insert(newProfile.toJson());
        return newProfile;
      }
    } catch (e) {
      debugPrint('[Supabase] Lỗi lấy profile: $e');
      return UserProfile(
        firebaseUid: uid,
        email: email,
        displayName: name,
        currentStreak: 0,
        maxStreak: 0,
        lastPracticeDate: null,
      );
    }
  }

  /// Lấy tiến độ mục tiêu hôm nay từ bảng daily_goals
  Future<Map<String, int>> getTodayGoal(String uid, {int defaultTargetMinutes = 15, int defaultTargetSentences = 5}) async {
    final todayStr = DateTime.now().toIso8601String().split('T').first;
    try {
      final res = await _client
          .from('daily_goals')
          .select()
          .eq('firebase_uid', uid)
          .eq('goal_date', todayStr)
          .maybeSingle();

      if (res != null) {
        return {
          'practiced_minutes': (res['practiced_minutes'] as num?)?.toInt() ?? 0,
          'target_minutes': (res['target_minutes'] as num?)?.toInt() ?? defaultTargetMinutes,
          'practiced_sentences': (res['practiced_sentences'] as num?)?.toInt() ?? 0,
          'target_sentences': (res['target_sentences'] as num?)?.toInt() ?? defaultTargetSentences,
        };
      }
    } catch (e) {
      debugPrint('[Supabase] Lỗi getTodayGoal: $e');
    }
    return {
      'practiced_minutes': 0,
      'target_minutes': defaultTargetMinutes,
      'practiced_sentences': 0,
      'target_sentences': defaultTargetSentences,
    };
  }

  /// Lấy thống kê số phút học trong 7 ngày (Thứ 2 -> Chủ nhật) từ practice_histories
  Future<List<double>> getWeeklyStudyMinutes(String uid) async {
    final now = DateTime.now();
    // 1: Thứ 2 (T2), ..., 7: Chủ nhật (CN)
    final currentMonday = now.subtract(Duration(days: now.weekday - 1));
    List<double> minutesPerDay = List.filled(7, 0.0);

    try {
      final mondayDateStr = DateTime(currentMonday.year, currentMonday.month, currentMonday.day)
          .toIso8601String()
          .split('T')
          .first;

      final res = await _client
          .from('practice_histories')
          .select('practiced_at, duration_seconds')
          .eq('firebase_uid', uid)
          .gte('practiced_at', mondayDateStr);

      for (var row in (res as List)) {
          final practicedAtStr = row['practiced_at']?.toString();
          if (practicedAtStr != null) {
            final pDate = DateTime.tryParse(practicedAtStr)?.toLocal();
            if (pDate != null) {
              final dayIndex = pDate.weekday - 1; // 0: T2 -> 6: CN
              if (dayIndex >= 0 && dayIndex < 7) {
                final sec = (row['duration_seconds'] as num?)?.toDouble() ?? 15.0;
                minutesPerDay[dayIndex] += (sec / 60.0);
              }
            }
          }
        }
    } catch (e) {
      debugPrint('[Supabase] Lỗi getWeeklyStudyMinutes: $e');
    }

    return minutesPerDay.map((m) => double.parse(m.toStringAsFixed(1))).toList();
  }

  /// Cập nhật chuỗi Streak sau khi hoàn thành bài phát âm thực tế
  Future<UserProfile> updateStreak(UserProfile currentProfile) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    int newStreak = currentProfile.currentStreak;
    int newMax = currentProfile.maxStreak;

    if (currentProfile.lastPracticeDate == null || currentProfile.currentStreak == 0) {
      // Bắt đầu chuỗi đầu tiên
      newStreak = 1;
    } else {
      final last = DateTime(
        currentProfile.lastPracticeDate!.year,
        currentProfile.lastPracticeDate!.month,
        currentProfile.lastPracticeDate!.day,
      );
      final diff = today.difference(last).inDays;
      if (diff == 0) {
        // Đã học hôm nay rồi -> Giữ nguyên chuỗi
        newStreak = currentProfile.currentStreak;
      } else if (diff == 1) {
        // Học tiếp vào ngày hôm sau -> Tăng streak lên 1
        newStreak = currentProfile.currentStreak + 1;
      } else {
        // Bỏ lỡ > 1 ngày -> Bắt đầu lại chuỗi mới = 1
        newStreak = 1;
      }
    }
    if (newStreak > newMax) newMax = newStreak;

    final updated = UserProfile(
      firebaseUid: currentProfile.firebaseUid,
      email: currentProfile.email,
      displayName: currentProfile.displayName,
      currentStreak: newStreak,
      maxStreak: newMax,
      lastPracticeDate: now,
      dailyTargetMinutes: currentProfile.dailyTargetMinutes,
      dailyTargetSentences: currentProfile.dailyTargetSentences,
    );

    try {
      await _client.from('profiles').upsert(updated.toJson());
    } catch (e) {
      debugPrint('[Supabase] Lỗi lưu streak: $e');
    }
    return updated;
  }

  /// Lưu lịch sử luyện tập
  Future<void> savePracticeHistory({
    required String uid,
    required int lessonId,
    required double overallScore,
    required double accuracyScore,
    required double fluencyScore,
    required double completenessScore,
    required String recognizedText,
    required String aiFeedback,
    String? audioUrl,
    int durationSeconds = 15,
  }) async {
    try {
      await _client.from('practice_histories').insert({
        'firebase_uid': uid,
        'lesson_id': lessonId,
        'overall_score': overallScore,
        'accuracy_score': accuracyScore,
        'fluency_score': fluencyScore,
        'completeness_score': completenessScore,
        'recognized_text': recognizedText,
        'ai_feedback_text': aiFeedback,
        'audio_storage_url': audioUrl,
        'duration_seconds': durationSeconds,
      });

      // Cập nhật tiến độ ngày vào daily_goals
      final todayStr = DateTime.now().toIso8601String().split('T').first;
      final existingGoal = await _client
          .from('daily_goals')
          .select()
          .eq('firebase_uid', uid)
          .eq('goal_date', todayStr)
          .maybeSingle();

      if (existingGoal != null) {
        int curSentences = (existingGoal['practiced_sentences'] ?? 0) + 1;
        int curMinutes = (existingGoal['practiced_minutes'] ?? 0) + (durationSeconds ~/ 60) + 1;
        bool isDone = curSentences >= (existingGoal['target_sentences'] ?? 5);

        await _client.from('daily_goals').update({
          'practiced_sentences': curSentences,
          'practiced_minutes': curMinutes,
          'is_completed': isDone,
        }).eq('id', existingGoal['id']);
      } else {
        await _client.from('daily_goals').insert({
          'firebase_uid': uid,
          'goal_date': todayStr,
          'practiced_sentences': 1,
          'practiced_minutes': 1,
          'target_sentences': 5,
          'target_minutes': 15,
          'is_completed': false,
        });
      }
    } catch (e) {
      debugPrint('[Supabase] Lỗi lưu practice history: $e');
    }
  }

  /// Lấy lịch sử luyện tập gần đây
  Future<List<PracticeHistory>> getRecentHistories(String uid) async {
    try {
      final res = await _client
          .from('practice_histories')
          .select()
          .eq('firebase_uid', uid)
          .order('practiced_at', ascending: false)
          .limit(10);
      return (res as List).map((e) => PracticeHistory.fromJson(e)).toList();
    } catch (e) {
      debugPrint('[Supabase] Lỗi tải histories: $e');
      return [];
    }
  }

  /// Tải file âm thanh lên Supabase Storage
  Future<String?> uploadAudio(String uid, int lessonId, Uint8List audioBytes) async {
    try {
      final fileName = '$uid/${lessonId}_${DateTime.now().millisecondsSinceEpoch}.wav';
      await _client.storage.from(SupabaseConfig.audioBucket).uploadBinary(fileName, audioBytes);
      return _client.storage.from(SupabaseConfig.audioBucket).getPublicUrl(fileName);
    } catch (e) {
      debugPrint('[Supabase Storage] Lỗi upload audio: $e');
      return null;
    }
  }
}
