import 'dart:io';

void main() {
  final file = File('lib/screens/receptionist/receptionist_dashboard_screen.dart');
  var content = file.readAsStringSync();
  
  content = content.replaceFirst('        body: SingleChildScrollView(', '''        body: _restaurant == null
            ? const Center(child: CircularProgressIndicator())
            : StreamBuilder<List<Map<String, dynamic>>>(
                stream: SupabaseService().listenToRestaurantBookings(_restaurant!['id']),
                builder: (context, bookingsSnapshot) {
                  return StreamBuilder<List<Map<String, dynamic>>>(
                    stream: SupabaseService().listenToQueue(_restaurant!['id']),
                    builder: (context, queueSnapshot) {
                      final bookings = bookingsSnapshot.data ?? [];
                      final queues = (queueSnapshot.data ?? []).where((q) => q['status'] == 'waiting').toList();
                      
                      final todaysBookings = bookings.length;
                      final waitingQueue = queues.length;
                      
                      return SingleChildScrollView(''');
                      
  content = content.replaceFirst('          child: Column(', '''          child: Column(''');

  // Replace hardcoded values in stats
  content = content.replaceFirst("'Today\\'s RSV',\\n                    '2'", "'Today\\'s RSV',\\n                    '\$todaysBookings'");
  content = content.replaceFirst("'Waiting Queue',\\n                    '4'", "'Waiting Queue',\\n                    '\$waitingQueue'");
  
  // Replace the reservation list with dynamic building
  final rListStart = content.indexOf('              // Reservation List');
  final rListEnd = content.indexOf('            ],\\n          ),\\n        ),\\n        bottomNavigationBar: BottomNavigationBar(');
  
  final replacement = '''              // Reservation List
              if (bookings.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: Center(
                    child: Text('No upcoming reservations for today.', style: TextStyle(color: Colors.grey)),
                  ),
                )
              else
                ...bookings.map((booking) {
                  // Waitlist/Booking date logic
                  final dateStr = booking['booking_date'] as String?;
                  final timeStr = dateStr != null ? dateStr.substring(11, 16) : 'N/A';
                  final partySize = booking['party_size'];
                  final status = booking['status'] as String? ?? 'Confirmed';
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildReservationCard(
                      name: 'Guest (User ID: \${booking['user_id'].toString().substring(0,4)})',
                      time: timeStr,
                      guests: '\$partySize Guests',
                      table: 'Unassigned',
                      requirement: 'No special requirements.',
                      status: status == 'confirmed' ? 'Confirmed' : 'Completed',
                      isConfirmed: status == 'confirmed',
                      showActions: status == 'confirmed',
                    ),
                  );
                }),''';

  content = content.replaceRange(rListStart, rListEnd, replacement);
  
  // Close StreamBuilders
  content = content.replaceFirst('        bottomNavigationBar: BottomNavigationBar(', '''            );
                  },
                );
              },
            ),
        bottomNavigationBar: BottomNavigationBar(''');

  file.writeAsStringSync(content);
}
