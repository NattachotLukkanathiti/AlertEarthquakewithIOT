import 'package:flutter/material.dart';
import 'colors.dart';
import 'models.dart';
import 'package:firebase_database/firebase_database.dart';

List<SeismicEvent> groupEventsByMinute(List<SeismicEvent> events) {
  Map<String, SeismicEvent> grouped = {};

  for (var event in events) {
    final key =
        "${event.dateTime.year}-${event.dateTime.month}-${event.dateTime.day}-${event.dateTime.hour}-${event.dateTime.minute}";

    if (!grouped.containsKey(key)) {
      grouped[key] = event;
    } else {
      final existing = grouped[key]!;

      // เลือกค่าที่มากที่สุดของ shock
      int maxShock = existing.shockCount > event.shockCount
          ? existing.shockCount
          : event.shockCount;

      grouped[key] = SeismicEvent(
        zoneName: existing.zoneName,
        zoneColor: existing.zoneColor,
        time: existing.time,
        dateTime: existing.dateTime,
        duration: maxShock.toDouble(),
        shockCount: maxShock,
      );
    }
  }

  return grouped.values.toList();
}

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final DatabaseReference ref = FirebaseDatabase.instance.ref("Earthquake");

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

                final rawData = Map<dynamic, dynamic>.from(
                  snapshot.data!.snapshot.value as Map,
                );

                List<SeismicEvent> events = [];

                rawData.forEach((key, value) {
                  final eventMap = Map<dynamic, dynamic>.from(value);
                  events.add(SeismicEvent.fromFirebase(eventMap));
                });
                events = groupEventsByMinute(events);
                events.sort((a, b) => b.dateTime.compareTo(a.dateTime));
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: events.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _EventCard(event: events[i]),
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
    final badgeLabel = event.isDanger ? 'อันตราย' : 'เฝ้าระวัง';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          // จุดสถานะใหญ่ขึ้น
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: badgeColor,
              shape: BoxShape.circle,
            ),
          ),

          const SizedBox(width: 16),

          // ข้อมูลเหตุการณ์
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // โซน
                Text(
                  event.zoneName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: event.zoneColor,
                    letterSpacing: 0.5,
                  ),
                ),

                const SizedBox(height: 4),

                // เวลา
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: mutedColor),
                    const SizedBox(width: 4),
                    Text(
                      event.time,
                      style: const TextStyle(fontSize: 12, color: textColor),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                // จำนวนครั้งสั่น (เด่นขึ้น)
                Row(
                  children: [
                    const Icon(Icons.vibration, size: 14, color: mutedColor),
                    const SizedBox(width: 4),
                    Text(
                      '${event.duration.toInt()} ครั้ง',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: badgeColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: badgeColor.withOpacity(0.35)),
            ),
            child: Text(
              badgeLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: badgeColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
