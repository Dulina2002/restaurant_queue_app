import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/user_profile.dart';
import '../../models/user_role.dart';
import '../../services/admin_supabase_service.dart';
import '../../services/storage_service.dart';
import '../../services/supabase_service.dart';
import '../../services/restaurant_image_storage.dart';
import '../../shared/widgets/restaurant_image.dart';
import 'admin_theme.dart';
import 'admin_dialogs.dart';

class EditRestaurantScreen extends StatefulWidget {
  final UserProfile profile;
  final AdminSupabaseService adminService;
  final Map<String, String> restaurant;
  final ValueChanged<Map<String, String>> onRestaurantSaved;

  const EditRestaurantScreen({
    super.key,
    required this.profile,
    required this.adminService,
    required this.restaurant,
    required this.onRestaurantSaved,
  });

  @override
  State<EditRestaurantScreen> createState() => _EditRestaurantScreenState();
}

class _EditRestaurantScreenState extends State<EditRestaurantScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _cuisineController;
  late final TextEditingController _addressController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _hoursController;
  late final TextEditingController _capacityController;
  late final TextEditingController _waitController;
  late final TextEditingController _descriptionController;
  final ImagePicker _picker = ImagePicker();

  File? _pickedImageFile;
  late String? _currentImageUrl;
  late bool _isActive;
  bool _saving = false;

  final List<Map<String, String>> _presetImages = const [
    {
      'title': 'Pizza & Italian',
      'url': 'https://images.unsplash.com/photo-1513104890138-7c749659a591?auto=format&fit=crop&w=1200&q=80',
    },
    {
      'title': 'Woodfired Pizza',
      'url': 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?auto=format&fit=crop&w=1200&q=80',
    },
    {
      'title': 'Fine Dining & Bistro',
      'url': 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=1200&q=80',
    },
    {
      'title': 'Italian Dining',
      'url': 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?auto=format&fit=crop&w=1200&q=80',
    },
    {
      'title': 'Contemporary Lounge',
      'url': 'https://images.unsplash.com/photo-1552566626-52f8b828add9?auto=format&fit=crop&w=1200&q=80',
    },
    {
      'title': 'Japanese & Sushi',
      'url': 'https://images.unsplash.com/photo-1579027989536-b7b1f875659b?auto=format&fit=crop&w=1200&q=80',
    },
    {
      'title': 'Seafood Grill',
      'url': 'https://images.unsplash.com/photo-1544025162-d76694265947?auto=format&fit=crop&w=1200&q=80',
    },
    {
      'title': 'Artisan Cafe',
      'url': 'https://images.unsplash.com/photo-1554118811-1e0d58224f24?auto=format&fit=crop&w=1200&q=80',
    },
  ];

  @override
  void initState() {
    super.initState();
    final r = widget.restaurant;
    _currentImageUrl = (r['imageUrl'] != null && r['imageUrl']!.isNotEmpty)
        ? r['imageUrl']
        : RestaurantImageStorage().getImage(id: r['id'], name: r['name'], cuisine: r['cuisine']);
    _nameController = TextEditingController(text: r['name']);
    _cuisineController = TextEditingController(
      text: r['cuisine']?.replaceAll(' • ', ', ') ?? 'Italian, Seafood',
    );
    _addressController = TextEditingController(
      text: r['address']?.isNotEmpty == true
          ? r['address']
          : '42 Marine Drive, Colombo 03',
    );
    _phoneController = TextEditingController(
      text: r['phone'] != null && r['phone'] != 'Not provided'
          ? r['phone']
          : '+94 11 257 8899',
    );
    _emailController = TextEditingController(
      text: r['email']?.isNotEmpty == true
          ? r['email']
          : 'info@oceanbistro.lk',
    );
    _hoursController = TextEditingController(
      text: r['openingHours']?.isNotEmpty == true
          ? r['openingHours']
          : '11:00 AM - 11:00 PM',
    );
    _capacityController = TextEditingController(
      text: r['capacity']?.replaceAll(RegExp(r'[^0-9]'), '') ?? '50',
    );
    _waitController = TextEditingController(
      text: r['waitTime']?.replaceAll(RegExp(r'[^0-9]'), '') ?? '0',
    );
    _descriptionController = TextEditingController(
      text: r['description']?.isNotEmpty == true
          ? r['description']
          : 'A premium dining experience overlooking the ocean, specializing in fresh seafood and authentic Italian cuisine.',
    );
    _isActive = r['status'] == 'Tables Available' || r['status'] == 'Active';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cuisineController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _hoursController.dispose();
    _capacityController.dispose();
    _waitController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _openSwitchRoleModal() {
    showDialog<void>(
      context: context,
      builder: (_) => SwitchRoleDialog(
        profile: widget.profile,
        currentRole: UserRole.admin,
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 900,
        imageQuality: 85,
      );

      if (picked != null) {
        setState(() {
          _pickedImageFile = File(picked.path);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open camera/gallery ($e). You can choose a preset photo.'),
          action: SnackBarAction(
            label: 'Presets',
            onPressed: _showPresetPickerSheet,
          ),
        ),
      );
    }
  }

  void _showPresetPickerSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Choose Restaurant Photo',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AdminTheme.textDark,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: AdminTheme.textSecondary),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _presetImages.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final item = _presetImages[index];
                    final url = item['url']!;
                    final title = item['title']!;
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        setState(() {
                          _currentImageUrl = url;
                          _pickedImageFile = null;
                        });
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              url,
                              width: 110,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            width: 110,
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  void _showImagePickerSheet() {
    final hasImage = _pickedImageFile != null || (_currentImageUrl != null && _currentImageUrl!.isNotEmpty);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Change Restaurant Photo',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AdminTheme.textDark,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: AdminTheme.textSecondary),
                    onPressed: () => Navigator.pop(sheetContext),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5F6EC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library_outlined, color: AdminTheme.primaryDark, size: 22),
                ),
                title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                subtitle: const Text('Select a photo from device storage', style: TextStyle(fontSize: 12, color: AdminTheme.textSecondary)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickImage(ImageSource.gallery);
                },
              ),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5F6EC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.camera_alt_outlined, color: AdminTheme.primaryDark, size: 22),
                ),
                title: const Text('Take a Photo', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                subtitle: const Text('Use camera to photograph restaurant', style: TextStyle(fontSize: 12, color: AdminTheme.textSecondary)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickImage(ImageSource.camera);
                },
              ),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.collections_outlined, color: Color(0xFFEA580C), size: 22),
                ),
                title: const Text('Choose Curated Preset', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                subtitle: const Text('Select from high quality restaurant photos', style: TextStyle(fontSize: 12, color: AdminTheme.textSecondary)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showPresetPickerSheet();
                },
              ),
              if (hasImage) ...[
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 22),
                  ),
                  title: const Text('Remove Custom Photo', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFFEF4444))),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    setState(() {
                      _pickedImageFile = null;
                      _currentImageUrl = 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=1200&q=80';
                    });
                  },
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    final name = _nameController.text.trim();
    final cuisine = _cuisineController.text.trim();
    final address = _addressController.text.trim();
    final rawWait = _waitController.text.trim();
    final waitMinutes = int.tryParse(rawWait.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    final wait = '${waitMinutes}m';
    final computedStatus = waitMinutes == 0 ? 'Tables Available' : 'Few Tables Left';

    setState(() => _saving = true);
    try {
      final id = widget.restaurant['id'] ?? 'restaurant';

      // 1. Upload picked file if newly chosen
      if (_pickedImageFile != null) {
        final uploaded = await SupabaseStorageService().uploadRestaurantImage(
          restaurantId: id,
          imageFile: _pickedImageFile!,
        );
        _currentImageUrl = uploaded;
        await RestaurantImageStorage().saveImage(
          id: id,
          name: name,
          imageUrl: uploaded,
        );
      }

      if (_currentImageUrl != null && _currentImageUrl!.isNotEmpty) {
        await RestaurantImageStorage().saveImage(
          id: id,
          name: name,
          imageUrl: _currentImageUrl!,
        );
      }

      // 2. Persist to Supabase
      if (id.isNotEmpty) {
        await widget.adminService.updateRestaurant(
          id: id,
          name: name,
          cuisine: cuisine,
          location: address,
          estimatedWait: wait,
          imageUrl: _currentImageUrl,
        );
      }

      final Map<String, String> updated = {
        ...widget.restaurant,
        'name': name,
        'cuisine': cuisine.contains(',') ? cuisine.replaceAll(', ', ' • ') : cuisine,
        'address': address,
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'openingHours': _hoursController.text.trim(),
        'capacity': '${_capacityController.text.trim()} Guests',
        'waitTime': wait,
        'imageUrl': _currentImageUrl ?? '',
        'description': _descriptionController.text.trim(),
        'status': _isActive ? computedStatus : 'Few Tables Left',
      };

      // 3. Immediately sync to in-memory active cache so customer screens show it instantly
      SupabaseService().syncRestaurant(
        id: id,
        name: name,
        cuisine: cuisine,
        location: address,
        estWait: wait,
        imageUrl: _currentImageUrl,
        isActive: _isActive,
      );

      widget.onRestaurantSaved(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$name updated successfully')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update restaurant: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.background,
      body: Column(
        children: [
          // Green Header Area
          Container(
            color: AdminTheme.headerGreen,
            child: SafeArea(
              bottom: false,
              child: _buildTopBar(),
            ),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with back arrow & title
                      Row(
                        children: [
                          InkWell(
                            onTap: () => Navigator.of(context).pop(),
                            borderRadius: BorderRadius.circular(20),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(Icons.arrow_back_rounded,
                                  color: AdminTheme.textDark, size: 22),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Edit Restaurant',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AdminTheme.textDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // RESTAURANT IMAGE label
                      _sectionHeader('RESTAURANT IMAGE'),
                      const SizedBox(height: 8),
                      // Image with "Change Photo" overlay button
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (_pickedImageFile != null)
                              Image.file(
                                _pickedImageFile!,
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              )
                            else
                              RestaurantImage(
                                imageUrl: _currentImageUrl,
                                restaurantId: widget.restaurant['id'],
                                restaurantName: widget.restaurant['name'],
                                cuisine: widget.restaurant['cuisine'],
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            Container(
                              height: 150,
                              width: double.infinity,
                              color: Colors.black.withValues(alpha: 0.25),
                            ),
                            InkWell(
                              onTap: _showImagePickerSheet,
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.15),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.camera_alt_outlined,
                                        size: 16, color: AdminTheme.textDark),
                                    SizedBox(width: 6),
                                    Text(
                                      'Change Photo',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AdminTheme.textDark,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      _sectionHeader('RESTAURANT NAME'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _nameController,
                        decoration: AdminTheme.inputDecoration(),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Name is required'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      _sectionHeader('CUISINE TYPE'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _cuisineController,
                        decoration: AdminTheme.inputDecoration(),
                      ),
                      const SizedBox(height: 14),
                      _sectionHeader('ADDRESS'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _addressController,
                        decoration: AdminTheme.inputDecoration(),
                      ),
                      const SizedBox(height: 14),
                      _sectionHeader('CONTACT NUMBER'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _phoneController,
                        decoration: AdminTheme.inputDecoration(),
                      ),
                      const SizedBox(height: 14),
                      _sectionHeader('EMAIL ADDRESS'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _emailController,
                        decoration: AdminTheme.inputDecoration(),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _sectionHeader('OPENING HOURS'),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _hoursController,
                                  decoration: AdminTheme.inputDecoration(),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _sectionHeader('CAPACITY'),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _capacityController,
                                  keyboardType: TextInputType.number,
                                  decoration: AdminTheme.inputDecoration(),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _sectionHeader('WAIT (MIN)'),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _waitController,
                                  keyboardType: TextInputType.number,
                                  decoration: AdminTheme.inputDecoration(),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Live Customer button indicator
                      Builder(
                        builder: (context) {
                          final raw = _waitController.text.trim();
                          final mins = int.tryParse(raw.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                          final isDirect = mins == 0;
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isDirect ? AdminTheme.badgeGreenBg : AdminTheme.badgeOrangeBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isDirect ? Icons.flash_on_rounded : Icons.people_alt_rounded,
                                  size: 16,
                                  color: isDirect ? AdminTheme.badgeGreenText : AdminTheme.badgeOrangeText,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    isDirect
                                        ? 'Wait time: 0m → Customer button: Direct Booking'
                                        : 'Wait time: ${mins}m → Customer button: Join Queue',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: isDirect ? AdminTheme.badgeGreenText : AdminTheme.badgeOrangeText,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      _sectionHeader('SHORT DESCRIPTION'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _descriptionController,
                        minLines: 3,
                        maxLines: 5,
                        decoration: AdminTheme.inputDecoration(),
                      ),
                      const SizedBox(height: 18),
                      // Status Switch Card
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: AdminTheme.borderSubtle, width: 1),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _isActive
                                    ? AdminTheme.badgeGreenText
                                    : AdminTheme.badgeOrangeText,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Current Status: ${_isActive ? 'Active' : 'Limited'}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AdminTheme.textDark,
                                ),
                              ),
                            ),
                            Switch(
                              value: _isActive,
                              activeThumbColor: Colors.white,
                              activeTrackColor: const Color(0xFF0F7A4A),
                              onChanged: (val) =>
                                  setState(() => _isActive = val),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Buttons
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _saving ? null : _handleSave,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AdminTheme.primaryDark,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.check_rounded, size: 20),
                          label: _saving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Save Changes',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            backgroundColor: AdminTheme.cancelBtnBg,
                            foregroundColor: const Color(0xFF4A5D54),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
                  _buildBottomNav(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: AdminTheme.textMuted,
        letterSpacing: 0.6,
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      color: AdminTheme.headerGreen,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AdminTheme.accentOrange,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'ADMINISTRATOR',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Flexible(
            child: InkWell(
              onTap: _openSwitchRoleModal,
              child: const Text(
                'Tap to switch role',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(
                  color: AdminTheme.headerTextMint,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const Spacer(),
          const Text(
            'DineQueue',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AdminTheme.borderSubtle, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.shield_rounded,
                    color: AdminTheme.primaryDark, size: 22),
                SizedBox(height: 2),
                Text(
                  'System',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AdminTheme.primaryDark,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: _openSwitchRoleModal,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.badge_outlined,
                    color: AdminTheme.textSecondary, size: 22),
                SizedBox(height: 2),
                Text(
                  'Roles',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AdminTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
