import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'alert_settings.dart';
import 'colors.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _time = '';
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      _time =
          '${now.hour.toString().padLeft(2, '0')}:'
          '${now.minute.toString().padLeft(2, '0')}:'
          '${now.second.toString().padLeft(2, '0')}';
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Color getColor(int value) {
    if (value >= AlertSettings.dangerThreshold) {
      return dangerColor;
    }
    if (value >= AlertSettings.warningThreshold) {
      return Colors.orange;
    }
    return safeColor;
  }

  String getStatus(int value) {
    if (value >= AlertSettings.dangerThreshold) {
      return "อันตราย";
    }
    if (value >= AlertSettings.warningThreshold) {
      return "เฝ้าระวัง";
    }
    return "ปลอดภัย";
  }

  @override
  Widget build(BuildContext context) {
    final ref = FirebaseDatabase.instance.ref("Earthquake").limitToLast(1);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Earthquake Alert"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );

              if (result == true) {
                setState(() {}); // รีเฟรชหน้าหลังบันทึก
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<DatabaseEvent>(
          stream: ref.onValue,
          builder: (context, snapshot) {
            Map<String, int> zoneData = {"Zone 1": 0, "Zone 2": 0};

            if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
              final data = snapshot.data!.snapshot.value;

              if (data is Map) {
                final lastEntry = data.values.last;

                if (lastEntry is Map) {
                  zoneData["Zone 1"] =
                      int.tryParse(lastEntry["shock1"]?.toString() ?? "0") ?? 0;

                  zoneData["Zone 2"] =
                      int.tryParse(lastEntry["shock2"]?.toString() ?? "0") ?? 0;
                }
              }
            }

            return Column(
              children: [
                const SizedBox(height: 30),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    padding: const EdgeInsets.all(20),
                    children: zoneData.entries.map((entry) {
                      final value = entry.value;
                      final color = getColor(value);
                      final status = getStatus(value);

                      return Container(
                        margin: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: color, width: 2),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(entry.key),
                            const SizedBox(height: 10),
                            Text(
                              status,
                              style: TextStyle(
                                fontSize: 18,
                                color: color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                Text("ตรวจสอบล่าสุด: $_time"),
                const SizedBox(height: 20),
              ],
            );
          },
        ),
      ),
    );
  }
}
