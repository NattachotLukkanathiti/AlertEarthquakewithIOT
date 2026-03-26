import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:audioplayers/audioplayers.dart';

import 'firebase_options.dart';
import 'colors.dart';
import 'home_screen.dart';
import 'history_screen.dart';
import 'alert_screen.dart';
import 'models.dart';
import 'settings_screen.dart';
import 'alert_settings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await AlertSettings.load();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Earthquake Alert',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bgColor,
      ),
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  StreamSubscription<DatabaseEvent>? _dangerSub;
  String? _lastDangerKey;

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isSirenPlaying = false;

  @override
  void initState() {
    super.initState();

    final ref =
        FirebaseDatabase.instance.ref("Earthquake").limitToLast(1);

    _dangerSub = ref.onValue.listen((event) async {
  final data = event.snapshot.value;

  if (data == null || data is! Map) return;

  final rawData = Map<dynamic, dynamic>.from(data);

  if (rawData.isEmpty) return;

  // limitToLast(1) จะเหลือ 1 record เสมอ
  final latestKey = rawData.keys.first;

  if (_lastDangerKey == latestKey) return;

  final latestValue = rawData[latestKey];

  if (latestValue is! Map) return;

  final latestMap = Map<dynamic, dynamic>.from(latestValue);

  final seismic = SeismicEvent.fromFirebase(latestMap);

  if (seismic.isDanger) {
    _lastDangerKey = latestKey;

    if (!_isSirenPlaying) {
      _isSirenPlaying = true;
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(
        AssetSource('sounds/siren.mp3'),
      );
    }

    if (mounted) {
      setState(() {
        _selectedIndex = 2;
      });
    }
  }
});
  }
  void _stopSiren() async {
    if (_isSirenPlaying) {
      await _audioPlayer.stop();
      _isSirenPlaying = false;
    }
  }

  @override
  void dispose() {
    _dangerSub?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const HomeScreen(),
      const HistoryScreen(),
      AlertScreen(
        onAcknowledge: () {
          _stopSiren(); // 🔇 หยุดเสียงเมื่อกดรับทราบ
          setState(() {
            _selectedIndex = 0;
          });
        },
      ),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        backgroundColor: bgColor,
        selectedItemColor: safeColor,
        unselectedItemColor: mutedColor,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'หน้าหลัก',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_rounded),
            label: 'ประวัติ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.warning_amber_rounded),
            label: 'แจ้งเตือน',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_rounded),
            label: 'ตั้งค่า',
          ),
        ],
      ),
    );
  }
}