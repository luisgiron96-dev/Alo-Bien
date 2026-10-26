import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const url = 'https://pwgeflsdgodnpzwqsktb.supabase.co';
  static const anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB3Z2VmbHNkZ29kbnB6d3Fza3RiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTMwNDU2NzIsImV4cCI6MjEwODYyMTY3Mn0.pQQYjUrZn2JMJ-pIbluzobCNZHcUhPv8sN0wXD5dE8k';
}

SupabaseClient get db => Supabase.instance.client;