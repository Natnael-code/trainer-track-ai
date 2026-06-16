import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/client_provider.dart';

void main() {
  runApp(
    // Wrapping the entire app in our state management engine
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => ClientProvider())],
      child: const TrainerTrackApp(),
    ),
  );
}

class TrainerTrackApp extends StatelessWidget {
  const TrainerTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TrainerTrack AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(
            0xFF1E293B,
          ), // Professional deep slate blue gray
          brightness: Brightness.dark, // Modern dark theme for gym trainers
        ),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Text(
            'TrainerTrack AI Engine Active 🏋️‍♂️',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
