import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/client_provider.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  // Ensures Flutter environment dependencies are locked before database spin up
  WidgetsFlutterBinding.ensureInitialized();

  final clientProvider = ClientProvider();
  await clientProvider
      .loadClientsFromDatabase(); // Boot loading local data engine

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider.value(value: clientProvider)],
      child: const TrainerTrackApp(),
    ),
  );
}
// Keep rest of TrainerTrackApp structure identical...

class TrainerTrackApp extends StatelessWidget {
  const TrainerTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TrainerTrack AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E293B),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(
          0xFF0F172A,
        ), // Premium rich midnight slate base black
      ),
      home:
          const DashboardScreen(), // Sets the dashboard screen as the entry layout
    );
  }
}
