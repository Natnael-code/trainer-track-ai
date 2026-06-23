import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/client_provider.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final clientProvider = ClientProvider();
  // Safe initial database background payload loading before bootstrapping application paint layout cycles
  await clientProvider.loadClientsFromDatabase();

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider.value(value: clientProvider)],
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
          seedColor: const Color(0xFF1E293B),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
      ),
      home: const DashboardScreen(),
    );
  }
}
