import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://zneqvgpxiprpumfvslqf.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpuZXF2Z3B4aXBycHVtZnZzbHFmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI3OTkzMTgsImV4cCI6MjA4ODM3NTMxOH0.UbLmYxDLc13xx6eUfHkGwI7bngwqlX4gS1a8AiU4FZ8',
  );

  runApp(const VetClinicApp());
}

class VetClinicApp extends StatelessWidget {
  const VetClinicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vet Clinic System',
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}