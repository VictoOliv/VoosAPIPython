import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'pages/home_page.dart';
import 'providers/flight_provider.dart';

void main() {
  DevicePreview.enable(enabled: const bool.fromEnvironment('DEVICE_PREVIEW'));
  runApp(
    ChangeNotifierProvider(
      create: (_) => FlightProvider()..search(),
      child: const FlightsApp(),
    ),
  );
}

class FlightsApp extends StatelessWidget {
  const FlightsApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Consulta de Voos',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF006A8E)),
      scaffoldBackgroundColor: const Color(0xFFF4F8FB),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
    ),
    home: const HomePage(),
  );
}
