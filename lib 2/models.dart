import 'package:flutter/material.dart';
import 'alert_settings.dart';

class SeismicEvent {
  final String zoneName;
  final Color zoneColor;
  final String time;
  final double duration;
  final int shockCount;

  SeismicEvent({
    required this.zoneName,
    required this.zoneColor,
    required this.time,
    required this.duration,
    required this.shockCount,
  });

  // ใช้ค่า threshold จาก Settings
  bool get hasAlert =>
      shockCount >= AlertSettings.warningThreshold;

  bool get isDanger =>
      shockCount >= AlertSettings.dangerThreshold;

  bool get isWarning =>
      shockCount >= AlertSettings.warningThreshold &&
      shockCount < AlertSettings.dangerThreshold;

  factory SeismicEvent.fromFirebase(Map<dynamic, dynamic> json) {
    int shockCount = 0;

    json.forEach((key, value) {
      if (key.toString().startsWith("shock")) {
        final shockValue =
            int.tryParse(value.toString()) ?? 0;

        if (shockValue > 0) {
          shockCount += shockValue;
        }
      }
    });

    String formattedTime = "ไม่ระบุเวลา";

    if (json['timestamp'] != null) {
      try {
        final dateTime =
            DateTime.parse(json['timestamp']);
        formattedTime =
            "${dateTime.day}/${dateTime.month} "
            "${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}";
      } catch (_) {
        formattedTime = json['timestamp'].toString();
      }
    }

    // ใช้ threshold จาก AlertSettings ตัดสินสี
    Color zoneColor;

    if (shockCount >= AlertSettings.dangerThreshold) {
      zoneColor = Colors.red;
    } else if (shockCount >= AlertSettings.warningThreshold) {
      zoneColor = Colors.orange;
    } else {
      zoneColor = Colors.green;
    }

    return SeismicEvent(
      zoneName: "เขตตรวจจับ",
      zoneColor: zoneColor,
      time: formattedTime,
      duration: shockCount.toDouble(),
      shockCount: shockCount,
    );
  }
}