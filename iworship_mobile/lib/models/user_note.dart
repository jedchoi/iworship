class UserNote {
  final String date;
  final String todayThanks;
  final String engravedWord;
  final String todayApplication;
  final String todayPrayer;
  final String sundayAnswer1;
  final String sundayAnswer2;
  final String sundayAnswer3;
  final String sermonNote;
  final String updatedAt;
  final int isSynced;

  UserNote({
    required this.date,
    this.todayThanks = '',
    this.engravedWord = '',
    this.todayApplication = '',
    this.todayPrayer = '',
    this.sundayAnswer1 = '',
    this.sundayAnswer2 = '',
    this.sundayAnswer3 = '',
    this.sermonNote = '',
    required this.updatedAt,
    this.isSynced = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'today_thanks': todayThanks,
      'engraved_word': engravedWord,
      'today_application': todayApplication,
      'today_prayer': todayPrayer,
      'sunday_answer1': sundayAnswer1,
      'sunday_answer2': sundayAnswer2,
      'sunday_answer3': sundayAnswer3,
      'sermon_note': sermonNote,
      'updated_at': updatedAt,
      'is_synced': isSynced,
    };
  }

  factory UserNote.fromMap(Map<String, dynamic> map) {
    return UserNote(
      date: map['date'] ?? '',
      todayThanks: map['today_thanks'] ?? '',
      engravedWord: map['engraved_word'] ?? '',
      todayApplication: map['today_application'] ?? '',
      todayPrayer: map['today_prayer'] ?? '',
      sundayAnswer1: map['sunday_answer1'] ?? '',
      sundayAnswer2: map['sunday_answer2'] ?? '',
      sundayAnswer3: map['sunday_answer3'] ?? '',
      sermonNote: map['sermon_note'] ?? '',
      updatedAt: map['updated_at'] ?? DateTime.now().toIso8601String(),
      isSynced: map['is_synced'] ?? 0,
    );
  }
}
