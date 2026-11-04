class PronunciationResult {
  final double overallScore;
  final double accuracyScore;
  final double fluencyScore;
  final double completenessScore;
  final String generalFeedback;
  final List<String> weakPhonemes;
  final List<WordAnalysis> words;
  final String audioStorageUrl;
  final String spokenText;

  PronunciationResult({
    required this.overallScore,
    required this.accuracyScore,
    required this.fluencyScore,
    required this.completenessScore,
    required this.generalFeedback,
    required this.weakPhonemes,
    required this.words,
    this.audioStorageUrl = '',
    this.spokenText = '',
  });

  factory PronunciationResult.fromJson(Map<String, dynamic> json) {
    return PronunciationResult(
      overallScore: (json['overall_score'] ?? 0.0).toDouble(),
      accuracyScore: (json['accuracy_score'] ?? 0.0).toDouble(),
      fluencyScore: (json['fluency_score'] ?? 0.0).toDouble(),
      completenessScore: (json['completeness_score'] ?? 0.0).toDouble(),
      generalFeedback: json['general_feedback'] ?? '',
      weakPhonemes: List<String>.from(json['weak_phonemes'] ?? []),
      words: (json['words'] as List<dynamic>?)
              ?.map((w) => WordAnalysis.fromJson(w))
              .toList() ??
          [],
      audioStorageUrl: json['audio_storage_url'] ?? '',
      spokenText: json['spoken_text'] ?? '',
    );
  }
}

class WordAnalysis {
  final String word;
  final String standardIpa;
  final String userIpa;
  final double score;
  final String errorType; // CORRECT, SUBSTITUTION, OMISSION, INSERTION
  final String mouthTongueTip;
  final List<PhonemeMatch> phonemes;

  WordAnalysis({
    required this.word,
    required this.standardIpa,
    required this.userIpa,
    required this.score,
    required this.errorType,
    required this.mouthTongueTip,
    required this.phonemes,
  });

  factory WordAnalysis.fromJson(Map<String, dynamic> json) {
    return WordAnalysis(
      word: json['word'] ?? '',
      standardIpa: json['standard_ipa'] ?? '',
      userIpa: json['user_ipa'] ?? '',
      score: (json['score'] ?? 100.0).toDouble(),
      errorType: json['error_type'] ?? 'CORRECT',
      mouthTongueTip: json['mouth_tongue_tip'] ?? '',
      phonemes: (json['phonemes'] as List<dynamic>?)
              ?.map((p) => PhonemeMatch.fromJson(p))
              .toList() ??
          [],
    );
  }
}

class PhonemeMatch {
  final String standardPhoneme;
  final String userPhoneme;
  final bool isCorrect;

  PhonemeMatch({
    required this.standardPhoneme,
    required this.userPhoneme,
    required this.isCorrect,
  });

  factory PhonemeMatch.fromJson(Map<String, dynamic> json) {
    return PhonemeMatch(
      standardPhoneme: (json['standard_phoneme'] ?? json['standard'] ?? '').toString(),
      userPhoneme: (json['user_phoneme'] ?? json['user'] ?? '').toString(),
      isCorrect: json['is_correct'] ?? true,
    );
  }
}
