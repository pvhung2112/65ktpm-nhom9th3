class PracticeHistory {
  final String id;
  final String firebaseUid;
  final int? lessonId;
  final String? audioStorageUrl;
  final double overallScore;
  final double accuracyScore;
  final double fluencyScore;
  final double completenessScore;
  final int durationSeconds;
  final String recognizedText;
  final String aiFeedbackText;
  final DateTime practicedAt;

  PracticeHistory({
    required this.id,
    required this.firebaseUid,
    this.lessonId,
    this.audioStorageUrl,
    required this.overallScore,
    required this.accuracyScore,
    required this.fluencyScore,
    required this.completenessScore,
    this.durationSeconds = 0,
    required this.recognizedText,
    required this.aiFeedbackText,
    required this.practicedAt,
  });

  factory PracticeHistory.fromJson(Map<String, dynamic> json) {
    return PracticeHistory(
      id: json['id'] ?? '',
      firebaseUid: json['firebase_uid'] ?? '',
      lessonId: json['lesson_id'],
      audioStorageUrl: json['audio_storage_url'],
      overallScore: (json['overall_score'] ?? 0.0).toDouble(),
      accuracyScore: (json['accuracy_score'] ?? 0.0).toDouble(),
      fluencyScore: (json['fluency_score'] ?? 0.0).toDouble(),
      completenessScore: (json['completeness_score'] ?? 0.0).toDouble(),
      durationSeconds: json['duration_seconds'] ?? 0,
      recognizedText: json['recognized_text'] ?? '',
      aiFeedbackText: json['ai_feedback_text'] ?? '',
      practicedAt: DateTime.tryParse(json['practiced_at'].toString()) ?? DateTime.now(),
    );
  }
}

