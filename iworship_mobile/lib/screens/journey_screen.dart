import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/qt_provider.dart';
import '../models/user_note.dart';

class JourneyScreen extends StatefulWidget {
  final bool isActive;
  final VoidCallback? onJumpToQt;

  const JourneyScreen({
    Key? key,
    this.isActive = false,
    this.onJumpToQt,
  }) : super(key: key);

  @override
  State<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends State<JourneyScreen> {
  DateTime _currentMonth = DateTime.now();
  String _activeFilter = 'all';
  List<UserNote> _monthNotes = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadMonthNotes();
  }

  @override
  void didUpdateWidget(covariant JourneyScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) {
      _loadMonthNotes();
    }
  }

  Future<void> _loadMonthNotes() async {
    setState(() => _loading = true);
    final provider = Provider.of<QtProvider>(context, listen: false);

    List<UserNote> allNotes = [];
    String monthPrefix = DateFormat('yyyy-MM').format(_currentMonth);

    final prefs = kIsWeb ? await SharedPreferences.getInstance() : null;

    for (int day = 1; day <= 31; day++) {
      String dayStr = '$monthPrefix-${day.toString().padLeft(2, '0')}';
      UserNote? note;

      if (kIsWeb && prefs != null) {
        String? jsonStr = prefs.getString('user_note_$dayStr');
        if (jsonStr != null && jsonStr.isNotEmpty) {
          try {
            note = UserNote.fromMap(json.decode(jsonStr));
          } catch (_) {}
        }
      } else {
        note = await provider.dbHelper.getUserNote(dayStr);
      }

      if (note != null &&
          (note.todayThanks.isNotEmpty ||
           note.engravedWord.isNotEmpty ||
           note.todayApplication.isNotEmpty ||
           note.todayPrayer.isNotEmpty ||
           note.sundayAnswer1.isNotEmpty ||
           note.sermonNote.isNotEmpty)) {
        allNotes.add(note);
      }
    }

    setState(() {
      _monthNotes = allNotes;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final qtProvider = Provider.of<QtProvider>(context);
    int daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    int completedCount = _monthNotes.where((n) =>
        n.todayThanks.isNotEmpty ||
        n.engravedWord.isNotEmpty ||
        n.sermonNote.isNotEmpty ||
        n.sundayAnswer1.isNotEmpty).length;

    int completionRate = daysInMonth > 0 ? ((completedCount / daysInMonth) * 100).toInt() : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('🧭 나의 묵상 여정', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () async {
              DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _currentMonth,
                firstDate: DateTime(2025),
                lastDate: DateTime(2030),
              );
              if (picked != null) {
                setState(() => _currentMonth = picked);
                _loadMonthNotes();
              }
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Month Selector Header with Navigation Arrows
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(Icons.chevron_left, color: Color(0xFF645179)),
                            onPressed: () {
                              setState(() {
                                _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
                              });
                              _loadMonthNotes();
                            },
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('yyyy년 MM월').format(_currentMonth),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF645179)),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(Icons.chevron_right, color: Color(0xFF645179)),
                            onPressed: () {
                              setState(() {
                                _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
                              });
                              _loadMonthNotes();
                            },
                          ),
                        ],
                      ),
                      Text('완료 ${completedCount}일 / $daysInMonth일', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Calendar Grid Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2DCD0)),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                    ),
                    child: Column(
                      children: [
                        // Weekday Names Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: ['일', '월', '화', '수', '목', '금', '토']
                              .map((w) => SizedBox(
                                    width: 36,
                                    child: Text(
                                      w,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: w == '일' ? Colors.red : (w == '토' ? Colors.blue : Colors.black87),
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                        const Divider(height: 20),

                        // Days Grid with proper day-of-week offset
                        Builder(
                          builder: (context) {
                            DateTime firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
                            int firstWeekdayOffset = firstDay.weekday % 7;
                            int totalGridCount = firstWeekdayOffset + daysInMonth;

                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 7,
                                mainAxisSpacing: 8,
                                crossAxisSpacing: 8,
                              ),
                              itemCount: totalGridCount,
                              itemBuilder: (context, index) {
                                if (index < firstWeekdayOffset) {
                                  return const SizedBox.shrink();
                                }
                                int dayNum = index - firstWeekdayOffset + 1;
                                String dateStr = '${DateFormat('yyyy-MM').format(_currentMonth)}-${dayNum.toString().padLeft(2, '0')}';
                                bool isCompleted = _monthNotes.any((n) => n.date == dateStr);

                                return GestureDetector(
                                  onTap: () {
                                    qtProvider.setDate(dateStr);
                                    if (widget.onJumpToQt != null) widget.onJumpToQt!();
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: isCompleted ? const Color(0xFF7C6893) : const Color(0xFFF7F5F0),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: dateStr == qtProvider.selectedDate ? Colors.redAccent : const Color(0xFFE2DCD0),
                                        width: dateStr == qtProvider.selectedDate ? 2 : 1,
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          '$dayNum',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: isCompleted ? Colors.white : Colors.black87,
                                          ),
                                        ),
                                        if (isCompleted)
                                          const Icon(Icons.check_circle, size: 10, color: Color(0xFFD6A5BC)),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Stats Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F4FA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2DCD0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text('$completionRate%', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF645179))),
                            const Text('묵상 달성률', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                        Container(height: 30, width: 1, color: const Color(0xFFE2DCD0)),
                        Column(
                          children: [
                            Text('$completedCount일', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF645179))),
                            const Text('완료 일수', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Filter Chips & Feed Section
                  const Text('📜 묵상 기록 피드', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF645179))),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      _buildFilterChip('전체', 'all'),
                      const SizedBox(width: 6),
                      _buildFilterChip('#감사', 'gratitude'),
                      const SizedBox(width: 6),
                      _buildFilterChip('#기도', 'prayer'),
                      const SizedBox(width: 6),
                      _buildFilterChip('#설교노트', 'sermon'),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Feed Items List
                  _monthNotes.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Text('작성된 묵상 기록이 없습니다.\n상단 묵상 탭에서 오늘의 말씀을 기록해 보세요!', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                          ),
                        )
                      : Column(
                          children: _monthNotes.map((note) {
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              child: ListTile(
                                title: Text(note.date, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF645179))),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 6.0),
                                  child: Text(
                                    note.todayThanks.isNotEmpty
                                        ? '🙏 감사: ${note.todayThanks}'
                                        : (note.sermonNote.isNotEmpty
                                            ? '✍️ 설교: ${note.sermonNote}'
                                            : '📖 묵상 기록 작성됨'),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                                onTap: () {
                                  qtProvider.setDate(note.date);
                                  if (widget.onJumpToQt != null) widget.onJumpToQt!();
                                },
                              ),
                            );
                          }).toList(),
                        ),
                ],
              ),
            ),
    );
  }

  Widget _buildFilterChip(String label, String code) {
    bool active = _activeFilter == code;
    return ChoiceChip(
      label: Text(label),
      selected: active,
      selectedColor: const Color(0xFF7C6893),
      labelStyle: TextStyle(color: active ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 12),
      onSelected: (val) {
        if (val) setState(() => _activeFilter = code);
      },
    );
  }
}
