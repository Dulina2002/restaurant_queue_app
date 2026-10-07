import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/admin_supabase_service.dart';
import '../home_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  final UserProfile profile;
  final AdminSupabaseService? adminService;

  const AdminDashboardScreen(
      {super.key, required this.profile, this.adminService});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AuthService _authService = AuthService();
  bool _isSigningOut = false;
  bool _loading = true;
  String _restaurantSource = 'Loading restaurants';
  String _userSource = 'Loading profiles';

  Future<void> _signOut() async {
    setState(() => _isSigningOut = true);
    try {
      await _authService.signOut();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to sign out: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSigningOut = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    final service = widget.adminService ?? AdminSupabaseService();
    await Future.wait([_loadRestaurants(service), _loadUsers(service)]);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadRestaurants(AdminSupabaseService service) async {
    try {
      final rows = await service.loadRestaurants();
      if (!mounted) return;
      setState(() {
        if (rows != null) {
          restaurants
            ..clear()
            ..addAll(rows);
          _restaurantSource = 'Supabase restaurants snapshot';
        } else {
          _restaurantSource = 'Example restaurants: Supabase not configured';
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() =>
          _restaurantSource = 'Example restaurants: Supabase read failed');
    }
  }

  Future<void> _loadUsers(AdminSupabaseService service) async {
    try {
      final rows = await service.loadUsers();
      if (!mounted) return;
      setState(() {
        if (rows != null) {
          users
            ..clear()
            ..addAll(rows);
          _userSource = 'Supabase profiles snapshot';
        } else {
          _userSource = 'Example users: Supabase not configured';
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _userSource = 'Example users: Supabase read failed');
    }
  }

  int selectedTab = 0;
  bool platformFrozen = false;
  final List<Map<String, String>> broadcasts = [];

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

  final List<Map<String, dynamic>> users = [
    {
      'name': 'Ayesha Perera',
      'email': 'ayesha@email.com',
      'role': 'Customer',
      'suspended': false,
    },
    {
      'name': 'David Fernando',
      'email': 'david@oceanbistro.com',
      'role': 'Receptionist',
      'suspended': false,
    },
    {
      'name': 'Chef Matteo',
      'email': 'matteo@oceanbistro.com',
      'role': 'Manager',
      'suspended': false,
    },
    {
      'name': 'Minoshi',
      'email': 'admin@dinequeue.com',
      'role': 'Admin',
      'suspended': false,
    },
  ];

  final List<String> userRoles = [
    'Customer',
    'Receptionist',
    'Manager',
    'Admin',
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
        actions: [
          IconButton(
            tooltip: 'Sign Out',
            onPressed: _isSigningOut ? null : _signOut,
            icon: _isSigningOut
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.logout),
          ),
        ],
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
              Text('$_restaurantSource • $_userSource',
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 8),
              const Text(
                'Preview mode: all changes apply to this session only. No database records or accounts are changed.',
                style: TextStyle(color: Colors.deepOrange, fontSize: 12),
              ),
              const SizedBox(height: 16),
              if (_loading) const Center(child: CircularProgressIndicator()),
              if (!_loading && selectedTab == 0) _buildRestaurants(),
              if (!_loading && selectedTab == 1) _buildUsers(),
              if (!_loading && selectedTab == 2) _buildBroadcasts(),
              if (!_loading && selectedTab == 3) _buildSystem(),
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
        Expanded(
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
                'Lead Admin: ${widget.profile.fullName} • ${widget.profile.email}',
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
            value: users.length.toString(),
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
              color: iconColor.withValues(alpha: 0.08),
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
          _emptyMessage(
            Icons.store_outlined,
            'No partner restaurants available.',
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

    final Color statusColor =
        available ? const Color(0xFF1B8F5A) : const Color(0xFFF47B4A);

    final details =
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
                  color: statusColor.withValues(alpha: 0.10),
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
                onPressed: () => _toggleRestaurantStatus(index),
                icon: const Icon(Icons.sync, size: 17),
                label: const Text('Toggle Status'),
              ),
              TextButton.icon(
                onPressed: () => _showEditRestaurantDialog(index),
                icon: const Icon(Icons.edit, size: 17),
                label: const Text('Edit'),
              ),
              TextButton.icon(
                onPressed: () => _showDeleteRestaurantDialog(index),
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
                  _dialogTextField(
                    nameController,
                    'Restaurant Name',
                    'e.g. Spice Garden',
                  ),
                  const SizedBox(height: 15),
                  _dialogTextField(
                    cuisineController,
                    'Cuisine Type',
                    'e.g. Sri Lankan',
                  ),
                  const SizedBox(height: 15),
                  _dialogTextField(priceController, 'Price Level', r'e.g. $$'),
                  const SizedBox(height: 15),
                  _dialogTextField(
                    addressController,
                    'Address',
                    'e.g. Colombo 03',
                  ),
                  const SizedBox(height: 15),
                  _dialogTextField(
                    phoneController,
                    'Contact Number',
                    '+94 77 123 4567',
                  ),
                  const SizedBox(height: 15),
                  _dialogTextField(
                    waitTimeController,
                    'Estimated Wait Time',
                    'e.g. 10m',
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: _greenButtonStyle(),
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
    final waitController = TextEditingController(text: restaurant['waitTime']);

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
                  _dialogTextField(nameController, 'Restaurant Name', ''),
                  const SizedBox(height: 15),
                  _dialogTextField(cuisineController, 'Cuisine Type', ''),
                  const SizedBox(height: 15),
                  _dialogTextField(priceController, 'Price Level', ''),
                  const SizedBox(height: 15),
                  _dialogTextField(addressController, 'Address', ''),
                  const SizedBox(height: 15),
                  _dialogTextField(phoneController, 'Contact Number', ''),
                  const SizedBox(height: 15),
                  _dialogTextField(waitController, 'Estimated Wait Time', ''),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: _greenButtonStyle(),
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
                  restaurants[index]['price'] = priceController.text.trim();
                  restaurants[index]['address'] = addressController.text.trim();
                  restaurants[index]['phone'] = phoneController.text.trim();
                  restaurants[index]['waitTime'] = waitController.text.trim();
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

  void _showDeleteRestaurantDialog(int index) {
    final name = restaurants[index]['name']!;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(
            Icons.warning_amber_rounded,
            color: Colors.deepOrange,
            size: 45,
          ),
          title: const Text('Delete Restaurant?', textAlign: TextAlign.center),
          content: Text(
            'Are you sure you want to remove "$name" from the platform?\n\nThis action cannot be undone.',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(dialogContext),
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
                _showMessage('$name deleted');
              },
              icon: const Icon(Icons.delete_outline),
              label: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _toggleRestaurantStatus(int index) {
    setState(() {
      if (restaurants[index]['status'] == 'Tables Available') {
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
              onPressed: _showAddUserDialog,
              style: _greenButtonStyle(),
              icon: const Icon(Icons.person_add),
              label: const Text('New User'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (users.isEmpty)
          _emptyMessage(Icons.people_outline, 'No users available.'),
        ...List.generate(
          users.length,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _userCard(index),
          ),
        ),
      ],
    );
  }

  Widget _userCard(int index) {
    final user = users[index];

    final String name = user['name'];
    final String email = user['email'];
    final String role = user['role'];
    final bool suspended = user['suspended'];

    final String initial =
        name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: suspended ? const Color(0xFFFFF8F5) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: suspended
            ? Border.all(color: Colors.deepOrange.withValues(alpha: 0.25))
            : null,
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
                    const SizedBox(height: 3),
                    Text(email, style: const TextStyle(color: Colors.grey)),
                    if (suspended) ...[
                      const SizedBox(height: 5),
                      const Text(
                        'Account Suspended',
                        style: TextStyle(
                          color: Colors.deepOrange,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Chip(label: Text(role), backgroundColor: const Color(0xFFF1FAF6)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 5,
            children: [
              TextButton.icon(
                onPressed: () => _showChangeRoleDialog(index),
                icon: const Icon(Icons.admin_panel_settings_outlined, size: 18),
                label: const Text('Change Role'),
              ),
              TextButton.icon(
                onPressed: () => _toggleUserSuspension(index),
                icon: Icon(
                  suspended ? Icons.check_circle_outline : Icons.block,
                  size: 18,
                ),
                label: Text(suspended ? 'Activate' : 'Suspend'),
              ),
              TextButton.icon(
                onPressed: () => _showDeleteUserDialog(index),
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
  // ADD USER
  // ============================================================

  void _showAddUserDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();

    String selectedRole = 'Customer';

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Add New User',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF064632),
                ),
              ),
              content: SizedBox(
                width: 450,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _dialogTextField(
                      nameController,
                      'Full Name',
                      'e.g. Nimal Perera',
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        hintText: 'name@email.com',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 15),
                    DropdownButtonFormField<String>(
                      initialValue: selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'User Role',
                        border: OutlineInputBorder(),
                      ),
                      items: userRoles.map((role) {
                        return DropdownMenuItem<String>(
                          value: role,
                          child: Text(role),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            selectedRole = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  style: _greenButtonStyle(),
                  onPressed: () {
                    final name = nameController.text.trim();
                    final email = emailController.text.trim();

                    if (name.isEmpty || email.isEmpty) {
                      _showMessage('Please enter the user name and email.');
                      return;
                    }

                    if (!email.contains('@')) {
                      _showMessage('Please enter a valid email address.');
                      return;
                    }

                    final emailExists = users.any(
                      (user) =>
                          user['email'].toString().toLowerCase() ==
                          email.toLowerCase(),
                    );

                    if (emailExists) {
                      _showMessage('A user with this email already exists.');
                      return;
                    }

                    setState(() {
                      users.add({
                        'name': name,
                        'email': email,
                        'role': selectedRole,
                        'suspended': false,
                      });
                    });

                    Navigator.pop(dialogContext);

                    _showMessage('$name added successfully');
                  },
                  icon: const Icon(Icons.person_add),
                  label: const Text('Create User'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ============================================================
  // CHANGE USER ROLE
  // ============================================================

  void _showChangeRoleDialog(int index) {
    String selectedRole = users[index]['role'];

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Change User Role',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF064632),
                ),
              ),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      users[index]['name'],
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      users[index]['email'],
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      initialValue: selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Select Role',
                        border: OutlineInputBorder(),
                      ),
                      items: userRoles.map((role) {
                        return DropdownMenuItem<String>(
                          value: role,
                          child: Text(role),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            selectedRole = value;
                          });
                        }
                      },
                    ),
                  ],
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
                  style: _greenButtonStyle(),
                  onPressed: () {
                    final String name = users[index]['name'];

                    setState(() {
                      users[index]['role'] = selectedRole;
                    });

                    Navigator.pop(dialogContext);

                    _showMessage('$name role changed to $selectedRole');
                  },
                  child: const Text('Update Role'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ============================================================
  // SUSPEND / ACTIVATE USER
  // ============================================================

  void _toggleUserSuspension(int index) {
    final bool currentlySuspended = users[index]['suspended'];

    final String name = users[index]['name'];

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: Icon(
            currentlySuspended ? Icons.check_circle_outline : Icons.block,
            color: currentlySuspended
                ? const Color(0xFF1B8F5A)
                : Colors.deepOrange,
            size: 42,
          ),
          title: Text(
            currentlySuspended ? 'Activate User?' : 'Suspend User?',
            textAlign: TextAlign.center,
          ),
          content: Text(
            currentlySuspended
                ? 'Restore access for "$name"?'
                : 'Suspend "$name" from accessing the platform?',
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
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: currentlySuspended
                    ? const Color(0xFF00523D)
                    : Colors.deepOrange,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  users[index]['suspended'] = !currentlySuspended;
                });

                Navigator.pop(dialogContext);

                _showMessage(
                  currentlySuspended ? '$name activated' : '$name suspended',
                );
              },
              child: Text(currentlySuspended ? 'Activate' : 'Suspend'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // DELETE USER
  // ============================================================

  void _showDeleteUserDialog(int index) {
    final String name = users[index]['name'];

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
            'Delete User?',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to permanently delete "$name"?\n\nThis action cannot be undone.',
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
                  users.removeAt(index);
                });

                Navigator.pop(dialogContext);

                _showMessage('$name deleted');
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
  // BROADCASTS
  // ============================================================

  Future<void> _showSendAlertDialog() async {
    final formKey = GlobalKey<FormState>();
    String title = '';
    String message = '';
    String priority = 'NORMAL';

    final broadcast = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Send Alert'),
        content: SizedBox(
          width: 450,
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Alert title',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Please enter an alert title.'
                        : null,
                    onSaved: (value) => title = value!.trim(),
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Message',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Please enter a message.'
                        : null,
                    onSaved: (value) => message = value!.trim(),
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    initialValue: priority,
                    decoration: const InputDecoration(
                      labelText: 'Alert type / priority',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'NORMAL', child: Text('Normal')),
                      DropdownMenuItem(
                          value: 'WARNING', child: Text('Warning')),
                      DropdownMenuItem(value: 'URGENT', child: Text('Urgent')),
                    ],
                    validator: (value) => value == null
                        ? 'Please select an alert priority.'
                        : null,
                    onChanged: (value) {
                      if (value != null) priority = value;
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: _greenButtonStyle(),
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              formKey.currentState!.save();
              Navigator.pop(dialogContext, {
                'title': title,
                'message': message,
                'priority': priority,
              });
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
    if (!mounted || broadcast == null) return;
    setState(() => broadcasts.insert(0, broadcast));
    _showMessage('Alert sent successfully');
  }

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
              onPressed: _showSendAlertDialog,
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
        ...broadcasts.map(
          (broadcast) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _broadcastCard(
              title: broadcast['title']!,
              message: broadcast['message']!,
              status: broadcast['priority']!,
              active: true,
              dispatched: 'Dispatched: Just now • Active',
            ),
          ),
        ),
        _broadcastCard(
          title: 'Platform Operational',
          message:
              'Example: All reservation and queue sync services running normally across Colombo partners.',
          status: 'NORMAL',
          active: true,
        ),
        const SizedBox(height: 16),
        _broadcastCard(
          title: 'Scheduled Maintenance',
          message:
              'Example: Monthly infrastructure updates were completed successfully.',
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
    String? dispatched,
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
            dispatched ??
                (active
                    ? 'Dispatched: 10m ago • Active'
                    : 'Dispatched: 2d ago • Archived'),
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SYSTEM
  // ============================================================

  Future<void> _confirmPlatformFreeze(bool value) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
            value ? 'Enable Platform Freeze?' : 'Disable Platform Freeze?'),
        content: Text(value
            ? 'Confirm emergency platform freeze? This updates the local dashboard state only.'
            : 'Confirm disabling the emergency platform freeze?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: _greenButtonStyle(),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    setState(() => platformFrozen = value);
    _showMessage(
        value ? 'Platform freeze enabled' : 'Platform freeze disabled');
  }

  Future<void> _confirmWaitlistFlush() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.deepOrange),
        title: const Text('Global Waitlist Flush?'),
        content: const Text(
          'Flushing waitlists would remove all waiting entries. Confirm this local simulation? No restaurant waitlists will be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    _showMessage('Global waitlist flush simulation completed successfully');
  }

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
                onChanged: _confirmPlatformFreeze,
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
                onPressed: _confirmWaitlistFlush,
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
        _statusRow(
            'Supabase restaurant/profile reads: see source status above'),
        _statusRow('Broadcast delivery: local preview only'),
        _statusRow('Freeze and waitlist flush: local preview only'),
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
  // REUSABLE HELPERS
  // ============================================================

  Widget _dialogTextField(
    TextEditingController controller,
    String label,
    String hint,
  ) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint.isEmpty ? null : hint,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _emptyMessage(IconData icon, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, size: 45, color: Colors.grey),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  ButtonStyle _greenButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF00523D),
      foregroundColor: Colors.white,
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('$message (local preview)'),
          duration: const Duration(seconds: 1)),
    );
  }
}
