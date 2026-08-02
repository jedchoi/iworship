import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/qt_provider.dart';
import '../models/user_note.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _urlCtrl;

  @override
  void initState() {
    super.initState();
    _urlCtrl = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _urlCtrl.text = Provider.of<QtProvider>(context, listen: false).apiService.baseUrl;
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<QtProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('⚙️ 설정 & 동기화', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🌐 백엔드 동기화 서버 주소 설정',
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

            const Divider(height: 40, thickness: 1),

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

            const Divider(height: 40, thickness: 1),

            const Text(
              '🔄 오프라인 데이터 백업 & 수동 동기화',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF645179)),
            ),
            const SizedBox(height: 8),
            const Text(
              '아이워십 앱은 오프라인 우선(Offline-First)으로 작동합니다. 네트워크가 연결되면 작성하신 묵상 일지가 LWW(Last-Write-Wins) 알고리즘으로 안전하게 서버로 백업됩니다.',
              style: TextStyle(fontSize: 13.5, color: Colors.grey, height: 1.5),
            ),
            const SizedBox(height: 16),

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
                        const SnackBar(content: Text('🎉 내 묵상 기록이 서버로 성공적으로 백업 동기화되었습니다!')),
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
                      List<UserNote> restored = await provider.apiService.pullSyncNotes('device_demo_001');
                      for (var note in restored) {
                        await provider.dbHelper.upsertUserNote(note);
                      }
                      await provider.loadDataForDate(provider.selectedDate);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('🎉 서버로부터 ${restored.length}개의 묵상 기록을 성공적으로 복원했습니다!')),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
