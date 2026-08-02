import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_note.dart';
import '../providers/qt_provider.dart';
import 'weekly_intro_dialog.dart';

class QtViewScreen extends StatefulWidget {
  const QtViewScreen({Key? key}) : super(key: key);

  @override
  State<QtViewScreen> createState() => _QtViewScreenState();
}

class _QtViewScreenState extends State<QtViewScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _lastLoadedDate;

  // Selected verse for inline memo box
  int? _selectedVerseNum;
  final Map<int, TextEditingController> _verseMemoCtrls = {};

  // Controllers for Weekday Page 2
  final TextEditingController _thanksCtrl = TextEditingController();
  final TextEditingController _engravedCtrl = TextEditingController();
  final TextEditingController _appCtrl = TextEditingController();
  final TextEditingController _prayerCtrl = TextEditingController();

  // Controllers for Sunday Page 1 Title & Page 2 IBS/Sermon
  final TextEditingController _sermonTitleCtrl = TextEditingController();
  final TextEditingController _ibs1Ctrl = TextEditingController();
  final TextEditingController _ibs2Ctrl = TextEditingController();
  final TextEditingController _ibs3Ctrl = TextEditingController();
  final TextEditingController _sermonCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  UserNote? _lastSyncedNote;

  void _syncControllersWithProvider(QtProvider provider) {
    bool isDateChanged = _lastLoadedDate != provider.selectedDate;
    bool isNoteChanged = _lastSyncedNote != provider.currentUserNote;

    if (!isDateChanged && !isNoteChanged) return;

    _lastLoadedDate = provider.selectedDate;
    _lastSyncedNote = provider.currentUserNote;
    if (isDateChanged) _selectedVerseNum = null;

    var note = provider.currentUserNote;
    if (note != null) {
      _sermonTitleCtrl.text = note.todayThanks;
      _thanksCtrl.text = note.todayThanks;
      _engravedCtrl.text = note.engravedWord;
      _appCtrl.text = note.todayApplication;
      _prayerCtrl.text = note.todayPrayer;
      _ibs1Ctrl.text = note.sundayAnswer1;
      _ibs2Ctrl.text = note.sundayAnswer2;
      _ibs3Ctrl.text = note.sundayAnswer3;
      _sermonCtrl.text = note.sermonNote;
    } else {
      _sermonTitleCtrl.clear();
      _thanksCtrl.clear();
      _engravedCtrl.clear();
      _appCtrl.clear();
      _prayerCtrl.clear();
      _ibs1Ctrl.clear();
      _ibs2Ctrl.clear();
      _ibs3Ctrl.clear();
      _sermonCtrl.clear();
    }

    if (isDateChanged) {
      _loadVerseMemosForDate(provider.selectedDate);
    }
  }

  Future<void> _loadVerseMemosForDate(String dateStr) async {
    final prefs = await SharedPreferences.getInstance();
    String key = 'verse_memos_$dateStr';
    String? raw = prefs.getString(key);
    _verseMemoCtrls.clear();
    if (raw != null && raw.isNotEmpty) {
      try {
        Map<String, dynamic> map = json.decode(raw);
        map.forEach((vNumStr, memoText) {
          int? vNum = int.tryParse(vNumStr);
          if (vNum != null && memoText is String && memoText.isNotEmpty) {
            _verseMemoCtrls[vNum] = TextEditingController(text: memoText);
          }
        });
      } catch (e) {
        if (kDebugMode) print('Verse memo load error: $e');
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _saveVerseMemo(String dateStr, int verseNum, String text) async {
    final prefs = await SharedPreferences.getInstance();
    String key = 'verse_memos_$dateStr';
    String? raw = prefs.getString(key);
    Map<String, dynamic> map = {};
    if (raw != null && raw.isNotEmpty) {
      try {
        map = json.decode(raw);
      } catch (_) {}
    }
    if (text.trim().isEmpty) {
      map.remove(verseNum.toString());
    } else {
      map[verseNum.toString()] = text;
    }
    await prefs.setString(key, json.encode(map));
  }

  void _autoSaveUserNote(QtProvider provider) {
    if (provider.isSunday) {
      provider.saveUserNoteSilently(
        todayThanks: _sermonTitleCtrl.text,
        sundayAnswer1: _ibs1Ctrl.text,
        sundayAnswer2: _ibs2Ctrl.text,
        sundayAnswer3: _ibs3Ctrl.text,
        sermonNote: _sermonCtrl.text,
      );
    } else {
      provider.saveUserNoteSilently(
        todayThanks: _thanksCtrl.text,
        engravedWord: _engravedCtrl.text,
        todayApplication: _appCtrl.text,
        todayPrayer: _prayerCtrl.text,
      );
    }
    _lastSyncedNote = provider.currentUserNote;
  }

  void _toggleVerseSelection(int verseNum) {
    setState(() {
      if (_selectedVerseNum == verseNum) {
        _selectedVerseNum = null;
      } else {
        _selectedVerseNum = verseNum;
        _verseMemoCtrls.putIfAbsent(verseNum, () => TextEditingController());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final qtProvider = Provider.of<QtProvider>(context);
    _syncControllersWithProvider(qtProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top App Header: Week Selector & 7-Day Horizontal Strip
            _buildTopWeekHeader(context, qtProvider),

            // 2. Page 1 (말씀 읽기) vs Page 2 (묵상 작성) TabBar Indicator
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF645179),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFF645179),
                tabs: const [
                  Tab(text: '📖 1. 말씀 읽기'),
                  Tab(text: '✍️ 2. 묵상 작성'),
                ],
              ),
            ),

            Expanded(
              child: qtProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        // Page 1: Scripture Reading with Inline Verse Memo & Highlight
                        _buildScripturePage1(context, qtProvider),

                        // Page 2: Dynamic Meditation Form (Sunday IBS vs Weekday 4-Cards)
                        _buildMeditationPage2(context, qtProvider),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // === 1. Top Week Selector Header & 7-Day Horizontal Calendar Strip ===
  Widget _buildTopWeekHeader(BuildContext context, QtProvider provider) {
    List<DateTime> dates = provider.weeklyDates;

    return Container(
      color: const Color(0xFF645179),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Week Selector Dropdown Button (Opens Weekly Intro Modal)
              InkWell(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => WeeklyIntroDialog(weeklyIntro: provider.currentWeeklyIntro),
                  );
                },
                child: Row(
                  children: [
                    Text(
                      provider.currentWeekLabel,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_drop_down, color: Colors.white),
                  ],
                ),
              ),

              // Date Picker Shortcut
              IconButton(
                icon: const Icon(Icons.calendar_month, color: Colors.white, size: 20),
                onPressed: () async {
                  DateTime currentDt = DateTime.tryParse(provider.selectedDate) ?? DateTime.now();
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: currentDt,
                    firstDate: DateTime(2025),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    provider.setDate(DateFormat('yyyy-MM-dd').format(picked));
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 7-Day Horizontal Calendar Strip: Fits 100% of Screen Width with Swipe Gesture
          GestureDetector(
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity != null) {
                if (details.primaryVelocity! < -100) {
                  // Swiped left -> Next week
                  setState(() => _selectedVerseNum = null);
                  provider.nextWeek();
                } else if (details.primaryVelocity! > 100) {
                  // Swiped right -> Previous week
                  setState(() => _selectedVerseNum = null);
                  provider.previousWeek();
                }
              }
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: dates.map((d) {
                String dateStr = DateFormat('yyyy-MM-dd').format(d);
                bool isSelected = dateStr == provider.selectedDate;
                String dayName = ['일', '월', '화', '수', '목', '금', '토'][d.weekday % 7];
                bool isSun = d.weekday == DateTime.sunday;

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _selectedVerseNum = null);
                      provider.setDate(dateStr);
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFD6A5BC) : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            dayName,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isSun ? (isSelected ? Colors.white : Colors.redAccent) : Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${d.day}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.black87 : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // === 2. Page 1: Scripture Reading with Inline Verse Memo & Selection Highlight ===
  Widget _buildScripturePage1(BuildContext context, QtProvider provider) {
    var scripture = provider.currentScripture;

    if (scripture == null) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.auto_stories, size: 64, color: Color(0xFFB5A9C9)),
              const SizedBox(height: 16),
              Text(
                '📖 [${provider.selectedDate}] 묵상 본문 준비 중',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF645179)),
              ),
              const SizedBox(height: 8),
              const Text(
                '선택하신 날짜의 말씀 묵상 본문이 아직 준비 중입니다.\n데이터가 등록되면 이 날짜 화면에 바로 업데이트됩니다.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13.5, height: 1.5),
              ),
            ],
          ),
        ),
      );
    }

    double baseFontSize = provider.fontSize;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title & Passage Header
          if (provider.isSunday || scripture.title.isEmpty) ...[
            TextField(
              controller: _sermonTitleCtrl,
              onChanged: (val) {
                provider.saveUserNoteSilently(
                  todayThanks: val,
                  sundayAnswer1: _ibs1Ctrl.text,
                  sundayAnswer2: _ibs2Ctrl.text,
                  sundayAnswer3: _ibs3Ctrl.text,
                  sermonNote: _sermonCtrl.text,
                );
                _lastSyncedNote = provider.currentUserNote;
              },
              style: TextStyle(
                fontSize: baseFontSize + 5,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF645179),
              ),
              decoration: InputDecoration(
                hintText: '✍️ 주일 설교 / 묵상 제목을 입력하세요',
                hintStyle: TextStyle(
                  fontSize: baseFontSize + 3,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFB5A9C9),
                ),
                isDense: true,
                border: InputBorder.none,
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFE2DCD0), width: 1.5),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF645179), width: 2),
                ),
                contentPadding: const EdgeInsets.only(bottom: 6, top: 2),
              ),
            ),
            const SizedBox(height: 10),
          ] else ...[
            Text(
              scripture.title,
              style: TextStyle(
                fontSize: baseFontSize + 5,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF645179),
              ),
            ),
            const SizedBox(height: 6),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEADA54),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              scripture.passage,
              style: TextStyle(
                fontSize: (baseFontSize - 2).clamp(12.0, 24.0),
                fontWeight: FontWeight.bold,
                color: const Color(0xFF4A3B5C),
              ),
            ),
          ),
          const Divider(height: 24, thickness: 1),

          // Verses List with In-line Selection Highlight & Always-Visible Note Box
          ...scripture.verses.map((v) {
            bool isVerseSelected = _selectedVerseNum == v.num;
            TextEditingController memoCtrl = _verseMemoCtrls.putIfAbsent(v.num, () => TextEditingController());
            bool hasMemo = memoCtrl.text.trim().isNotEmpty;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Verse Text Row (Highlighted when selected)
                InkWell(
                  onTap: () => _toggleVerseSelection(v.num),
                  borderRadius: BorderRadius.circular(8),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: isVerseSelected ? const Color(0xFFF3EDF7) : (hasMemo ? const Color(0xFFFAF7FC) : Colors.transparent),
                      borderRadius: BorderRadius.circular(8),
                      border: isVerseSelected ? Border.all(color: const Color(0xFF8E7CA2), width: 1.5) : (hasMemo ? Border.all(color: const Color(0xFFD6CBE3), width: 1) : null),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${v.num} ',
                          style: TextStyle(
                            fontSize: baseFontSize,
                            fontWeight: FontWeight.bold,
                            color: isVerseSelected ? const Color(0xFF645179) : const Color(0xFF7C6893),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            v.text,
                            style: TextStyle(
                              fontSize: baseFontSize,
                              height: 1.6,
                              color: const Color(0xFF333333),
                              fontWeight: isVerseSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Inline Verse Memo Box (Always visible if selected OR has written content)
                if (isVerseSelected || hasMemo) ...[
                  Container(
                    margin: const EdgeInsets.only(left: 24, right: 24, top: 6, bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isVerseSelected ? const Color(0xFFF7F5F0) : const Color(0xFFFBF9FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isVerseSelected ? const Color(0xFF7C6893) : const Color(0xFFE2DCD0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '💬 ${v.num}절 묵상 메모',
                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF645179)),
                            ),
                            if (hasMemo && !isVerseSelected)
                              const Text(
                                '✔️ 작성됨',
                                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: memoCtrl,
                          maxLines: 2,
                          style: const TextStyle(fontSize: 13.5),
                          decoration: const InputDecoration(
                            hintText: '이 구절에 대한 내 묵상 메모를 적으세요...',
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (val) {
                            _saveVerseMemo(provider.selectedDate, v.num, val);
                          },
                        ),

                        // "+ 아로새길말씀" Button (Hidden on Sundays)
                        if (!provider.isSunday) ...[
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.bookmark_add, size: 14),
                              label: const Text('+ 아로새길말씀', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF7C6893),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                              onPressed: () {
                                provider.appendEngravedWord('${v.num}절: ${v.text}');
                                _autoSaveUserNote(provider);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('🎉 ${v.num}절이 "아로새길 말씀"에 추가되었습니다!')),
                                );
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            );
          }).toList(),

          // Always Exposed 말씀 BGM Section at Bottom
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F6FB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2DCD0)),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.music_note, color: Color(0xFF7C6893)),
                    SizedBox(width: 6),
                    Text(
                      '💡 말씀 BGM / 본문 해설',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF645179),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  scripture.bgmCommentary.isNotEmpty ? scripture.bgmCommentary : '오늘의 본문 해설 준비 중입니다.',
                  style: TextStyle(
                    fontSize: (baseFontSize - 2).clamp(12.0, 24.0),
                    height: 1.6,
                    color: const Color(0xFF555555),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // === 3. Page 2: Dynamic Meditation Form (Sunday IBS vs Weekday 4-Cards) ===
  Widget _buildMeditationPage2(BuildContext context, QtProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (provider.isSunday) ...[
            // === SUNDAY FORM ===
            _buildSectionHeader('📖 주일 IBS (3가지 나눔 질문)'),
            _buildInputCard('1. 오늘 말씀을 통해 알게 된 하나님은 어떠한 하나님인가요?', _ibs1Ctrl, onChanged: () => _autoSaveUserNote(provider)),
            _buildInputCard('2. 오늘 말씀을 통해 깨달은 것과 받은 은혜는 무엇인가요?', _ibs2Ctrl, onChanged: () => _autoSaveUserNote(provider)),
            _buildInputCard('3. 나는 한 주간 어떤 삶을 살 것인지 다짐하고 함께 나누어 봅시다.', _ibs3Ctrl, onChanged: () => _autoSaveUserNote(provider)),
            const SizedBox(height: 20),
            _buildSectionHeader('✍️ 주일 설교 NOTE (설교 제목 & 메시지 메모)'),
            _buildInputCard('설교 제목 및 본문 요약 메모를 자유롭게 적어보세요', _sermonCtrl, maxLines: 8, onChanged: () => _autoSaveUserNote(provider)),
          ] else ...[
            // === WEEKDAY FORM ===
            _buildSectionHeader('🔥 우모하 기도발전소'),
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F4FA),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2DCD0)),
              ),
              child: Text(
                provider.currentScripture?.weeklyPrayer.isNotEmpty == true
                    ? '• ${provider.currentScripture?.weeklyPrayCategory}: "${provider.currentScripture?.weeklyPrayer}"'
                    : '• 공동체 기도: "우리 가정이 말씀 안에 바로 서도록 인도하소서."',
                style: const TextStyle(fontSize: 13.5, color: Color(0xFF645179), fontWeight: FontWeight.w600),
              ),
            ),
            _buildInputCard('1. 오늘의 감사', _thanksCtrl, onChanged: () => _autoSaveUserNote(provider)),
            _buildInputCard('2. 아로새길 말씀 (1페이지 구절 터치 시 자동 추가 가능)', _engravedCtrl, onChanged: () => _autoSaveUserNote(provider)),
            _buildInputCard('3. 오늘의 적용', _appCtrl, onChanged: () => _autoSaveUserNote(provider)),
            _buildInputCard('4. 오늘의 기도 (주신 말씀으로 살아낼 은혜를 구하는 기도)', _prayerCtrl, onChanged: () => _autoSaveUserNote(provider)),
          ],

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('묵상 기록 수동 백업 동기화', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C6893),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                _autoSaveUserNote(provider);
                await provider.triggerSyncPush();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('🎉 묵상 기록이 로컬에 저장되고 서버로 백업 동기화되었습니다!')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF645179)),
      ),
    );
  }

  Widget _buildInputCard(String label, TextEditingController controller, {int maxLines = 3, VoidCallback? onChanged}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2DCD0)),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            maxLines: maxLines,
            decoration: const InputDecoration(
              hintText: '내용을 작성하세요...',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.all(10),
            ),
            onChanged: (_) {
              if (onChanged != null) onChanged();
            },
          ),
        ],
      ),
    );
  }
}
