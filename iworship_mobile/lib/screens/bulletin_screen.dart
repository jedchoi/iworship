import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/qt_provider.dart';
import '../services/bulletin_cache_service.dart';

class BulletinScreen extends StatefulWidget {
  const BulletinScreen({Key? key}) : super(key: key);

  @override
  State<BulletinScreen> createState() => _BulletinScreenState();
}

class _BulletinScreenState extends State<BulletinScreen> {
  List<Map<String, dynamic>> _bulletins = [];
  bool _loading = false;
  int _selectedIndex = 0;
  int _currentPage = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _initAndSyncBulletins();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// 1) 로컬 데이터 0.01초 즉시 렌더링 + 2) 백그라운드 서버 최신화 체계
  Future<void> _initAndSyncBulletins() async {
    // 1단계: 로컬 저장소 캐시 0.01초 즉시 가져오기
    List<Map<String, dynamic>> localList = await BulletinCacheService.getLocalBulletinList();
    if (localList.isNotEmpty && mounted) {
      setState(() {
        _bulletins = localList;
        _loading = false;
      });
    } else if (mounted) {
      setState(() => _loading = true);
    }

    // 2단계: 백그라운드에서 서버 최신 업데이트 확인 및 이미지 다운로드 캐싱
    _fetchAndSyncServerBulletins();
  }

  Future<void> _fetchAndSyncServerBulletins() async {
    try {
      final provider = Provider.of<QtProvider>(context, listen: false);
      var serverList = await provider.apiService.fetchBulletins();

      if (serverList.isNotEmpty) {
        await BulletinCacheService.saveLocalBulletinList(serverList);

        if (mounted) {
          setState(() {
            _bulletins = serverList;
            _loading = false;
          });
        }

        // 모든 주보 이미지 백그라운드 로컬 캐싱 수행
        String baseUrl = provider.apiService.baseUrl;
        for (var b in serverList) {
          List<dynamic> pages = b['pages'] ?? [];
          for (var p in pages) {
            String imgPath = p.toString();
            String fullImgUrl = imgPath.startsWith('http') ? imgPath : '$baseUrl$imgPath';

            Uint8List? cachedBytes = await BulletinCacheService.getCachedImageBytes(imgPath);
            if (cachedBytes == null) {
              await BulletinCacheService.downloadAndCacheImage(fullImgUrl, imgPath);
              if (mounted) setState(() {});
            }
          }
        }
      }
    } catch (e) {
      print('서버 주보 백그라운드 동기화 실패 (오프라인 모드 유지): $e');
      if (mounted && _bulletins.isEmpty) {
        setState(() => _loading = false);
      }
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  void _goToPage(int page) {
    if (page >= 0 && page < (_bulletins[_selectedIndex]['pages'] as List).length) {
      _pageController.animateToPage(
        page,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _forceRefreshBulletins() async {
    if (mounted) setState(() => _loading = true);
    await BulletinCacheService.clearCache();
    await _fetchAndSyncServerBulletins();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📰 주보 보기', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _forceRefreshBulletins,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _bulletins.isEmpty
              ? const Center(
                  child: Text(
                    '등록된 주보가 없습니다.\n관리자 콘솔(/admin)에서 주보 사진을 업로드해 보세요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : Column(
                  children: [
                    // Bulletin Selector Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      color: const Color(0xFFF7F5F0),
                      child: Row(
                        children: [
                          const Text('주보 선택: ', style: TextStyle(fontWeight: FontWeight.bold)),
                          Expanded(
                            child: DropdownButton<int>(
                              value: _selectedIndex < _bulletins.length ? _selectedIndex : 0,
                              isExpanded: true,
                              items: List.generate(_bulletins.length, (idx) {
                                var b = _bulletins[idx];
                                return DropdownMenuItem<int>(
                                  value: idx,
                                  child: Text('${b['label']}'),
                                );
                              }),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedIndex = val;
                                    _currentPage = 0;
                                  });
                                  if (_pageController.hasClients) {
                                    _pageController.jumpToPage(0);
                                  }
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Bulletin 4-Page Swipe Slider & Zoomable Display with Local Cache
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          var currentBulletin = _bulletins[_selectedIndex];
                          List<dynamic> pages = currentBulletin['pages'] ?? [];
                          if (pages.isEmpty) {
                            return const Center(child: Text('주보 이미지 페이지가 없습니다.'));
                          }

                          String baseUrl = Provider.of<QtProvider>(context).apiService.baseUrl;

                          return Column(
                            children: [
                              // 1. Horizontal PageView Slider for Smooth Swiping
                              Expanded(
                                child: PageView.builder(
                                  controller: _pageController,
                                  itemCount: pages.length,
                                  onPageChanged: _onPageChanged,
                                  itemBuilder: (context, index) {
                                    String imgPath = pages[index].toString();
                                    String fullImgUrl = imgPath.startsWith('http') ? imgPath : '$baseUrl$imgPath';

                                    return Container(
                                      padding: const EdgeInsets.all(8),
                                      child: InteractiveViewer(
                                        minScale: 1.0,
                                        maxScale: 4.5,
                                        child: FutureBuilder<Uint8List?>(
                                          future: BulletinCacheService.getCachedImageBytes(imgPath),
                                          builder: (context, snapshot) {
                                            if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
                                              // 0.01초 로컬 이미지 바이트 렌더링
                                              return Image.memory(
                                                snapshot.data!,
                                                fit: BoxFit.contain,
                                              );
                                            }
                                            // 로컬에 없을 경우 네트워크 이미지 로딩 및 백그라운드 다운로드
                                            return Image.network(
                                              fullImgUrl,
                                              fit: BoxFit.contain,
                                              errorBuilder: (_, __, ___) => const Center(
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(Icons.broken_image, size: 64, color: Colors.grey),
                                                    SizedBox(height: 8),
                                                    Text('오프라인 상태입니다.', style: TextStyle(color: Colors.grey)),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),

                              // 2. Bottom Navigation Controls (Arrows & Page Counter)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 4,
                                      offset: Offset(0, -1),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.arrow_back_ios, size: 20),
                                      onPressed: _currentPage > 0 ? () => _goToPage(_currentPage - 1) : null,
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF645179),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        '${_currentPage + 1} / ${pages.length} 페이지',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.arrow_forward_ios, size: 20),
                                      onPressed: _currentPage < pages.length - 1 ? () => _goToPage(_currentPage + 1) : null,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
