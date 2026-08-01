import 'package:flutter/material.dart';
import 'qt_view_screen.dart';
import 'journey_screen.dart';
import 'bulletin_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    QtViewScreen(),
    JourneyScreen(),
    BulletinScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF645179),
          unselectedItemColor: Colors.grey,
          backgroundColor: Colors.white,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.auto_stories),
              label: '묵상',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.explore),
              label: '여정',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.newspaper),
              label: '주보',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: '설정',
            ),
          ],
        ),
      ),
    );
  }
}
