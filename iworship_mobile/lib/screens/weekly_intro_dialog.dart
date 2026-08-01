import 'package:flutter/material.dart';
import '../models/weekly_intro.dart';

class WeeklyIntroDialog extends StatelessWidget {
  final WeeklyIntroModel? weeklyIntro;

  const WeeklyIntroDialog({Key? key, this.weeklyIntro}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (weeklyIntro == null) {
      return AlertDialog(
        title: const Text('주간 안내'),
        content: const Text('해당 주간의 모달 정보를 찾을 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      );
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 650),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '🗓️ ${weeklyIntro!.weekNumber}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF645179),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  )
                ],
              ),
              const SizedBox(height: 12),

              // 캘리그라피 문구 카드
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F4FA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2DCD0)),
                ),
                child: Text(
                  weeklyIntro!.calligraphyScripture.isNotEmpty
                      ? weeklyIntro!.calligraphyScripture
                      : '말씀을 가까이하는 복된 주간이 되기를 소망합니다.',
                  style: const TextStyle(
                    fontSize: 15,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFF333333),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                '📅 주간 성경 공부 / QT 일정표',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF645179),
                ),
              ),
              const SizedBox(height: 10),

              // 일정표 테이블
              Table(
                border: TableBorder.all(color: const Color(0xFFE2DCD0), width: 1),
                columnWidths: const {
                  0: FlexColumnWidth(1.2),
                  1: FlexColumnWidth(2.0),
                  2: FlexColumnWidth(2.5),
                },
                children: [
                  const TableRow(
                    decoration: BoxDecoration(color: Color(0xFFF2ECE4)),
                    children: [
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('날짜', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('성경 본문', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('말씀 제목', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  ...weeklyIntro!.schedule.map((item) {
                    bool isSun = item.day == '주일';
                    return TableRow(
                      decoration: BoxDecoration(
                        color: isSun ? const Color(0xFFFFF8F8) : Colors.white,
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            '${item.day}\n${item.date.substring(5)}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSun ? FontWeight.bold : FontWeight.normal,
                              color: isSun ? Colors.red : Colors.black87,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            item.passage,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            isSun && item.title.isEmpty ? '(설교시간 제목 작성)' : item.title,
                            style: TextStyle(
                              fontSize: 13,
                              color: isSun && item.title.isEmpty ? Colors.grey : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
