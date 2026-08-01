class WeeklyIntroModel {
  final String weekNumber;
  final String startDate;
  final String calligraphyImageUrl;
  final String calligraphyScripture;
  final List<WeeklyScheduleItem> schedule;

  WeeklyIntroModel({
    required this.weekNumber,
    required this.startDate,
    required this.calligraphyImageUrl,
    required this.calligraphyScripture,
    required this.schedule,
  });

  factory WeeklyIntroModel.fromJson(Map<String, dynamic> json) {
    var rawList = json['weekly_schedule'] ?? [];
    List<WeeklyScheduleItem> items = [];
    if (rawList is List) {
      items = rawList.map((x) => WeeklyScheduleItem.fromJson(x)).toList();
    }

    return WeeklyIntroModel(
      weekNumber: json['week_number'] ?? '',
      startDate: json['start_date'] ?? '',
      calligraphyImageUrl: json['calligraphy_image_url'] ?? '',
      calligraphyScripture: json['calligraphy_scripture'] ?? '',
      schedule: items,
    );
  }
}

class WeeklyScheduleItem {
  final String date;
  final String day;
  final String passage;
  final String title;

  WeeklyScheduleItem({
    required this.date,
    required this.day,
    required this.passage,
    required this.title,
  });

  factory WeeklyScheduleItem.fromJson(Map<String, dynamic> json) {
    return WeeklyScheduleItem(
      date: json['date'] ?? '',
      day: json['day'] ?? '',
      passage: json['passage'] ?? '',
      title: json['title'] ?? '',
    );
  }
}
