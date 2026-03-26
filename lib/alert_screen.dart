import 'package:flutter/material.dart';
import 'colors.dart';
import 'models.dart';
import 'package:firebase_database/firebase_database.dart';

class AlertScreen extends StatefulWidget {
  final VoidCallback onAcknowledge;

  const AlertScreen({super.key, required this.onAcknowledge});

  @override
  State<AlertScreen> createState() => _AlertScreenState();
}

class _AlertScreenState extends State<AlertScreen> {
  String? acknowledgedKey;

  @override
  Widget build(BuildContext context) {
    final DatabaseReference ref = FirebaseDatabase.instance.ref("Earthquake");

    return SafeArea(
      child: StreamBuilder<DatabaseEvent>(
        stream: ref.onValue,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(
              child: Text(
                "ไม่มีข้อมูลแจ้งเตือน",
                style: TextStyle(color: textColor),
              ),
            );
          }

          final rawData = Map<dynamic, dynamic>.from(
            snapshot.data!.snapshot.value as Map,
          );

          if (rawData.isEmpty) {
            return const Center(
              child: Text(
                "ไม่มีข้อมูลแจ้งเตือน",
                style: TextStyle(color: textColor),
              ),
            );
          }

          final keys = rawData.keys.toList()..sort();
          final latestKey = keys.last;

          final latestMap = Map<dynamic, dynamic>.from(rawData[latestKey]);

          final event = SeismicEvent.fromFirebase(latestMap);

          final hasAlert = event.hasAlert;
          final isDanger = event.isDanger;

          if (!hasAlert || acknowledgedKey == latestKey)
            return const Center(
              child: Text(
                "ไม่มีข้อมูลแจ้งเตือน",
                style: TextStyle(color: textColor),
              ),
            );

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Row(
                  children: [
                    const Text(
                      'การแจ้งเตือน',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 2,
                        color: mutedColor,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      event.time,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDanger ? dangerColor : warnColor,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: surfaceColor,
                  border: Border.all(
                    color: isDanger
                        ? dangerColor.withOpacity(0.5)
                        : warnColor.withOpacity(0.5),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isDanger ? dangerColor : warnColor).withOpacity(
                        0.15,
                      ),
                      blurRadius: 50,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('⚠️', style: TextStyle(fontSize: 32)),
                    const SizedBox(height: 8),
                    Text(
                      isDanger ? 'อันตราย!' : 'เฝ้าระวัง',
                      style: TextStyle(
                        fontSize: 22,
                        color: isDanger ? dangerColor : warnColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'ตรวจพบการสั่นไหว',
                      style: TextStyle(
                        fontSize: 10,
                        color: mutedColor,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              Text(
                '📍 ${event.zoneName} กำลังสั่นไหว',
                style: const TextStyle(fontSize: 14, color: textColor),
              ),
              const SizedBox(height: 6),
              Text(
                'เกิดเมื่อ: ${event.time}  ·  สั่น ${event.duration.toInt()} ครั้ง',
                style: const TextStyle(fontSize: 11, color: mutedColor),
              ),

              const Spacer(),

              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        acknowledgedKey = latestKey;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'รับทราบ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
