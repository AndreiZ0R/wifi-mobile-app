import 'package:flutter/material.dart';
import 'package:mobile/config/config_loader.dart';
import 'package:mobile/screens/wifi_scan_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ConfigLoader.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WhyFi',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepOrange,
          brightness: Brightness.dark,
          error: Colors.redAccent,
          secondary: Colors.deepPurple,
          primary: Colors.deepOrange,
          onPrimary: Colors.white,
        ),
        useMaterial3: true,
      ),
      home: const WiFiScannerScreen(),
    );
  }
}
