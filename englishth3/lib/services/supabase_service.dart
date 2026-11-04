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

  // Cache dữ liệu cục bộ để app chạy mượt mà
  final List<Lesson> _localLessons = [
    Lesson(
      id: 11,
      title: 'Từ vựng: Xin chào',
      category: 'Vocabulary',
      difficulty: 'Beginner',
      targetSentence: 'Hello',
      standardIpa: '/həˈloʊ/',
      targetFocusPhonemes: '/h/, /oʊ/',
    ),
    Lesson(
      id: 12,
      title: 'Từ vựng: Số ba (Âm /θ/)',
      category: 'Vocabulary',
      difficulty: 'Beginner',
      targetSentence: 'Three',
      standardIpa: '/θriː/',
      targetFocusPhonemes: '/θ/, /r/',
    ),
    Lesson(
      id: 13,
      title: 'Từ vựng: Cảm ơn',
      category: 'Vocabulary',
      difficulty: 'Beginner',
      targetSentence: 'Thank you',
      standardIpa: '/ˈθæŋk juː/',
      targetFocusPhonemes: '/θ/, /ŋ/',
    ),
    Lesson(
      id: 14,
      title: 'Từ vựng: Quả táo',
      category: 'Vocabulary',
      difficulty: 'Beginner',
      targetSentence: 'Apple',
      standardIpa: '/ˈæpəl/',
      targetFocusPhonemes: '/æ/, /p/, /l/',
    ),
    Lesson(
      id: 15,
      title: 'Từ vựng: Nước uống',
      category: 'Vocabulary',
      difficulty: 'Beginner',
      targetSentence: 'Water',
      standardIpa: '/ˈwɔːtər/',
      targetFocusPhonemes: '/w/, /t/',
    ),
    Lesson(
      id: 16,
      title: 'Từ vựng: Cà phê',
      category: 'Vocabulary',
      difficulty: 'Beginner',
      targetSentence: 'Coffee',
      standardIpa: '/ˈkɔːfi/',
      targetFocusPhonemes: '/k/, /f/',
    ),
    Lesson(
      id: 17,
      title: 'Từ vựng: Chào buổi sáng',
      category: 'Vocabulary',
      difficulty: 'Beginner',
      targetSentence: 'Good morning',
      standardIpa: '/ɡʊd ˈmɔːrnɪŋ/',
      targetFocusPhonemes: '/ɡ/, /ʊ/, /ŋ/',
    ),
    Lesson(
      id: 18,
      title: 'Từ vựng: Tạm biệt',
      category: 'Vocabulary',
      difficulty: 'Beginner',
      targetSentence: 'Goodbye',
      standardIpa: '/ɡʊdˈbaɪ/',
      targetFocusPhonemes: '/d/, /aɪ/',
    ),
    Lesson(
      id: 1,
      title: 'Giao tiếp hàng ngày 1',
      category: 'Daily Life',
      difficulty: 'Beginner',
      targetSentence: 'I think that is right.',
      standardIpa: '/aɪ θɪŋk ðæt ɪz raɪt/',
      targetFocusPhonemes: '/θ/, /ð/',
    ),
    Lesson(
      id: 2,
      title: 'Giao tiếp hàng ngày 2',
      category: 'Daily Life',
      difficulty: 'Beginner',
      targetSentence: 'Thank you very much for your help.',
      standardIpa: '/θæŋk juː ˈveri mʌtʃ fɔːr jɔːr help/',
      targetFocusPhonemes: '/θ/, /tʃ/',
    ),
    Lesson(
      id: 3,
      title: 'Cặp âm tối thiểu /θ/ và /s/',
      category: 'Minimal Pairs',
      difficulty: 'Intermediate',
      targetSentence: 'Think and sink are different words.',
      standardIpa: '/θɪŋk ænd sɪŋk ɑːr ˈdɪfrənt wɜːrdz/',
      targetFocusPhonemes: '/θ/, /s/',
    ),
    Lesson(
      id: 4,
      title: 'Cặp âm tối thiểu /r/ và /l/',
      category: 'Minimal Pairs',
      difficulty: 'Intermediate',
      targetSentence: 'Red lorry yellow lorry.',
      standardIpa: '/red ˈlɒri ˈjeləʊ ˈlɒri/',
      targetFocusPhonemes: '/r/, /l/',
    ),
    Lesson(
      id: 5,
      title: 'Thử thách âm đuôi /s/, /t/',
      category: 'Pronunciation Challenge',
      difficulty: 'Intermediate',
      targetSentence: 'She likes facts and statistics.',
      standardIpa: '/ʃiː laɪks fækts ænd stəˈtɪstɪks/',
      targetFocusPhonemes: '/ks/, /kts/',
    ),
    Lesson(
      id: 6,
      title: 'Môi trường công sở',
      category: 'Business',
      difficulty: 'Advanced',
      targetSentence: 'We appreciate your dedication to this project.',
      standardIpa: '/wiː əˈpriːʃieɪt jɔːr ˌdedɪˈkeɪʃn tuː ðɪs ˈprɒdʒekt/',
      targetFocusPhonemes: '/ʃ/, /dʒ/',
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
