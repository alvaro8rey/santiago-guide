import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://paxjnpdzcfnampnvefjy.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBheGpucGR6Y2ZuYW1wbnZlZmp5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkzNzQwNzYsImV4cCI6MjA5NDk1MDA3Nn0.bJ2jHxMlwyeFvqaUoKHI3MVW3tR7ObVKpEKGR0nqtsg',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Santiago Guide',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Text('Santiago Guide'),
        ),
      ),
    );
  }
}