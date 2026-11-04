class UserProfile {
  final String firebaseUid;
  final String email;
  final String displayName;
  final String avatarUrl;
  final int currentStreak;
  final int maxStreak;
  final DateTime? lastPracticeDate;
  final int dailyTargetMinutes;
  final int dailyTargetSentences;

  UserProfile({
    required this.firebaseUid,
    required this.email,
    required this.displayName,
    this.avatarUrl = '',
    this.currentStreak = 0,
    this.maxStreak = 0,
    this.lastPracticeDate,
    this.dailyTargetMinutes = 15,
    this.dailyTargetSentences = 5,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      firebaseUid: json['firebase_uid'] ?? '',
      email: json['email'] ?? '',
      displayName: json['display_name'] ?? 'Học viên',
      avatarUrl: json['avatar_url'] ?? '',
      currentStreak: json['current_streak'] ?? 0,
      maxStreak: json['max_streak'] ?? 0,
      lastPracticeDate: json['last_practice_date'] != null
          ? DateTime.tryParse(json['last_practice_date'].toString())
          : null,
      dailyTargetMinutes: json['daily_target_minutes'] ?? 15,
      dailyTargetSentences: json['daily_target_sentences'] ?? 5,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'firebase_uid': firebaseUid,
      'email': email,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'current_streak': currentStreak,
      'max_streak': maxStreak,
      'last_practice_date': lastPracticeDate?.toIso8601String().split('T').first,
      'daily_target_minutes': dailyTargetMinutes,
      'daily_target_sentences': dailyTargetSentences,
    };
  }
}

