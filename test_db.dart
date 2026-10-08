import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  
  final supabaseUrl = dotenv.env['SUPABASE_URL']!;
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY']!;
  
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  final client = Supabase.instance.client;
  
  try {
    await client.from('reviews').select().limit(1);
    print('SUCCESS: reviews table exists!');
  } catch (e) {
    print('ERROR: $e');
  }
  
  try {
    await client.from('reviews').insert({
      'id': 'test_id',
      'user_id': 'test_user',
      'restaurant_id': 'ocean_bistro',
      'restaurant_name': 'Ocean Bistro',
      'rating': 5.0,
      'comment': 'Test'
    });
    print('SUCCESS: inserted into reviews!');
  } catch (e) {
    print('INSERT ERROR: $e');
  }
}
