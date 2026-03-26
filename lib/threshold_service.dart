import 'dart:convert';
import 'package:http/http.dart' as http;

class ThresholdService {

  static const String url =
      "https://api.netpie.io/v2/device/message?topic=home/device_control";

  static const String clientId = "450b598f-ad94-4eaf-8db8-9437f9c7f93d";
  static const String token = "9pZYy4j5YRHK72ssVtaKUUEgoTNULcsQ";

  static Future<void> sendThreshold(int danger, int warning) async {

    final payload = jsonEncode({
      "data": {
        "D": danger,
        "W": warning
      }
    });

    final response = await http.put(
      Uri.parse(url),
      headers: {
        "Authorization": "Device $clientId:$token",
        "Content-Type": "application/json",
      },
      body: payload,
    );

    print("Response: ${response.statusCode}");
    print(response.body);
  }
}