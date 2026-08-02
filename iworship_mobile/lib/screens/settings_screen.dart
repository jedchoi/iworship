import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/qt_provider.dart';
import '../models/user_note.dart';

class SettingsScreen extends StatefulWidget {
  final bool isActive;
  const SettingsScreen({Key? key, this.isActive = true}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with WidgetsBindingObserver {
  late TextEditingController _urlCtrl;
  late TextEditingController _deviceIdCtrl;
  bool _showServerSettings = false;
  int _titleTapCount = 0;
  DateTime? _lastTapTime;

  @override
  void initState() {
    super.initState();
    _urlCtrl = TextEditingController();
    _deviceIdCtrl = TextEditingController();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _urlCtrl.dispose();
    _deviceIdCtrl.dispose();
    super.dispose();
  }

  @override
  void deactivate() {
    _hideServerSettings();
    super.deactivate();
  }

  @override
  void didUpdateWidget(covariant SettingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive && !widget.isActive) {
      _hideServerSettings();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _hideServerSettings();
    }
  }

  void _hideServerSettings() {
    if (_showServerSettings || _titleTapCount > 0) {
      setState(() {
        _showServerSettings = false;
        _titleTapCount = 0;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    var provider = Provider.of<QtProvider>(context, listen: false);
    _urlCtrl.text = provider.apiService.baseUrl;
    _deviceIdCtrl.text = provider.deviceId;
  }

  void _onTitleTapped() {
    final now = DateTime.now();
    if (_lastTapTime != null && now.difference(_lastTapTime!).inMilliseconds > 1500) {
      _titleTapCount = 0;
    }
    _lastTapTime = now;
    _titleTapCount++;

    if (_titleTapCount >= 10) {
      setState(() {
        _showServerSettings = !_showServerSettings;
        _titleTapCount = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<QtProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: _onTitleTapped,
          behavior: HitTestBehavior.opaque,
          child: const Text('⚙️ 설정 & 동기화', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 항상 노출: 성경 폰트 크기 설정
            const Text(
              '🔤 성경 폰트 크기 설정',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF645179)),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2DCD0)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('현재 폰트 크기:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('${provider.fontSize.toInt()} px', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF7C6893))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('가', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      Expanded(
                        child: Slider(
                          value: provider.fontSize,
                          min: 13.0,
                          max: 26.0,
                          divisions: 13,
                          label: '${provider.fontSize.toInt()} px',
                          activeColor: const Color(0xFF7C6893),
                          onChanged: (val) {
                            provider.setFontSize(val);
                          },
                        ),
                      ),
                      const Text('가', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),

            // 2. 개발자 모드 (10회 연속 탭 시 노출)
            if (_showServerSettings) ...[
              const Divider(height: 40, thickness: 1),

              const Text(
                '🌐 백엔드 동기화 서버 주소 설정 (개발자 전용)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF645179)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _urlCtrl,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'http://localhost:8000 또는 http://192.168.0.100:8000',
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.cloud_done, size: 16),
                    label: const Text('☁️ 오라클 실서버 (168.110.63.231:8000)'),
                    onPressed: () {
                      _urlCtrl.text = 'http://168.110.63.231:8000';
                    },
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.phone_android, size: 16),
                    label: const Text('📱 스마트폰 (192.168.45.21)'),
                    onPressed: () {
                      _urlCtrl.text = 'http://192.168.45.21:8000';
                    },
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.computer, size: 16),
                    label: const Text('💻 에뮬레이터 (10.0.2.2)'),
                    onPressed: () {
                      _urlCtrl.text = 'http://10.0.2.2:8000';
                    },
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.language, size: 16),
                    label: const Text('🖥️ 로컬 (localhost)'),
                    onPressed: () {
                      _urlCtrl.text = 'http://localhost:8000';
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  provider.updateServerUrl(_urlCtrl.text.trim());
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('서버 연결 주소가 업데이트되었습니다!')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C6893),
                  foregroundColor: Colors.white,
                ),
                child: const Text('서버 주소 저장'),
              ),
              const Divider(height: 32, thickness: 1),

              const Text(
                '🔄 오프라인 데이터 백업 & 수동 동기화 (개발자 전용)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF645179)),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F5F0),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2DCD0)),
                ),
                child: const Text(
                  '💡 새 스마트폰으로 변경 시 복원 방법:\n기존 기기에 표시되던 [백업 동기화 코드]를 새 스마트폰의 아래 입력란에 동일하게 입력하신 후 [서버 기록 복원]을 누르시면 작성하셨던 모든 묵상 일지가 1:1로 원상 복원됩니다!',
                  style: TextStyle(fontSize: 12.5, color: Color(0xFF555555), height: 1.4),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _deviceIdCtrl,
                      decoration: const InputDecoration(
                        labelText: '🔑 내 백업 동기화 코드 (Sync ID)',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      provider.updateDeviceId(_deviceIdCtrl.text);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('🔑 동기화 코드가 [${provider.deviceId}]로 저장되었습니다.')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C6893),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    ),
                    child: const Text('코드 변경'),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.cloud_upload),
                      label: const Text('내 묵상 서버 백업 (Push)'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: const Color(0xFF645179),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        await provider.triggerSyncPush();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('🎉 [${provider.deviceId}] 코드로 묵상 기록이 서버에 성공적으로 백업되었습니다!')),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.cloud_download),
                      label: const Text('서버 기록 복원 (Pull)'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF645179),
                        side: const BorderSide(color: Color(0xFF645179)),
                      ),
                      onPressed: () async {
                        String activeId = provider.deviceId;
                        List<UserNote> restored = await provider.apiService.pullSyncNotes(activeId);
                        if (restored.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('⚠️ [$activeId] 동기화 코드로 저장된 백업 데이터가 없습니다.')),
                          );
                        } else {
                          for (var note in restored) {
                            await provider.dbHelper.upsertUserNote(note);
                          }
                          await provider.loadDataForDate(provider.selectedDate);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('🎉 [$activeId] 코드로 ${restored.length}개의 묵상 기록을 성공적으로 복원했습니다!')),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
