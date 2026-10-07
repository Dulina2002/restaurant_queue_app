import 'package:flutter/material.dart';
import '../../../models/queue_entry_model.dart';
import '../../../models/user_profile.dart';
import '../../../services/firestore_service.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/app_toast.dart';

class CustomerQueueView extends StatefulWidget {
  final UserProfile? profile;
  final VoidCallback onBrowseRestaurants;

  const CustomerQueueView({
    super.key,
    this.profile,
    required this.onBrowseRestaurants,
  });

  @override
  State<CustomerQueueView> createState() => _CustomerQueueViewState();
}

class _CustomerQueueViewState extends State<CustomerQueueView> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLeaving = false;

  void _confirmLeaveQueue(QueueEntryModel queue) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Leave Waitlist?',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: Text(
          'Are you sure you want to cancel your position (#${queue.position}) in the waitlist for ${queue.restaurantName}? This action cannot be undone.',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Stay in Queue', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              setState(() => _isLeaving = true);
              try {
                await _firestoreService.leaveQueue(
                  queueId: queue.id,
                  restaurantId: queue.restaurantId,
                );
                if (!mounted) return;
                AppToast.show(
                  context,
                  title: 'Left Waitlist',
                  message: 'Left ${queue.restaurantName} waitlist.',
                  type: ToastType.error,
                );
              } catch (e) {
                if (!mounted) return;
                AppToast.showError(
                  context,
                  'Failed to leave waitlist: $e',
                );
              } finally {
                if (mounted) setState(() => _isLeaving = false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Leave Waitlist'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = widget.profile?.id ?? 'current_customer_id';

    return StreamBuilder<QueueEntryModel?>(
      stream: _firestoreService.streamCustomerActiveQueue(userId),
      builder: (context, snapshot) {
        final activeQueue = snapshot.data;

        if (activeQueue == null) {
          return _buildEmptyQueueState();
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Screen Header
              const Text(
                'Live Waitlist',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Track your real-time virtual queue position',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
              const SizedBox(height: 20),

              // Active Ticket Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF14382A), Color(0xFF0A2218)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0D3B2E).withValues(alpha: 0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Top Row: Restaurant & Live Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activeQueue.restaurantName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Party of ${activeQueue.partySize} guests',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: activeQueue.status == QueueStatus.called
                                ? const Color(0xFF10B981)
                                : const Color(0xFFF59E0B),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                activeQueue.status == QueueStatus.called ? 'TABLE READY!' : 'WAITING',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Big Queue Ticket Number
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.1),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                          width: 2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'TICKET',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            activeQueue.queueNumber,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Position & Est Wait
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildQueueStat(
                          label: 'Position in line',
                          value: '#${activeQueue.position}',
                          icon: Icons.people_alt_rounded,
                        ),
                        Container(height: 36, width: 1, color: Colors.white.withValues(alpha: 0.15)),
                        _buildQueueStat(
                          label: 'Est. Wait Time',
                          value: '${activeQueue.estimatedWaitMinutes} min',
                          icon: Icons.timer_outlined,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Waitlist Progress Stepper
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Queue Status',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 16),
                    _buildProgressStep(
                      step: '1',
                      title: 'Queue Joined',
                      subtitle: 'Your ticket has been registered in the system.',
                      isCompleted: true,
                    ),
                    _buildProgressStep(
                      step: '2',
                      title: 'Host Review & Line Moving',
                      subtitle: activeQueue.position <= 2 ? 'Almost your turn! Please stay near the entrance.' : 'Waiting in line behind ${activeQueue.position - 1} parties.',
                      isCompleted: activeQueue.position <= 2 || activeQueue.status == QueueStatus.called,
                      isCurrent: activeQueue.position > 2 && activeQueue.status != QueueStatus.called,
                    ),
                    _buildProgressStep(
                      step: '3',
                      title: 'Table Ready & Seating',
                      subtitle: 'Head to the reception counter to be seated.',
                      isCompleted: activeQueue.status == QueueStatus.called,
                      isCurrent: activeQueue.status == QueueStatus.called,
                      isLast: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Leave Waitlist Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _isLeaving ? null : () => _confirmLeaveQueue(activeQueue),
                  icon: const Icon(Icons.exit_to_app_rounded, color: Color(0xFFEF4444), size: 18),
                  label: _isLeaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Color(0xFFEF4444), strokeWidth: 2),
                        )
                      : const Text(
                          'Leave Waitlist',
                          style: TextStyle(
                            color: Color(0xFFEF4444),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFFCA5A5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQueueStat({required String label, required String value, required IconData icon}) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.white70),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressStep({
    required String step,
    required String title,
    required String subtitle,
    bool isCompleted = false,
    bool isCurrent = false,
    bool isLast = false,
  }) {
    final Color stepColor = isCompleted
        ? const Color(0xFF10B981)
        : isCurrent
            ? const Color(0xFFF59E0B)
            : AppColors.border;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isCompleted ? const Color(0xFF10B981) : (isCurrent ? const Color(0xFFFFFBEB) : AppColors.surface),
                shape: BoxShape.circle,
                border: Border.all(color: stepColor, width: 2),
              ),
              alignment: Alignment.center,
              child: isCompleted
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : Text(
                      step,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isCurrent ? const Color(0xFFF59E0B) : AppColors.textMuted,
                      ),
                    ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 36,
                color: isCompleted ? const Color(0xFF10B981) : AppColors.border,
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isCurrent || isCompleted ? FontWeight.bold : FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.3),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyQueueState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.people_alt_outlined,
                size: 44,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Active Queue',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'You are not currently waiting in any restaurant waitlist. Join a queue nearby to get real-time seating updates.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.4),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: widget.onBrowseRestaurants,
              icon: const Icon(Icons.restaurant_menu_rounded, size: 18),
              label: const Text('Browse Restaurants'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D3B2E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
