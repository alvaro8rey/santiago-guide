import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String url = 'https://paxjnpdzcfnampnvefjy.supabase.co';
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBheGpucGR6Y2ZuYW1wbnZlZmp5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkzNzQwNzYsImV4cCI6MjA5NDk1MDA3Nn0.bJ2jHxMlwyeFvqaUoKHI3MVW3tR7ObVKpEKGR0nqtsg';

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
  }
}
