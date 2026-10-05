import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../models/restaurant_model.dart';
import '../../models/queue_entry_model.dart';
import '../../models/reservation_model.dart';
import '../../models/customer_notification_model.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/widgets/user_avatar.dart';
import '../../services/firestore_service.dart';
import '../../services/customer_notification_center.dart';
import '../home_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import 'widgets/filter_restaurants_sheet.dart';
import 'widgets/customer_notifications_sheet.dart';
import 'widgets/create_booking_modal.dart';
import 'widgets/customer_queue_view.dart';
import 'widgets/customer_bookings_view.dart';
import 'widgets/customer_profile_view.dart';
import 'widgets/top_notification_banner.dart';
import 'booking/restaurant_details_screen.dart';
import 'booking/reservation_details_screen.dart';

class CustomerDashboardScreen extends StatefulWidget {
  final UserProfile? profile;
  final int initialTabIndex;

  const CustomerDashboardScreen({
    super.key,
    this.profile,
    this.initialTabIndex = 0,
  });

  @override
  State<CustomerDashboardScreen> createState() => _CustomerDashboardScreenState();
}

class _CustomerDashboardScreenState extends State<CustomerDashboardScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  int _selectedCategoryIndex = 0;
  int _selectedExploreCuisineIndex = 0;
  late int _bottomNavIndex;

  final TextEditingController _homeSearchController = TextEditingController();
  final TextEditingController _exploreSearchController = TextEditingController();

  final List<String> _homeCategories = [
    'Nearby',
    'Available Now',
    'Top Rated',
    'Popular',
  ];

  final List<String> _exploreCuisines = [
    'All',
    'Italian',
    'Indian',
    'Japanese',
    'Café',
  ];

  // Saved Filters
  Set<String> _selectedFilterCuisines = {'Italian'};
  double _maxDistance = 10.0;
  String _selectedRating = '4.5+ ★';
  String _selectedAvailability = 'Available Today';
  int _partySize = 2;

  StreamSubscription<CustomerNotificationItem>? _notificationSub;
  UserProfile? _currentProfile;

  @override
  void initState() {
    super.initState();
    _currentProfile = widget.profile;
    _bottomNavIndex = widget.initialTabIndex;
    _homeSearchController.addListener(() => setState(() {}));
    _exploreSearchController.addListener(() => setState(() {}));

    // Real-time notifications for the bell icon and top dropdown banner
    CustomerNotificationCenter.instance.start(widget.profile?.id ?? 'guest_id');
    _notificationSub = CustomerNotificationCenter.instance.onNew.listen((item) {
      if (!mounted) return;
      TopNotificationBanner.show(
        context,
        item: item,
        onTapView: _showNotificationsBottomSheet,
      );
    });
  }

  @override
  void didUpdateWidget(covariant CustomerDashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.profile != oldWidget.profile) {
      _currentProfile = widget.profile;
    }
  }

  @override
  void dispose() {
    _notificationSub?.cancel();
    TopNotificationBanner.dismiss();
    _homeSearchController.dispose();
    _exploreSearchController.dispose();
    super.dispose();
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return FilterRestaurantsBottomSheet(
          initialCuisines: _selectedFilterCuisines,
          initialMaxDistance: _maxDistance,
          initialRating: _selectedRating,
          initialAvailability: _selectedAvailability,
          initialPartySize: _partySize,
          onApply: (filters) {
            setState(() {
              _selectedFilterCuisines = filters['cuisines'] as Set<String>;
              _maxDistance = filters['maxDistance'] as double;
              _selectedRating = filters['rating'] as String;
              _selectedAvailability = filters['availability'] as String;
              _partySize = filters['partySize'] as int;
            });
          },
        );
      },
    );
  }

  void _showNotificationsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CustomerNotificationsSheet(),
    );
  }

  void _handleJoinQueue(RestaurantModel restaurant) async {
    final partySizeController = TextEditingController(text: '2');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF162C1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Join Queue: ${restaurant.name}',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter your party size to join the live virtual queue.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: partySizeController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Party Size (Guests)',
                labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFFF27B50)),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              final size = int.tryParse(partySizeController.text) ?? 2;
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);

              try {
                final entry = await _firestoreService.joinQueue(
                  restaurantId: restaurant.id,
                  restaurantName: restaurant.name,
                  userId: widget.profile?.id ?? 'current_customer_id',
                  guestName: (widget.profile?.fullName.isNotEmpty == true) ? widget.profile!.fullName : 'Ayesha Perera',
                  partySize: size,
                  phoneNumber: widget.profile?.phoneNumber ?? '+94 77 123 4567',
                );

                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Joined ${restaurant.name} Queue! Ticket ${entry.queueNumber} (#${entry.position} in line)'),
                    backgroundColor: const Color(0xFF00E676),
                  ),
                );

                // Switch to live queue tab
                setState(() => _bottomNavIndex = 3);
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Failed to join queue: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF27B50),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Confirm & Join'),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'AP';
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length.clamp(1, 2)).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final activeProfile = _currentProfile ?? widget.profile;
    final userName = (activeProfile?.fullName.isNotEmpty == true)
        ? activeProfile!.fullName
        : 'Dulina';
    final initials = _getInitials(userName);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _buildCurrentTab(activeProfile, userName, initials),
            ),

            // --- Bottom Navigation Bar ---
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: const Border(
                  top: BorderSide(color: AppColors.border, width: 1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(icon: Icons.home_filled, label: 'Home', index: 0),
                  _buildNavItem(icon: Icons.explore, label: 'Explore', index: 1),
                  _buildNavItem(icon: Icons.calendar_month_outlined, label: 'Bookings', index: 2),
                  _buildNavItem(icon: Icons.people_alt_outlined, label: 'Queue', index: 3),
                  _buildNavItem(icon: Icons.person_outline, label: 'Profile', index: 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentTab(UserProfile? activeProfile, String userName, String initials) {
    switch (_bottomNavIndex) {
      case 0:
        return _buildHomeView(activeProfile, userName, initials);
      case 1:
        return _buildExploreView();
      case 2:
        return CustomerBookingsView(
          profile: activeProfile,
          onBrowseRestaurants: () => setState(() => _bottomNavIndex = 1),
        );
      case 3:
        return CustomerQueueView(
          profile: activeProfile,
          onBrowseRestaurants: () => setState(() => _bottomNavIndex = 0),
        );
      case 4:
        return CustomerProfileView(
          profile: activeProfile,
          onProfileUpdated: (updated) {
            setState(() {
              _currentProfile = updated;
            });
          },
        );
      default:
        return _buildHomeView(activeProfile, userName, initials);
    }
  }

  // ==========================================
  // --- 1. EXPLORE RESTAURANTS VIEW SCREEN ---
  // ==========================================
  Widget _buildExploreView() {
    final selectedCuisine = _exploreCuisines[_selectedExploreCuisineIndex];
    final searchQuery = _exploreSearchController.text.trim().toLowerCase();

    return StreamBuilder<List<RestaurantModel>>(
      stream: _firestoreService.streamActiveRestaurants(),
      builder: (context, snapshot) {
        final restaurants = snapshot.data ?? [];
        final filtered = restaurants.where((r) {
          // Cuisine Pill Filter
          final matchesCuisine = selectedCuisine == 'All' ||
              r.cuisine.toLowerCase() == selectedCuisine.toLowerCase() ||
              r.tag.toLowerCase().contains(selectedCuisine.toLowerCase());

          // Search query filter
          final matchesQuery = searchQuery.isEmpty ||
              r.name.toLowerCase().contains(searchQuery) ||
              r.cuisine.toLowerCase().contains(searchQuery) ||
              r.location.toLowerCase().contains(searchQuery);

          return matchesCuisine && matchesQuery;
        }).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Screen Title
              const Text(
                'Explore Restaurants',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Discover top dining spots and reserve instantly',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: 16),

              // Search Bar & Filter Button
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.search_rounded,
                            color: AppColors.textMuted,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _exploreSearchController,
                              decoration: const InputDecoration(
                                hintText: 'Search cuisine or restaurant',
                                hintStyle: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 13,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                          if (_exploreSearchController.text.isNotEmpty)
                            GestureDetector(
                              onTap: () => _exploreSearchController.clear(),
                              child: const Icon(Icons.clear, size: 18, color: AppColors.textMuted),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D3B2E),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.tune_rounded, color: Colors.white, size: 20),
                      onPressed: _showFilterBottomSheet,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Cuisine Filter Pills
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(_exploreCuisines.length, (index) {
                    final isSelected = _selectedExploreCuisineIndex == index;
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _selectedExploreCuisineIndex = index);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF0D3B2E) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF0D3B2E) : AppColors.border,
                            ),
                          ),
                          child: Text(
                            _exploreCuisines[index],
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              color: isSelected ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 20),

              // Restaurant Cards List
              if (filtered.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.search_off_rounded, size: 40, color: AppColors.textMuted),
                      const SizedBox(height: 12),
                      const Text(
                        'No Restaurants Match Your Search',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Try clearing search filters or choosing another cuisine.',
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                )
              else
                ...filtered.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildExploreCard(restaurant: item),
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExploreCard({
    required RestaurantModel restaurant,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RestaurantDetailsScreen(
              restaurant: restaurant,
              profile: widget.profile,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero banner
            Container(
              height: 145,
              width: double.infinity,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                gradient: LinearGradient(
                  colors: [Color(0xFF1B4D3E), Color(0xFF0B2B1F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -10,
                    bottom: -10,
                    child: Icon(
                      Icons.restaurant_rounded,
                      size: 115,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  Positioned(
                    left: 14,
                    bottom: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.restaurant_menu_rounded, size: 13, color: Colors.white),
                          const SizedBox(width: 5),
                          Text(
                            restaurant.tag,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        restaurant.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 17),
                          const SizedBox(width: 3),
                          Text(
                            restaurant.rating.toString(),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            ' (${restaurant.reviewsCount})',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    restaurant.location,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            restaurant.isQueueAvailable ? Icons.check_circle_rounded : Icons.calendar_today_rounded,
                            size: 15,
                            color: restaurant.isQueueAvailable ? const Color(0xFF10B981) : AppColors.accentOrange,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            restaurant.estWait,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: restaurant.isQueueAvailable ? const Color(0xFF10B981) : AppColors.accentOrange,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () {
                          if (restaurant.isQueueAvailable) {
                            _handleJoinQueue(restaurant);
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RestaurantDetailsScreen(
                                  restaurant: restaurant,
                                  profile: widget.profile,
                                ),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D3B2E),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          restaurant.isQueueAvailable ? 'Join Queue' : 'Book Table',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // --- 2. HOME VIEW SCREEN ---
  // ==========================================
  Widget _buildHomeView(UserProfile? activeProfile, String userName, String initials) {
    final userId = activeProfile?.id ?? 'guest_id';
    final homeQuery = _homeSearchController.text.trim().toLowerCase();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Header: Avatar + Greeting/Name + DineQueue Brand + Notification
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left: Avatar + Greeting & Name
              Row(
                children: [
                  UserAvatar(
                    profile: activeProfile,
                    name: userName,
                    size: 44,
                    onTap: () async {
                      final updated = await Navigator.push<UserProfile>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditProfileScreen(profile: activeProfile),
                        ),
                      );
                      if (updated != null && mounted) {
                        setState(() => _currentProfile = updated);
                      }
                    },
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getGreeting(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Right: DineQueue & Notification Bell
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HomeScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.restaurant_rounded,
                            size: 13,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'DineQueue',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _showNotificationsBottomSheet,
                    child: Stack(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Icon(
                            Icons.notifications_none_rounded,
                            color: AppColors.textPrimary,
                            size: 22,
                          ),
                        ),
                        ListenableBuilder(
                          listenable: CustomerNotificationCenter.instance,
                          builder: (context, _) {
                            final unread = CustomerNotificationCenter.instance.unreadCount;
                            if (unread == 0) return const SizedBox.shrink();
                            return Positioned(
                              top: 1,
                              right: 1,
                              child: Container(
                                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                decoration: const BoxDecoration(
                                  color: AppColors.accentOrange,
                                  borderRadius: BorderRadius.all(Radius.circular(10)),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  unread > 9 ? '9+' : '$unread',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Location Selector
          Row(
            children: [
              const Icon(
                Icons.location_on_rounded,
                color: AppColors.accentOrange,
                size: 16,
              ),
              const SizedBox(width: 4),
              const Text(
                'Colombo, Sri Lanka',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 2),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.textMuted,
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search Bar & Filter Button
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.search_rounded,
                        color: AppColors.textMuted,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _homeSearchController,
                          decoration: const InputDecoration(
                            hintText: 'Search restaurants or cuisines',
                            hintStyle: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      if (_homeSearchController.text.isNotEmpty)
                        GestureDetector(
                          onTap: () => _homeSearchController.clear(),
                          child: const Icon(Icons.clear, size: 18, color: AppColors.textMuted),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF0D3B2E),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: IconButton(
                  icon: const Icon(Icons.tune_rounded, color: Colors.white, size: 20),
                  onPressed: _showFilterBottomSheet,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Category Filter Pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_homeCategories.length, (index) {
                final isSelected = _selectedCategoryIndex == index;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _selectedCategoryIndex = index);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF0D3B2E) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF0D3B2E) : AppColors.border,
                        ),
                      ),
                      child: Text(
                        _homeCategories[index],
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 24),

          // --- Realtime Customer Active Queue Banner ---
          StreamBuilder<QueueEntryModel?>(
            stream: _firestoreService.streamCustomerActiveQueue(userId),
            builder: (context, queueSnapshot) {
              final activeQueue = queueSnapshot.data;
              if (activeQueue == null) {
                return const SizedBox.shrink();
              }

              return GestureDetector(
                onTap: () => setState(() => _bottomNavIndex = 3),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF9EC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFFE8B2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF6B4A),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          activeQueue.queueNumber,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Virtual Queue: Position #${activeQueue.position}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFD9531E),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${activeQueue.restaurantName} • Est. wait ${activeQueue.estimatedWaitMinutes} min',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.accentOrange,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Your Upcoming Reservation Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Your Upcoming Reservation',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _bottomNavIndex = 2),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'View All',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accentOrange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Upcoming Reservation Card (Stream from Firestore)
          StreamBuilder<List<ReservationModel>>(
            stream: _firestoreService.streamUserReservations(userId),
            builder: (context, resSnapshot) {
              final reservations = (resSnapshot.data ?? []).where((r) => r.status.toLowerCase() == 'confirmed').toList();
              final res = reservations.isNotEmpty
                  ? reservations.first
                  : null;

              if (res == null) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('No Upcoming Reservations', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
                          SizedBox(height: 2),
                          Text('Book a table in advance anytime', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () => CreateBookingModal.show(context, profile: widget.profile),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D3B2E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        child: const Text('Book Table', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              }

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReservationDetailsScreen(
                        reservation: res,
                        profile: widget.profile,
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                res.restaurantName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'ID: ${res.reservationCode}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: Color(0xFF10B981),
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  res.status.toUpperCase(),
                                  style: const TextStyle(
                                    color: Color(0xFF10B981),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Divider(height: 1, color: AppColors.border),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildReservationDetail(
                            icon: Icons.calendar_today_outlined,
                            text: res.date.isNotEmpty ? res.date : 'Saturday, 12 Sep',
                          ),
                          _buildReservationDetail(
                            icon: Icons.access_time_rounded,
                            text: res.time.isNotEmpty ? res.time : '7:30 PM',
                          ),
                          _buildReservationDetail(
                            icon: Icons.people_outline_rounded,
                            text: '${res.partySize} Guests',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // Restaurants Near You Section (Stream from Firestore)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Restaurants Near You',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Real-time live queue & direct table booking',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          StreamBuilder<List<RestaurantModel>>(
            stream: _firestoreService.streamActiveRestaurants(),
            builder: (context, snapshot) {
              final restaurants = snapshot.data ?? [];
              final filtered = restaurants.where((r) {
                // Search query filter
                if (homeQuery.isNotEmpty) {
                  final matches = r.name.toLowerCase().contains(homeQuery) ||
                      r.cuisine.toLowerCase().contains(homeQuery) ||
                      r.location.toLowerCase().contains(homeQuery);
                  if (!matches) return false;
                }

                // Category filter ('Nearby', 'Available Now', 'Top Rated', 'Popular')
                if (_selectedCategoryIndex == 1) {
                  // Available Now: direct seating or queue available
                  return r.isQueueAvailable;
                } else if (_selectedCategoryIndex == 2) {
                  // Top rated >= 4.8
                  return r.rating >= 4.8;
                }
                return true;
              }).toList();

              if (filtered.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text('No matching restaurants found.', style: TextStyle(color: AppColors.textMuted)),
                  ),
                );
              }

              return Column(
                children: filtered.map((restaurant) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _buildHomeRestaurantCard(restaurant: restaurant),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildReservationDetail({required IconData icon, required String text}) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildHomeRestaurantCard({
    required RestaurantModel restaurant,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RestaurantDetailsScreen(
              restaurant: restaurant,
              profile: widget.profile,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 140,
              width: double.infinity,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                gradient: LinearGradient(
                  colors: [Color(0xFF1B4D3E), Color(0xFF0B2B1F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -10,
                    bottom: -10,
                    child: Icon(
                      Icons.restaurant_rounded,
                      size: 110,
                      color: Colors.white.withValues(alpha: 0.07),
                    ),
                  ),
                  Positioned(
                    left: 14,
                    bottom: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.restaurant_menu_rounded, size: 13, color: Colors.white),
                          const SizedBox(width: 5),
                          Text(
                            restaurant.tag,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        restaurant.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 16),
                          const SizedBox(width: 2),
                          Text(
                            restaurant.rating.toString(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            ' (${restaurant.reviewsCount})',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    restaurant.location,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: restaurant.isQueueAvailable ? const Color(0xFF10B981) : AppColors.accentOrange,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            restaurant.isQueueAvailable ? '${restaurant.waitlistCount} in queue • ${restaurant.estWait}' : restaurant.estWait,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: restaurant.isQueueAvailable ? const Color(0xFF10B981) : AppColors.accentOrange,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () {
                          if (restaurant.isQueueAvailable) {
                            _handleJoinQueue(restaurant);
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RestaurantDetailsScreen(
                                  restaurant: restaurant,
                                  profile: widget.profile,
                                ),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D3B2E),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          restaurant.isQueueAvailable ? 'Join Queue' : 'Book Table',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({required IconData icon, required String label, required int index}) {
    final isSelected = _bottomNavIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _bottomNavIndex = index);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 22,
            color: isSelected ? const Color(0xFF0D3B2E) : AppColors.textMuted,
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? const Color(0xFF0D3B2E) : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
