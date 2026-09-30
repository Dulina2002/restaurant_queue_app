import 'package:flutter/material.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int selectedTab = 0;
  bool platformFrozen = false;

  final List<String> tabs = ['Restaurants', 'Users', 'Broadcasts', 'System'];

  final List<Map<String, String>> restaurants = [
    {
      'name': 'Ocean Bistro',
      'cuisine': 'Italian • Seafood',
      'price': r'$$$',
      'address': '42 Marine Drive',
      'phone': '+94 11 257 8899',
      'waitTime': '0m',
      'status': 'Tables Available',
    },
    {
      'name': 'The Mango Tree',
      'cuisine': 'Indian • North Indian',
      'price': r'$$',
      'address': '82 Dharmapala',
      'phone': '+94 11 762 0145',
      'waitTime': '15m',
      'status': 'Few Tables Left',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FAF8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00523D),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Platform Administration',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildSummaryCards(),
              const SizedBox(height: 28),
              _buildTabs(),
              const SizedBox(height: 30),

              if (selectedTab == 0) _buildRestaurants(),
              if (selectedTab == 1) _buildUsers(),
              if (selectedTab == 2) _buildBroadcasts(),
              if (selectedTab == 3) _buildSystem(),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Platform\nAdministration',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF064632),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Lead Admin: Minoshi • DineQueue Global',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFE5F6EB),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'SUPERADMIN',
            style: TextStyle(
              color: Color(0xFF075B3E),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            title: 'Restaurants',
            value: restaurants.length.toString(),
            icon: Icons.store,
            iconColor: const Color(0xFF00735A),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _summaryCard(
            title: 'Platform Users',
            value: '4',
            icon: Icons.people,
            iconColor: const Color(0xFFF47B4A),
          ),
        ),
      ],
    );
  }

  Widget _summaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF073F2E),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TABS
  // ============================================================

  Widget _buildTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(tabs.length, (index) {
          final bool selected = selectedTab == index;

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(25),
              onTap: () {
                setState(() {
                  selectedTab = index;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFF00523D) : Colors.white,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Text(
                  tabs[index],
                  style: TextStyle(
                    color: selected ? Colors.white : const Color(0xFF59636A),
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ============================================================
  // RESTAURANTS
  // ============================================================

  Widget _buildRestaurants() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Partner Restaurants (${restaurants.length})',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF064632),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Add, Edit, Update Status, or Remove',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: _showAddPartnerDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00523D),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 18,
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Add Partner'),
            ),
          ],
        ),
        const SizedBox(height: 22),

        if (restaurants.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Column(
              children: [
                Icon(Icons.store_outlined, size: 45, color: Colors.grey),
                SizedBox(height: 12),
                Text(
                  'No partner restaurants available.',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),

        ...List.generate(
          restaurants.length,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: _restaurantCard(index),
          ),
        ),
      ],
    );
  }

  Widget _restaurantCard(int index) {
    final restaurant = restaurants[index];

    final bool available = restaurant['status'] == 'Tables Available';

    final Color statusColor = available
        ? const Color(0xFF1B8F5A)
        : const Color(0xFFF47B4A);

    final String details =
        '${restaurant['cuisine']} • ${restaurant['price']} • ${restaurant['address']}';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  restaurant['name']!,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF073F2E),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  restaurant['status']!,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(details, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 6),
          Text(
            'Tel: ${restaurant['phone']} | Est Wait: ${restaurant['waitTime']}',
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              TextButton.icon(
                onPressed: () {
                  _toggleRestaurantStatus(index);
                },
                icon: const Icon(Icons.sync, size: 17),
                label: const Text('Toggle Status'),
              ),
              TextButton.icon(
                onPressed: () {
                  _showEditRestaurantDialog(index);
                },
                icon: const Icon(Icons.edit, size: 17),
                label: const Text('Edit'),
              ),
              TextButton.icon(
                onPressed: () {
                  _showDeleteRestaurantDialog(index);
                },
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.deepOrange,
                  size: 18,
                ),
                label: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.deepOrange),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ADD RESTAURANT
  // ============================================================

  void _showAddPartnerDialog() {
    final nameController = TextEditingController();
    final cuisineController = TextEditingController();
    final priceController = TextEditingController();
    final addressController = TextEditingController();
    final phoneController = TextEditingController();
    final waitTimeController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Add Partner Restaurant',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF064632),
            ),
          ),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Restaurant Name',
                      hintText: 'e.g. Spice Garden',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: cuisineController,
                    decoration: const InputDecoration(
                      labelText: 'Cuisine Type',
                      hintText: 'e.g. Sri Lankan',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: priceController,
                    decoration: const InputDecoration(
                      labelText: 'Price Level',
                      hintText: r'e.g. $$',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: addressController,
                    decoration: const InputDecoration(
                      labelText: 'Address',
                      hintText: 'e.g. Colombo 03',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Contact Number',
                      hintText: '+94 77 123 4567',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: waitTimeController,
                    decoration: const InputDecoration(
                      labelText: 'Estimated Wait Time',
                      hintText: 'e.g. 10m',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00523D),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final name = nameController.text.trim();
                final cuisine = cuisineController.text.trim();

                if (name.isEmpty || cuisine.isEmpty) {
                  _showMessage('Please enter restaurant name and cuisine.');
                  return;
                }

                setState(() {
                  restaurants.add({
                    'name': name,
                    'cuisine': cuisine,
                    'price': priceController.text.trim().isEmpty
                        ? r'$$'
                        : priceController.text.trim(),
                    'address': addressController.text.trim().isEmpty
                        ? 'Address not provided'
                        : addressController.text.trim(),
                    'phone': phoneController.text.trim().isEmpty
                        ? 'Not provided'
                        : phoneController.text.trim(),
                    'waitTime': waitTimeController.text.trim().isEmpty
                        ? '0m'
                        : waitTimeController.text.trim(),
                    'status': 'Tables Available',
                  });
                });

                Navigator.pop(dialogContext);

                _showMessage('$name added successfully');
              },
              child: const Text('Add Partner'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // EDIT RESTAURANT
  // ============================================================

  void _showEditRestaurantDialog(int index) {
    final restaurant = restaurants[index];

    final nameController = TextEditingController(text: restaurant['name']);

    final cuisineController = TextEditingController(
      text: restaurant['cuisine'],
    );

    final priceController = TextEditingController(text: restaurant['price']);

    final addressController = TextEditingController(
      text: restaurant['address'],
    );

    final phoneController = TextEditingController(text: restaurant['phone']);

    final waitTimeController = TextEditingController(
      text: restaurant['waitTime'],
    );

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Edit Restaurant',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF064632),
            ),
          ),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Restaurant Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: cuisineController,
                    decoration: const InputDecoration(
                      labelText: 'Cuisine Type',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: priceController,
                    decoration: const InputDecoration(
                      labelText: 'Price Level',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: addressController,
                    decoration: const InputDecoration(
                      labelText: 'Address',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Contact Number',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: waitTimeController,
                    decoration: const InputDecoration(
                      labelText: 'Estimated Wait Time',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00523D),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final name = nameController.text.trim();
                final cuisine = cuisineController.text.trim();

                if (name.isEmpty || cuisine.isEmpty) {
                  _showMessage('Restaurant name and cuisine cannot be empty.');
                  return;
                }

                setState(() {
                  restaurants[index]['name'] = name;
                  restaurants[index]['cuisine'] = cuisine;

                  restaurants[index]['price'] =
                      priceController.text.trim().isEmpty
                      ? r'$$'
                      : priceController.text.trim();

                  restaurants[index]['address'] =
                      addressController.text.trim().isEmpty
                      ? 'Address not provided'
                      : addressController.text.trim();

                  restaurants[index]['phone'] =
                      phoneController.text.trim().isEmpty
                      ? 'Not provided'
                      : phoneController.text.trim();

                  restaurants[index]['waitTime'] =
                      waitTimeController.text.trim().isEmpty
                      ? '0m'
                      : waitTimeController.text.trim();
                });

                Navigator.pop(dialogContext);

                _showMessage('$name updated successfully');
              },
              child: const Text('Save Changes'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // DELETE RESTAURANT
  // ============================================================

  void _showDeleteRestaurantDialog(int index) {
    final String restaurantName = restaurants[index]['name']!;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(
            Icons.warning_amber_rounded,
            color: Colors.deepOrange,
            size: 45,
          ),
          title: const Text(
            'Delete Restaurant?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF064632),
            ),
          ),
          content: Text(
            'Are you sure you want to remove "$restaurantName" from the platform?\n\nThis action cannot be undone.',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            OutlinedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  restaurants.removeAt(index);
                });

                Navigator.pop(dialogContext);

                _showMessage('$restaurantName deleted');
              },
              icon: const Icon(Icons.delete_outline),
              label: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // TOGGLE RESTAURANT STATUS
  // ============================================================

  void _toggleRestaurantStatus(int index) {
    final String currentStatus = restaurants[index]['status']!;

    setState(() {
      if (currentStatus == 'Tables Available') {
        restaurants[index]['status'] = 'Few Tables Left';
        restaurants[index]['waitTime'] = '15m';
      } else {
        restaurants[index]['status'] = 'Tables Available';
        restaurants[index]['waitTime'] = '0m';
      }
    });

    _showMessage('${restaurants[index]['name']} status updated');
  }

  // ============================================================
  // USERS
  // ============================================================

  Widget _buildUsers() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'User Directory & Access Control',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF064632),
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Manage system access, roles, and account status',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                _showMessage('New User clicked');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00523D),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.person_add),
              label: const Text('New User'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _userCard(
          name: 'Ayesha Perera',
          email: 'ayesha@email.com',
          role: 'Customer',
          initial: 'A',
        ),
        const SizedBox(height: 14),
        _userCard(
          name: 'David Fernando',
          email: 'david@oceanbistro.com',
          role: 'Receptionist',
          initial: 'D',
        ),
        const SizedBox(height: 14),
        _userCard(
          name: 'Chef Matteo',
          email: 'matteo@oceanbistro.com',
          role: 'Manager',
          initial: 'C',
        ),
      ],
    );
  }

  Widget _userCard({
    required String name,
    required String email,
    required String role,
    required String initial,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFEAF7F1),
                foregroundColor: const Color(0xFF064632),
                child: Text(
                  initial,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    Text(email, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              Chip(label: Text(role), backgroundColor: const Color(0xFFF1FAF6)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            children: [
              TextButton.icon(
                onPressed: () {
                  _showMessage('Change Role for $name');
                },
                icon: const Icon(Icons.admin_panel_settings_outlined, size: 18),
                label: const Text('Change Role'),
              ),
              TextButton.icon(
                onPressed: () {
                  _showMessage('Suspend $name');
                },
                icon: const Icon(Icons.block, size: 18),
                label: const Text('Suspend'),
              ),
              IconButton(
                onPressed: () {
                  _showMessage('Delete $name');
                },
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.deepOrange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BROADCASTS
  // ============================================================

  Widget _buildBroadcasts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'System Broadcast Announcements',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF064632),
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Publish global alerts to all customers & hosts',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                _showMessage('Send Alert clicked');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF47B4A),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.campaign),
              label: const Text('Send Alert'),
            ),
          ],
        ),
        const SizedBox(height: 22),
        _broadcastCard(
          title: 'Platform Operational',
          message: 'All reservation and queue sync services running normally across Colombo partners.',
          status: 'NORMAL',
          active: true,
        ),
        const SizedBox(height: 16),
        _broadcastCard(
          title: 'Scheduled Maintenance',
          message:
              'Monthly infrastructure updates were completed successfully.',
          status: 'PAST',
          active: false,
        ),
      ],
    );
  }

  Widget _broadcastCard({
    required String title,
    required String message,
    required String status,
    required bool active,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                active
                    ? Icons.notifications_active
                    : Icons.warning_amber_rounded,
                color: active ? Colors.deepOrange : Colors.amber,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: Color(0xFF064632),
                  ),
                ),
              ),
              Chip(label: Text(status)),
            ],
          ),
          const SizedBox(height: 14),
          Text(message, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 14),
          Text(
            active
                ? 'Dispatched: 10m ago • Active'
                : 'Dispatched: 2d ago • Archived',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SYSTEM
  // ============================================================

  Widget _buildSystem() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Superadmin Special Control Center',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF064632),
          ),
        ),
        const SizedBox(height: 25),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              const Icon(Icons.emergency, color: Colors.red),
              const SizedBox(width: 15),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Emergency Platform Freeze',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Instant freeze on incoming reservations and waitlists during severe outages or capacity crises.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Switch(
                value: platformFrozen,
                onChanged: (value) {
                  setState(() {
                    platformFrozen = value;
                  });

                  _showMessage(
                    value
                        ? 'Platform freeze enabled'
                        : 'Platform freeze disabled',
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              const Icon(Icons.cleaning_services, color: Colors.brown),
              const SizedBox(width: 15),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Global Waitlist Flush',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Reset all restaurant waitlists at shift conclusion.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  _showMessage('Global waitlist flushed');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF47B20),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Flush'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        const Text(
          'Infrastructure Health & Telemetry',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 18),
        _statusRow('Virtual Queue Sync Socket: Operational (0ms)'),
        _statusRow('Push Notification Gateway: Connected'),
        _statusRow('Automated Double-Booking Prevention: Active'),
      ],
    );
  }

  Widget _statusRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          const Icon(Icons.circle, color: Color(0xFF20B987), size: 10),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 1)),
    );
  }
}
