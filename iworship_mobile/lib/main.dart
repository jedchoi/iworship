import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'providers/qt_provider.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko_KR', null);
  runApp(const IWorshipApp());
}

class IWorshipApp extends StatelessWidget {
  const IWorshipApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => QtProvider(),
      child: MaterialApp(
        title: '명선아이워십',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF7F5F0),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF7C6893),
            primary: const Color(0xFF7C6893),
            secondary: const Color(0xFFD6A5BC),
            background: const Color(0xFFF7F5F0),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Color(0xFF645179),
            elevation: 0.5,
          ),
          fontFamily: 'Pretendard',
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
