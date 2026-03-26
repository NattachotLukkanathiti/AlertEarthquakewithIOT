import 'package:flutter/material.dart';
import 'alert_settings.dart';
import 'package:intl/intl.dart';

class SeismicEvent {
  final String zoneName;
  final Color zoneColor;
  final String time;
  final DateTime dateTime;
  final double duration;
  final int shockCount;

  SeismicEvent({
    required this.zoneName,
    required this.zoneColor,
    required this.time,
    required this.dateTime,
    required this.duration,
    required this.shockCount,
  });

  // ใช้ค่า threshold จาก Settings
  bool get hasAlert => shockCount >= AlertSettings.warningThreshold;

  bool get isDanger => shockCount >= AlertSettings.dangerThreshold;

  bool get isWarning =>
      shockCount >= AlertSettings.warningThreshold &&
      shockCount < AlertSettings.dangerThreshold;

  factory SeismicEvent.fromFirebase(Map<dynamic, dynamic> json) {
    int shockCount = 0;

    int shock1 = int.tryParse(json['shock1']?.toString() ?? "0") ?? 0;
    int shock2 = int.tryParse(json['shock2']?.toString() ?? "0") ?? 0;

    shockCount = shock1 >= shock2 ? shock1 : shock2;

    String zoneName;
    Color zoneColor;

    if (shock1 >= shock2) {
      zoneName = "Zone 1";
    } else {
      zoneName = "Zone 2";
    }

    DateTime dateTime = DateTime.now();
    String formattedTime = "ไม่ระบุเวลา";

    if (json['timestamp'] != null) {
      try {
        dateTime = DateTime.parse(json['timestamp']);

        formattedTime = DateFormat("d MMM yyyy  HH:mm", "th").format(dateTime);
      } catch (_) {
        formattedTime = json['timestamp'].toString();
      }
    }

    if (shockCount >= AlertSettings.dangerThreshold) {
      zoneColor = Colors.red;
    } else if (shockCount >= AlertSettings.warningThreshold) {
      zoneColor = Colors.orange;
    } else {
      zoneColor = Colors.green;
    }

    return SeismicEvent(
      zoneName: zoneName,
      zoneColor: zoneColor,
      time: formattedTime,
      dateTime: dateTime,
      duration: shockCount.toDouble(),
      shockCount: shockCount,
    );
  }
}

