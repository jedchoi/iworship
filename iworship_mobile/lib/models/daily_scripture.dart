class DailyScripture {
  final String date;
  final String title;
  final String passage;
  final List<VerseItem> verses;
  final String bgmCommentary;
  final String weeklyPrayCategory;
  final String weeklyPrayer;
  final String calligraphyText;
  final String calligraphyRef;

  DailyScripture({
    required this.date,
    required this.title,
    required this.passage,
    required this.verses,
    required this.bgmCommentary,
    required this.weeklyPrayCategory,
    required this.weeklyPrayer,
    required this.calligraphyText,
    required this.calligraphyRef,
  });

  factory DailyScripture.fromJson(Map<String, dynamic> json) {
    var rawVerses = json['verses'] ?? [];
    List<VerseItem> verseList = [];
    if (rawVerses is List) {
      verseList = rawVerses.map((v) => VerseItem.fromJson(v)).toList();
    }

    return DailyScripture(
      date: json['date'] ?? '',
      title: json['title'] ?? '',
      passage: json['passage'] ?? '',
      verses: verseList,
      bgmCommentary: json['bgm_commentary'] ?? '',
      weeklyPrayCategory: json['weekly_pray_category'] ?? '',
      weeklyPrayer: json['weekly_prayer'] ?? '',
      calligraphyText: json['calligraphy_text'] ?? '',
      calligraphyRef: json['calligraphy_ref'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'title': title,
      'passage': passage,
      'verses': verses.map((v) => v.toJson()).toList(),
      'bgm_commentary': bgmCommentary,
      'weekly_pray_category': weeklyPrayCategory,
      'weekly_prayer': weeklyPrayer,
      'calligraphy_text': calligraphyText,
      'calligraphy_ref': calligraphyRef,
    };
  }
}

class VerseItem {
  final int num;
  final String text;

  VerseItem({required this.num, required this.text});

  factory VerseItem.fromJson(Map<String, dynamic> json) {
    return VerseItem(
      num: json['num'] is int ? json['num'] : int.tryParse(json['num'].toString()) ?? 1,
      text: json['text'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'num': num,
      'text': text,
    };
  }
}
