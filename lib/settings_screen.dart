import 'package:flutter/material.dart';
import 'alert_settings.dart';
import 'mqtt_service.dart';
import 'threshold_service.dart';

final MqttService mqttService = MqttService(
  clientId: "450b598f-ad94-4eaf-8db8-9437f9c7f93d",
  token: "9pZYy4j5YRHK72ssVtaKUUEgoTNULcsQ",
  secret: "5WL2jCWXPnimmzN2cNqrwttg4S9K6Eew",
);

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

  double dangerValue = AlertSettings.dangerThreshold.toDouble();
  double warningValue = AlertSettings.warningThreshold.toDouble();

  @override
  void initState() {
    super.initState();
    mqttService.connect(); // เชื่อม MQTT
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: const Text("ตั้งค่าการแจ้งเตือน")),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text("ระดับอันตราย (≥ ${dangerValue.round()})"),

            Slider(
              value: dangerValue,
              min: 1,
              max: 10,
              divisions: 9,
              label: dangerValue.round().toString(),
              onChanged: (value) {
                setState(() {
                  dangerValue = value;
                });
              },
            ),

            const SizedBox(height: 20),

            Text("ระดับเฝ้าระวัง (≥ ${warningValue.round()})"),

            Slider(
              value: warningValue,
              min: 1,
              max: 10,
              divisions: 9,
              label: warningValue.round().toString(),
              onChanged: (value) {
                setState(() {
                  warningValue = value;
                });
              },
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,

              child: ElevatedButton(

                onPressed: () async {

                  if (warningValue >= dangerValue) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("ระดับเฝ้าระวังต้องน้อยกว่าระดับอันตราย"),
                      ),
                    );
                    return;
                  }

                  await AlertSettings.save(
                    danger: dangerValue.round(),
                    warning: warningValue.round(),
                  );

                  // 🔹 ส่งผ่าน MQTT
                  mqttService.publishThreshold(
                    dangerValue.round(),
                    warningValue.round(),
                  );

                  // 🔹 ส่งผ่าน HTTP API
                  await ThresholdService.sendThreshold(
                    dangerValue.round(),
                    warningValue.round(),
                  );

                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("บันทึกสำเร็จ")),
                  );
                },

                child: const Text("บันทึก"),
              ),
            ),

          ],
        ),
      ),
    );
  }
}