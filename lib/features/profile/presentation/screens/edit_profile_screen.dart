import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../models/user_profile.dart';
import '../../../../services/auth_service.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/user_avatar.dart';

class EditProfileScreen extends StatefulWidget {
  final UserProfile? profile;

  const EditProfileScreen({super.key, this.profile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();

  File? _pickedImageFile;
  String? _currentAvatarUrl;
  bool _imageRemoved = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _nameController.addListener(() => setState(() {}));
  }

  Future<void> _loadProfile() async {
    if (widget.profile != null) {
      _nameController.text = widget.profile!.fullName;
      _emailController.text = widget.profile!.email;
      _phoneController.text = widget.profile!.phoneNumber ?? '';
      _currentAvatarUrl = widget.profile!.avatarUrl;
    } else {
      final currentProf = await _authService.getCurrentUserProfile();
      if (currentProf != null) {
        _nameController.text = currentProf.fullName;
        _emailController.text = currentProf.email;
        _phoneController.text = currentProf.phoneNumber ?? '';
        _currentAvatarUrl = currentProf.avatarUrl;
      } else {
        _nameController.text = (_authService.currentUser?.userMetadata?['full_name'] as String?) ?? 'Customer';
        _emailController.text = _authService.currentUser?.email ?? 'customer@dinequeue.com';
      }
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (picked != null) {
        setState(() {
          _pickedImageFile = File(picked.path);
          _imageRemoved = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      final isMissingPlugin = e.toString().contains('MissingPluginException');
      if (isMissingPlugin) {
        AppToast.show(
          context,
          title: 'Native Camera Restart Required',
          message: 'Camera & Gallery native plugin requires a full app restart. Pick from our Preset Avatars below in the meantime.',
          type: ToastType.warning,
          duration: const Duration(seconds: 5),
          actionLabel: 'Presets',
          onAction: _showPresetAvatarsSheet,
        );
      } else {
        AppToast.showError(
          context,
          'Could not access image: $e',
          title: 'Image Selection Error',
        );
      }
    }
  }

  void _showPresetAvatarsSheet() {
    final List<Map<String, String>> presets = [
      {
        'title': 'Dulina (Default)',
        'url': 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=300&q=80',
      },
      {
        'title': 'Ayesha Perera',
        'url': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=300&q=80',
      },
      {
        'title': 'Foodie Diner',
        'url': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=300&q=80',
      },
      {
        'title': 'Gourmet Lover',
        'url': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=300&q=80',
      },
      {
        'title': 'Chef Special',
        'url': 'https://images.unsplash.com/photo-1577219491135-ce391730fb2c?w=300&q=80',
      },
      {
        'title': 'Bistro Guest',
        'url': 'https://images.unsplash.com/photo-1583394838336-acd977736f90?w=300&q=80',
      },
    ];

    showModalBottomSheet(
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
                    'Choose Preset Avatar',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: AppColors.textMuted),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Select a ready-to-use profile avatar:',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.9,
                ),
                itemCount: presets.length,
                itemBuilder: (context, index) {
                  final preset = presets[index];
                  final url = preset['url']!;
                  final title = preset['title']!;
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() {
                        _currentAvatarUrl = url;
                        _pickedImageFile = null;
                        _imageRemoved = false;
                      });
                    },
                    child: Column(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _currentAvatarUrl == url ? AppColors.primary : const Color(0xFFE2E8F0),
                              width: _currentAvatarUrl == url ? 2.5 : 1,
                            ),
                          ),
                          child: ClipOval(
                            child: Image.network(
                              url,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => const Icon(Icons.person, color: AppColors.primary),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  void _showImagePickerSheet() {
    final hasPhoto = _pickedImageFile != null || (_currentAvatarUrl != null && !_imageRemoved);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
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
                    'Profile Photo',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: AppColors.textMuted),
                    onPressed: () => Navigator.pop(sheetContext),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: AppColors.primary, size: 22),
                ),
                title: const Text(
                  'Take Photo',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                subtitle: const Text(
                  'Use camera to capture a new photo',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickImage(ImageSource.camera);
                },
              ),
              const Divider(height: 1, color: AppColors.border),

              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: Color(0xFF2563EB), size: 22),
                ),
                title: const Text(
                  'Choose from Gallery',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                subtitle: const Text(
                  'Select an image from device gallery',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickImage(ImageSource.gallery);
                },
              ),
              const Divider(height: 1, color: AppColors.border),

              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.face_rounded, color: Color(0xFFEA580C), size: 22),
                ),
                title: const Text(
                  'Choose Preset Avatar',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                subtitle: const Text(
                  'Select from curated avatar gallery',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showPresetAvatarsSheet();
                },
              ),

              if (hasPhoto) ...[
                const Divider(height: 1, color: AppColors.border),
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
                  title: const Text(
                    'Remove Photo',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                  subtitle: const Text(
                    'Revert to initials avatar',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    setState(() {
                      _pickedImageFile = null;
                      _imageRemoved = true;
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

  void _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = widget.profile?.id ?? _authService.currentUser?.id ?? 'user_profile_id';

    setState(() => _isSaving = true);

    try {
      String? avatarUrlToSave = _currentAvatarUrl;

      // 1. Upload picked image if available
      if (_pickedImageFile != null) {
        avatarUrlToSave = await _authService.uploadAvatar(
          userId: userId,
          imageFile: _pickedImageFile!,
        );
      } else if (_imageRemoved) {
        avatarUrlToSave = null;
      }

      // 2. Update profile in Firestore, Supabase, and local session
      final updatedProf = await _authService.updateProfile(
        userId: userId,
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        avatarUrl: avatarUrlToSave,
        clearAvatar: _imageRemoved,
      );

      if (!mounted) return;
      setState(() => _isSaving = false);

      AppToast.showSuccess(
        context,
        'Your profile changes have been saved.',
        title: 'Profile Updated',
      );

      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) {
          Navigator.of(context).pop(updatedProf);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      AppToast.showError(
        context,
        'Failed to update profile: $e',
        title: 'Update Error',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveAvatarUrl = _imageRemoved ? null : _currentAvatarUrl;
    final roleName = widget.profile?.role.name.toUpperCase() ?? 'CUSTOMER';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        titleSpacing: 0,
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 12),

                            // --- Profile Avatar & Image Attachment Section ---
                            Center(
                              child: Column(
                                children: [
                                  UserAvatar(
                                    imageFile: _pickedImageFile,
                                    avatarUrl: effectiveAvatarUrl,
                                    name: _nameController.text.isNotEmpty
                                        ? _nameController.text
                                        : (widget.profile?.fullName ?? 'User'),
                                    size: 92,
                                    isEditable: true,
                                    onTap: _showImagePickerSheet,
                                    onEditTap: _showImagePickerSheet,
                                  ),
                                  const SizedBox(height: 10),
                                  TextButton.icon(
                                    onPressed: _showImagePickerSheet,
                                    icon: const Icon(Icons.photo_camera_outlined, size: 16, color: AppColors.primary),
                                    label: Text(
                                      (_pickedImageFile != null || effectiveAvatarUrl != null)
                                          ? 'Change Photo'
                                          : 'Add Profile Photo',
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    style: TextButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // --- Role Chip Indicator ---
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF27B50),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      roleName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Active account role for this session',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // --- Full Name Field ---
                            _buildFieldLabel('Full Name'),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: _nameController,
                              hint: 'Enter your full name',
                              icon: Icons.person_outline_rounded,
                              keyboardType: TextInputType.name,
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Full name cannot be empty';
                                }
                                if (val.trim().length < 2) {
                                  return 'Name must be at least 2 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            // --- Email Address Field ---
                            _buildFieldLabel('Email Address'),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: _emailController,
                              hint: 'Enter your email address',
                              icon: Icons.mail_outline_rounded,
                              keyboardType: TextInputType.emailAddress,
                              validator: AuthService.validateEmail,
                            ),
                            const SizedBox(height: 20),

                            // --- Phone Number Field ---
                            _buildFieldLabel('Phone Number'),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: _phoneController,
                              hint: '+94 77 123 4567',
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // --- Save Changes Button ---
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Save Changes',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        style: const TextStyle(
          fontSize: 14,
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
    );
  }
}
