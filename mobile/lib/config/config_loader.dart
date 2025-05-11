import 'package:flutter_dotenv/flutter_dotenv.dart';

class ConfigLoader {
  static Future<void> load() async {
    await dotenv.load(fileName: "local.env");
  }

  static String get serverIp => dotenv.env["SERVER_HOST"] ?? '10.0.2.2';

  static String get serverPort => dotenv.env["SERVER_PORT"] ?? '8080';

  static String get serverUri => "http://$serverIp:$serverPort";
}
