import 'dart:convert';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttService {

  final String clientId;
  final String token;
  final String secret;

  MqttServerClient? client;

  MqttService({
    required this.clientId,
    required this.token,
    required this.secret,
  });

  Future<void> connect() async {

    client = MqttServerClient('mqtt.netpie.io', clientId);

    client!.port = 1883;
    client!.logging(on: true);
    client!.keepAlivePeriod = 30;
    client!.setProtocolV311();

    client!.onConnected = () {
      print("MQTT Connected");
    };

    client!.onDisconnected = () {
      print("MQTT Disconnected");
    };

    client!.connectionMessage = MqttConnectMessage()
        .authenticateAs(token, secret)
        .withClientIdentifier(clientId)
        .startClean();

    try {
      await client!.connect();
    } catch (e) {
      print("MQTT connect error: $e");
      client!.disconnect();
    }

    if (client!.connectionStatus!.state == MqttConnectionState.connected) {
      print("Connected to NETPIE");
    } else {
      print("Connection failed");
      client!.disconnect();
    }
  }

  void publishThreshold(int danger, int warning) {

    if (client == null ||
        client!.connectionStatus!.state != MqttConnectionState.connected) {
      print("MQTT ยังไม่เชื่อมต่อ");
      return;
    }

    final payloadBuilder = MqttClientPayloadBuilder();

    final message = jsonEncode({
      "data": {
        "D": danger,
        "W": warning
      }
    });

    payloadBuilder.addString(message);

    // 🔹 ส่งไป ESP32
    client!.publishMessage(
      "@msg/home/device_control",
      MqttQos.atLeastOnce,
      payloadBuilder.payload!,
    );

    // 🔹 ส่งไป NETPIE Shadow (เหมือนเดิม)
    client!.publishMessage(
      "@shadow/data/update",
      MqttQos.atLeastOnce,
      payloadBuilder.payload!,
    );

    print("ส่งค่าไป ESP32 + NETPIE: $message");
  }
}