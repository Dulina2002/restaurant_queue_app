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

class AddRestaurantScreen extends StatefulWidget {
  final UserProfile profile;
  final AdminSupabaseService adminService;
  final void Function(Map<String, String> newRestaurant) onRestaurantAdded;

  const AddRestaurantScreen({
    super.key,
    required this.profile,
    required this.adminService,
    required this.onRestaurantAdded,
  });

  @override
  State<AddRestaurantScreen> createState() => _AddRestaurantScreenState();
}

class _AddRestaurantScreenState extends State<AddRestaurantScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _hoursController = TextEditingController();
  final _capacityController = TextEditingController();
  final _waitController = TextEditingController(text: '0');
  final _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  File? _pickedImageFile;
  String? _selectedImageUrl;
  String? _selectedCuisine;
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

  final List<String> _cuisines = [
    'Pizza • Italian',
    'Italian • Seafood',
    'Indian • North Indian',
    'Seafood • Sri Lankan',
    'Fusion • Contemporary',
    'Southeast Asian • Asian',
    'Japanese • Sushi',
    'Mediterranean',
    'Cafe & Bakery',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _hoursController.dispose();
    _capacityController.dispose();
    _waitController.dispose();
    _descriptionController.dispose();
    super.dispose();
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
          _selectedImageUrl = null;
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
                          _selectedImageUrl = url;
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
    final hasImage = _pickedImageFile != null || _selectedImageUrl != null;

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
                    'Upload Restaurant Image',
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
                  title: const Text('Remove Photo', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFFEF4444))),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    setState(() {
                      _pickedImageFile = null;
                      _selectedImageUrl = null;
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
    final cuisine = _selectedCuisine ?? 'Italian • Seafood';

    setState(() => _saving = true);
    try {
      final location = _addressController.text.trim().isEmpty
          ? '42 Marine Drive, Colombo 03'
          : _addressController.text.trim();
      final phone = _phoneController.text.trim().isEmpty
          ? '+94 11 257 8899'
          : _phoneController.text.trim();
      final rawWait = _waitController.text.trim();
      final waitMinutes = int.tryParse(rawWait.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      final waitTime = '${waitMinutes}m';
      final status = waitMinutes == 0 ? 'Tables Available' : 'Few Tables Left';

      // 1. Resolve image url (upload if local file was selected, or use selected preset / culinary fallback)
      String finalImageUrl = _selectedImageUrl ?? '';

      if (_pickedImageFile != null) {
        final tempId = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
        final uploaded = await SupabaseStorageService().uploadRestaurantImage(
          restaurantId: tempId.isEmpty ? 'restaurant' : tempId,
          imageFile: _pickedImageFile!,
        );
        finalImageUrl = uploaded;
        await RestaurantImageStorage().saveImage(
          id: tempId,
          name: name,
          imageUrl: uploaded,
        );
      }

      if (finalImageUrl.isEmpty) {
        finalImageUrl = RestaurantImageStorage().getImage(name: name, cuisine: cuisine) ??
            'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=1200&q=80';
      }

      // 2. Persist to Supabase
      final row = await widget.adminService.addRestaurant(
        name: name,
        cuisine: cuisine,
        location: location,
        estimatedWait: waitTime,
        imageUrl: finalImageUrl,
      );

      final newId = row?['id'] ?? 'rest_${DateTime.now().millisecondsSinceEpoch}';

      // 3. Immediately persist to RestaurantImageStorage by ID and Name
      await RestaurantImageStorage().saveImage(
        id: newId,
        name: name,
        imageUrl: finalImageUrl,
      );

      final Map<String, String> newRecord = {
        'id': newId,
        'name': name,
        'cuisine': cuisine,
        'price': r'$$$',
        'address': location,
        'phone': phone,
        'email': _emailController.text.trim().isEmpty
            ? 'contact@$name.com'
            : _emailController.text.trim(),
        'openingHours': _hoursController.text.trim().isEmpty
            ? '11:00 AM - 11:00 PM'
            : _hoursController.text.trim(),
        'capacity': _capacityController.text.trim().isEmpty
            ? '50 Guests'
            : '${_capacityController.text.trim()} Guests',
        'description': _descriptionController.text.trim().isEmpty
            ? 'A premium dining experience with exquisite flavours and exceptional service.'
            : _descriptionController.text.trim(),
        'waitTime': waitTime,
        'status': status,
        'imageUrl': finalImageUrl,
      };

      // 4. Immediately sync to in-memory active cache so customer screens show it instantly
      SupabaseService().syncRestaurant(
        id: newId,
        name: name,
        cuisine: cuisine,
        location: location,
        estWait: waitTime,
        imageUrl: finalImageUrl,
        isActive: true,
      );

      widget.onRestaurantAdded(newRecord);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$name added successfully')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add restaurant: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Add Partner Restaurant',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AdminTheme.textDark,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Onboard a new dining partner to the platform',
                        style: TextStyle(
                          fontSize: 13,
                          color: AdminTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 22),
                      _fieldLabel('Restaurant Name'),
                      TextFormField(
                        controller: _nameController,
                        decoration: AdminTheme.inputDecoration(
                          hintText: 'e.g. The Golden Platter',
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Restaurant name is required'
                                : null,
                      ),
                      const SizedBox(height: 14),
                      _fieldLabel('Cuisine Type'),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedCuisine,
                        hint: const Text(
                          'Select Cuisine',
                          style: TextStyle(color: AdminTheme.textMuted, fontSize: 14),
                        ),
                        decoration: AdminTheme.inputDecoration(),
                        icon: const Icon(Icons.keyboard_arrow_down_rounded,
                            color: AdminTheme.textSecondary),
                        items: _cuisines
                            .map((c) =>
                                DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _selectedCuisine = val),
                        validator: (value) =>
                            value == null ? 'Please select a cuisine type' : null,
                      ),
                      const SizedBox(height: 14),
                      _fieldLabel('Address'),
                      TextFormField(
                        controller: _addressController,
                        decoration: AdminTheme.inputDecoration(
                          hintText: 'Full street address',
                        ),
                      ),
                      const SizedBox(height: 14),
                      _fieldLabel('Contact Number'),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: AdminTheme.inputDecoration(
                          hintText: '+94 11 XXX XXXX',
                        ),
                      ),
                      const SizedBox(height: 14),
                      _fieldLabel('Email Address'),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: AdminTheme.inputDecoration(
                          hintText: 'contact@restaurant.com',
                        ),
                      ),
                      const SizedBox(height: 14),
                      _fieldLabel('Opening Hours'),
                      TextFormField(
                        controller: _hoursController,
                        decoration: AdminTheme.inputDecoration(
                          hintText: 'e.g. 10:00 AM - 11:00 PM',
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _fieldLabel('Restaurant Capacity'),
                                TextFormField(
                                  controller: _capacityController,
                                  keyboardType: TextInputType.number,
                                  decoration: AdminTheme.inputDecoration(
                                    hintText: 'e.g. 50',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _fieldLabel('Wait Time (min)'),
                                TextFormField(
                                  controller: _waitController,
                                  keyboardType: TextInputType.number,
                                  decoration: AdminTheme.inputDecoration(
                                    hintText: '0',
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
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
                      _fieldLabel('Short Description'),
                      TextFormField(
                        controller: _descriptionController,
                        minLines: 3,
                        maxLines: 5,
                        decoration: AdminTheme.inputDecoration(
                          hintText:
                              'Briefly describe the dining experience...',
                        ),
                      ),
                      const SizedBox(height: 18),
                      _fieldLabel('Upload Restaurant Image'),
                      _buildImageUploadBox(),
                      const SizedBox(height: 28),
                      // Action Buttons
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _handleSave,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AdminTheme.primaryDark,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _saving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  '+ Save Restaurant',
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

  Widget _buildImageUploadBox() {
    final hasPickedFile = _pickedImageFile != null;
    final hasSelectedUrl = _selectedImageUrl != null;

    if (hasPickedFile || hasSelectedUrl) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFC7D7CF), width: 1.2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Stack(
            children: [
              if (hasPickedFile)
                Image.file(
                  _pickedImageFile!,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                )
              else
                RestaurantImage(
                  imageUrl: _selectedImageUrl,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.2),
                      Colors.black.withValues(alpha: 0.6),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Row(
                  children: [
                    InkWell(
                      onTap: _showImagePickerSheet,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.camera_alt_outlined, size: 15, color: AdminTheme.textDark),
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
                    const Spacer(),
                    InkWell(
                      onTap: () {
                        setState(() {
                          _pickedImageFile = null;
                          _selectedImageUrl = null;
                        });
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.delete_outline_rounded, size: 15, color: Color(0xFFEF4444)),
                            SizedBox(width: 4),
                            Text(
                              'Remove',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFEF4444),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return InkWell(
      onTap: _showImagePickerSheet,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FCFA),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFC7D7CF),
            width: 1.2,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFE5F6EC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.storefront_outlined,
                color: AdminTheme.primaryDark,
                size: 24,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Upload Restaurant Image',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AdminTheme.textDark,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'PNG, JPG up to 10MB',
              style: TextStyle(
                fontSize: 12,
                color: AdminTheme.textSecondary,
              ),
            ),
          ],
        ),
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
                Icon(Icons.shield_rounded, color: AdminTheme.primaryDark, size: 22),
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

  Widget _fieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AdminTheme.textDark,
        ),
      ),
    );
  }
}
