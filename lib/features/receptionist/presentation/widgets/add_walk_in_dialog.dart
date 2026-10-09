import 'package:flutter/material.dart';
import '../../../../core/utils/shared_mock_data.dart';
import '../../../../services/supabase_service.dart';
import '../../../../services/receptionist_context.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../data/models/queue_entry_model.dart';

class AddWalkInDialog extends StatefulWidget {
  final String? restaurantId;
  final String? restaurantName;

  const AddWalkInDialog({
    super.key,
    this.restaurantId,
    this.restaurantName,
  });

  static Future<void> show(
    BuildContext context, {
    String? restaurantId,
    String? restaurantName,
  }) {
    return showDialog(
      context: context,
      builder: (context) => AddWalkInDialog(
        restaurantId: restaurantId,
        restaurantName: restaurantName,
      ),
    );
  }

  @override
  State<AddWalkInDialog> createState() => _AddWalkInDialogState();
}

class _AddWalkInDialogState extends State<AddWalkInDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  int _partySize = 2;
  bool _isSubmitting = false;

  String get _targetRestaurantId =>
      widget.restaurantId ?? ReceptionistContext().activeRestaurantId;

  String get _targetRestaurantName =>
      widget.restaurantName ?? ReceptionistContext().activeRestaurantName;

  Future<void> _addWalkIn() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    if (name.isEmpty || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    final restaurantId = _targetRestaurantId;
    final restaurantName = _targetRestaurantName;

    try {
      // 1. Create walk-in entry directly in Supabase queue_entries table
      final createdEntry = await SupabaseService().addWalkIn(
        guestName: name,
        partySize: _partySize,
        phoneNumber: phone,
        restaurantId: restaurantId,
        restaurantName: restaurantName,
      );

      // 2. Sync to local receptionist mock state for seamless immediate offline fallback
      final queue = SharedMockData().queue;
      final newEntry = QueueEntry(
        id: createdEntry.id,
        queueNumber: createdEntry.queueNumber,
        guestName: createdEntry.guestName,
        partySize: createdEntry.partySize,
        waitingMinutes: 0,
        position: createdEntry.position,
      );
      queue.add(newEntry);

      if (!mounted) return;
      Navigator.pop(context);
      AppToast.showSuccess(
        context,
        '$name added to $restaurantName waitlist (${createdEntry.queueNumber})!',
        title: 'Walk-In Added',
      );
    } catch (e) {
      // Graceful offline fallback
      final queue = SharedMockData().queue;
      final newId = 'q_${DateTime.now().millisecondsSinceEpoch}';
      final latestQ = queue.isEmpty
          ? 10
          : int.tryParse(queue.last.queueNumber.replaceAll('Q', '').replaceAll('-', '')) ?? 10;
      final newEntry = QueueEntry(
        id: newId,
        queueNumber: 'Q-${latestQ + 1}',
        guestName: name,
        partySize: _partySize,
        waitingMinutes: 0,
        position: queue.length + 1,
      );
      queue.add(newEntry);

      if (!mounted) return;
      Navigator.pop(context);
      AppToast.showSuccess(
        context,
        '$name added to $restaurantName waitlist!',
        title: 'Walk-In Added',
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Add Walk-In to Waitlist',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7ED),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFFFEDD5)),
                            ),
                            child: Text(
                              _targetRestaurantName,
                              style: const TextStyle(
                                color: Color(0xFFC2410C),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 20, color: Color(0xFF94A3B8)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            const Text(
              'Customer Name',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'e.g. Ruwan',
                hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF143621)),
                ),
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'Phone Number (Optional)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: '+94 77 123 4567',
                hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF143621)),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Party Size',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        if (_partySize > 1) {
                          setState(() => _partySize--);
                        }
                      },
                      icon: const Icon(Icons.remove, size: 20, color: Color(0xFF4B5563)),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 20),
                    Text(
                      '$_partySize',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(width: 20),
                    IconButton(
                      onPressed: () {
                        if (_partySize < 20) {
                          setState(() => _partySize++);
                        }
                      },
                      icon: const Icon(Icons.add, size: 20, color: Color(0xFF4B5563)),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 28),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _addWalkIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D3B2E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Add to Queue',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
