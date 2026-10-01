import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://pwcgtvfzavztnjwphmgj.supabase.co',
    anonKey: 'sb_publishable_rtN4RJiw2EgI9phVpnjPpw_sySbz72x',
  );
  final client = Supabase.instance.client;

  // Let's first query any waiting queue entry
  final queues = await client.from('queue_entries').select().eq('status', 'waiting');
  print('Found ${queues.length} waiting queues');
  
  if (queues.isNotEmpty) {
    for (var q in queues) {
      print('Queue entry: $q');
    }
  }
}
