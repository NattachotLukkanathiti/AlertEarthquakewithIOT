import 'package:flutter/material.dart';
import 'colors.dart';
import 'models.dart';
import 'package:firebase_database/firebase_database.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final DatabaseReference ref =
        FirebaseDatabase.instance.ref("Earthquake");

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 16, 24, 16),
            child: Text(
              'ประวัติการสั่นไหว',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ),

          Expanded(
            child: StreamBuilder<DatabaseEvent>(
              stream: ref.onValue,
              builder: (context, snapshot) {

                // ไม่มีข้อมูล
                if (!snapshot.hasData ||
                    snapshot.data!.snapshot.value == null) {
                  return const Center(
                    child: Text(
                      "ไม่มีข้อมูล",
                      style: TextStyle(color: textColor),
                    ),
                  );
                }

                final rawData =
                    Map<dynamic, dynamic>.from(
                        snapshot.data!.snapshot.value as Map);

                List<SeismicEvent> events = [];

                rawData.forEach((key, value) {
                  final eventMap =
                      Map<dynamic, dynamic>.from(value);
                  events.add(
                    SeismicEvent.fromFirebase(eventMap),
                  );
                });

                return ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: events.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 10),
                  itemBuilder: (_, i) =>
                      _EventCard(event: events[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── การ์ดแสดงเหตุการณ์ ─────────────────────────────
class _EventCard extends StatelessWidget {
  final SeismicEvent event;
  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final badgeColor = event.isDanger ? dangerColor : warnColor;
    final badgeLabel =
        event.isDanger ? 'อันตราย' : 'เฝ้าระวัง';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [

          // จุดสถานะ
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: badgeColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 14),

          // ข้อมูล
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  event.zoneName,
                  style: TextStyle(
                    fontSize: 11,
                    color: event.zoneColor,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  event.time,
                  style: const TextStyle(
                      fontSize: 13, color: textColor),
                ),
                const SizedBox(height: 2),

                // แก้ให้เป็นจำนวนครั้ง
                Text(
                  'สั่น ${event.duration.toInt()} ครั้ง',
                  style: const TextStyle(
                      fontSize: 11, color: mutedColor),
                ),
              ],
            ),
          ),

          // badge
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: badgeColor.withOpacity(0.3)),
            ),
            child: Text(
              badgeLabel,
              style: TextStyle(
                  fontSize: 10, color: badgeColor),
            ),
          ),
        ],
      ),
    );
  }
}