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

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            title: 'Restaurants',
            value: '5',
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

  // ---------------- RESTAURANTS ----------------

  Widget _buildRestaurants() {
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
                    'Partner Restaurants (5)',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF064632),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Add, Edit, Update Status, or Remove',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                _showMessage('Add Partner clicked');
              },
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
        _restaurantCard(
          name: 'Ocean Bistro',
          details: r'Italian • Seafood • $$$ • 42 Marine Drive',
          phone: '+94 11 257 8899',
          waitTime: '0m',
          status: 'Tables Available',
          statusColor: const Color(0xFF1B8F5A),
        ),
        const SizedBox(height: 18),
        _restaurantCard(
          name: 'The Mango Tree',
          details: r'Indian • North Indian • $$ • 82 Dharmapala',
          phone: '+94 11 762 0145',
          waitTime: '15m',
          status: 'Few Tables Left',
          statusColor: const Color(0xFFF47B4A),
        ),
      ],
    );
  }

  Widget _restaurantCard({
    required String name,
    required String details,
    required String phone,
    required String waitTime,
    required String status,
    required Color statusColor,
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
              Expanded(
                child: Text(
                  name,
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
                  status,
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
            'Tel: $phone | Est Wait: $waitTime',
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 15,
            children: [
              TextButton(
                onPressed: () {
                  _showMessage('Status updated for $name');
                },
                child: const Text('Toggle Status'),
              ),
              TextButton.icon(
                onPressed: () {
                  _showMessage('Edit $name');
                },
                icon: const Icon(Icons.edit, size: 17),
                label: const Text('Edit'),
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

  // ---------------- USERS ----------------

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

  // ---------------- BROADCASTS ----------------

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

  // ---------------- SYSTEM ----------------

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

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 1)),
    );
  }
}
