import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://pwcgtvfzavztnjwphmgj.supabase.co',
    anonKey: 'sb_publishable_rtN4RJiw2EgI9phVpnjPpw_sySbz72x',
  );
  
  final client = Supabase.instance.client;
  try {
    final response = await client.from('restaurants').select().limit(1);
    print('Response: $response');
  } catch (e) {
    print('Error: $e');
  }
}
