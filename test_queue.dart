import 'package:supabase/supabase.dart';

void main() async {
  final client = SupabaseClient(
    'https://pwcgtvfzavztnjwphmgj.supabase.co',
    'sb_publishable_rtN4RJiw2EgI9phVpnjPpw_sySbz72x',
  );

  // Get first waiting queue
  final queues = await client.from('queue_entries').select().eq('status', 'waiting').limit(1);
  print('Queues: $queues');
  
  if (queues.isNotEmpty) {
    final q = queues.first;
    print('Queue ID: ${q['id']}');
    print('User ID: ${q['user_id']}');
    
    // We cannot test update without user auth, but we can see the data types.
    print('ID type: ${q['id'].runtimeType}');
  }
}
