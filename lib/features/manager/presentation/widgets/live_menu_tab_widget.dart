import 'package:flutter/material.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../services/firestore_service.dart';
import '../../data/models/live_menu_dish_model.dart';

class LiveMenuTabWidget extends StatefulWidget {
  const LiveMenuTabWidget({super.key});

  @override
  State<LiveMenuTabWidget> createState() => _LiveMenuTabWidgetState();
}

class _LiveMenuTabWidgetState extends State<LiveMenuTabWidget> {
  final FirestoreService _firestoreService = FirestoreService();
  String _selectedRestaurantFilter = 'All';

  final List<String> _restaurantOptions = [
    'All',
    'Ocean Bistro',
    'The Mango Tree',
    'Nihonbashi',
  ];

  final List<String> _categoryOptions = [
    'Starters',
    'Mains',
    'Desserts',
    'Beverages',
  ];

  void _toggleAvailability(String id, bool val) async {
    try {
      await _firestoreService.toggleDishAvailability(id, val);
      if (!mounted) return;
      AppToast.showSuccess(
        context,
        val ? 'Dish marked AVAILABLE in Firestore' : 'Dish marked 86\'D in Firestore',
        title: 'Menu Status Updated',
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      if (!mounted) return;
      AppToast.showError(
        context,
        'Error updating status: $e',
        title: 'Error',
      );
    }
  }

  void _addDish(LiveMenuDish newDish) async {
    try {
      await _firestoreService.addDish(newDish);
      if (!mounted) return;
      AppToast.showSuccess(
        context,
        'Dish added to Firestore Live Menu',
        title: 'Dish Added',
      );
    } catch (e) {
      if (!mounted) return;
      AppToast.showError(
        context,
        'Error adding dish: $e',
        title: 'Error',
      );
    }
  }

  void _editDish(LiveMenuDish updatedDish) async {
    try {
      await _firestoreService.updateDish(updatedDish);
      if (!mounted) return;
      AppToast.showSuccess(
        context,
        'Dish updated in Firestore Live Menu',
        title: 'Dish Updated',
      );
    } catch (e) {
      if (!mounted) return;
      AppToast.showError(
        context,
        'Error updating dish: $e',
        title: 'Error',
      );
    }
  }

  void _deleteDish(String id) async {
    try {
      await _firestoreService.deleteDish(id);
      if (!mounted) return;
      AppToast.showSuccess(
        context,
        'Dish removed from Firestore',
        title: 'Dish Removed',
      );
    } catch (e) {
      if (!mounted) return;
      AppToast.showError(
        context,
        'Error deleting dish: $e',
        title: 'Error',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<LiveMenuDish>>(
      stream: _firestoreService.streamLiveMenu(restaurantId: _selectedRestaurantFilter),
      builder: (context, snapshot) {
        final dishes = snapshot.data ?? LiveMenuDish.mockList();
        final isLoading = snapshot.connectionState == ConnectionState.waiting;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Live Sync Banner Container ---
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFC8E6C9)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Icon(
                    Icons.sync,
                    color: AppColors.primary,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Live Sync Connected: Menu changes and 86\'d status update customer-facing reservation pre-orders and dining menus in real-time.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // --- Header Section: Title & + Add Dish Button ---
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Live Menu & 86 Item Management',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Instant toggle availability, edit price, or add specials.',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _showAddOrEditDishDialog(),
                  icon: const Icon(Icons.add, size: 16, color: Colors.white),
                  label: const Text(
                    'Add Dish',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // --- Restaurant Filter Pills ---
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _restaurantOptions.map((rest) {
                  final isSelected = _selectedRestaurantFilter == rest;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedRestaurantFilter = rest),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: isSelected ? null : Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        rest,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // --- Dish Cards List ---
            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (dishes.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Center(
                  child: Text(
                    'No dishes found in menu. Tap + Add Dish to create one.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: dishes.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final dish = dishes[index];
                  return _buildDishCard(dish);
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildDishCard(LiveMenuDish dish) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Title, Status Badge, Toggle, Edit, Delete
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        dish.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildAvailabilityBadge(dish.isAvailable),
                  ],
                ),
              ),
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: dish.isAvailable,
                  activeColor: AppColors.primary,
                  activeTrackColor: const Color(0xFFC8E6C9),
                  onChanged: (val) => _toggleAvailability(dish.id, val),
                ),
              ),
              IconButton(
                onPressed: () => _showAddOrEditDishDialog(dish: dish),
                icon: const Icon(Icons.edit_outlined, size: 18),
                color: const Color(0xFF64748B),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(4),
                tooltip: 'Edit Dish',
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: () => _confirmDeleteDish(dish),
                icon: const Icon(Icons.delete_outline, size: 18),
                color: const Color(0xFFEF4444),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(4),
                tooltip: 'Delete Dish',
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Subtitle Line: Category • Rs. Price • Restaurant
          Text(
            '${dish.category}  -  Rs. ${dish.price.toInt()}  ${dish.restaurant}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),

          // Description Line
          Text(
            dish.description,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityBadge(bool isAvailable) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isAvailable ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isAvailable ? 'AVAILABLE' : '86\'D',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: isAvailable ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  void _showAddOrEditDishDialog({LiveMenuDish? dish}) {
    final isEditing = dish != null;
    String selectedRestaurant = isEditing ? dish.restaurant : 'Ocean Bistro';
    String selectedCategory = isEditing ? dish.category : 'Mains';

    final nameController = TextEditingController(text: isEditing ? dish.name : '');
    final priceController = TextEditingController(text: isEditing ? dish.price.toInt().toString() : '');
    final descController = TextEditingController(text: isEditing ? dish.description : '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isEditing ? 'Edit Live Menu Dish' : 'Add Live Menu Dish',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Restaurant Selector Pills
                    const Text(
                      'Restaurant',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: _restaurantOptions.where((r) => r != 'All').map((rest) {
                        final isSel = selectedRestaurant == rest;
                        return GestureDetector(
                          onTap: () => setSheetState(() => selectedRestaurant = rest),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSel ? AppColors.primary : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              rest,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                color: isSel ? Colors.white : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Dish Name Field
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Dish Name',
                        hintText: 'e.g. Garlic Butter Prawns',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Category Selector Pills
                    const Text(
                      'Category',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: _categoryOptions.map((cat) {
                        final isSel = selectedCategory == cat;
                        return GestureDetector(
                          onTap: () => setSheetState(() => selectedCategory = cat),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSel ? AppColors.primary : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              cat,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                color: isSel ? Colors.white : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Price (Rs.) Field
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Price (Rs.)',
                        hintText: '2500',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Description Field
                    TextField(
                      controller: descController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Description / Ingredients',
                        hintText: 'Brief note for diners and kitchen',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () {
                            final name = nameController.text.trim();
                            final price = double.tryParse(priceController.text.trim()) ?? 0;
                            final desc = descController.text.trim();

                            if (name.isNotEmpty && price > 0) {
                              if (isEditing) {
                                _editDish(dish.copyWith(
                                  name: name,
                                  restaurant: selectedRestaurant,
                                  category: selectedCategory,
                                  price: price,
                                  description: desc,
                                ));
                              } else {
                                _addDish(LiveMenuDish(
                                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                                  restaurantId: 'ocean_bistro',
                                  name: name,
                                  restaurant: selectedRestaurant,
                                  category: selectedCategory,
                                  price: price,
                                  description: desc,
                                  isAvailable: true,
                                ));
                              }
                              Navigator.pop(context);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            isEditing ? 'Save Changes' : 'Add Dish',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDeleteDish(LiveMenuDish dish) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Dish'),
          content: Text('Are you sure you want to delete "${dish.name}" from Live Menu?'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _deleteDish(dish.id);
                Navigator.pop(context);
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }
}
