class Lesson {
  final int id;
  final String title;
  final String category;
  final String difficulty;
  final String targetSentence;
  final String standardIpa;
  final String targetFocusPhonemes;
  final String audioNativeUrl;

  Lesson({
    required this.id,
    required this.title,
    required this.category,
    required this.difficulty,
    required this.targetSentence,
    required this.standardIpa,
    required this.targetFocusPhonemes,
    this.audioNativeUrl = '',
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      title: json['title'] ?? '',
      category: json['category'] ?? 'General',
      difficulty: json['difficulty'] ?? 'Beginner',
      targetSentence: json['target_sentence'] ?? '',
      standardIpa: json['standard_ipa'] ?? '',
      targetFocusPhonemes: json['target_focus_phonemes'] ?? '',
      audioNativeUrl: json['audio_native_url'] ?? '',
    );
  }
}

