import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../models/restaurant_model.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../services/restaurant_database_service.dart';
import '../../data/models/live_menu_dish_model.dart';

class LiveMenuTabWidget extends StatefulWidget {
  /// All restaurants available in the picker.
  final List<RestaurantModel> restaurants;

  /// Id of the restaurant selected in the dashboard header.
  final String selectedRestaurantId;

  const LiveMenuTabWidget({
    super.key,
    required this.restaurants,
    required this.selectedRestaurantId,
  });

  @override
  State<LiveMenuTabWidget> createState() => _LiveMenuTabWidgetState();
}

class _LiveMenuTabWidgetState extends State<LiveMenuTabWidget> {
  static const String _allFilter = 'All';

  final RestaurantDatabaseService _firestoreService = RestaurantDatabaseService();
  late String _selectedRestaurantFilter;
  late Stream<List<LiveMenuDish>> _menuStream;

  String _selectedCategoryFilter = 'All Categories';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isGridView = false;
  bool? _availabilityFilter;

  final List<String> _categoryFilterOptions = [
    'All Categories',
    'Starters',
    'Mains',
    'Desserts',
    'Beverages',
  ];

  final List<String> _categoryOptions = [
    'Starters',
    'Mains',
    'Desserts',
    'Beverages',
  ];

  RestaurantModel? _restaurantById(String id) {
    for (final r in widget.restaurants) {
      if (r.id == id) return r;
    }
    return null;
  }

  String _restaurantName(String id) => _restaurantById(id)?.name ?? id;

  List<String> get _filterIds => [_allFilter, widget.selectedRestaurantId];

  @override
  void initState() {
    super.initState();
    _selectedRestaurantFilter = widget.selectedRestaurantId;
    _menuStream = _firestoreService.streamLiveMenu(restaurantId: _selectedRestaurantFilter);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(LiveMenuTabWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedRestaurantId != oldWidget.selectedRestaurantId) {
      _setRestaurantFilter(widget.selectedRestaurantId);
    }
  }

  void _setRestaurantFilter(String id) {
    setState(() {
      _selectedRestaurantFilter = id;
      _menuStream = _firestoreService.streamLiveMenu(restaurantId: id);
    });
  }

  void _toggleAvailability(String id, bool val) async {
    try {
      await _firestoreService.toggleDishAvailability(id, val);
      if (!mounted) return;
      AppToast.showSuccess(
        context,
        val ? 'Dish marked AVAILABLE in database' : 'Dish marked 86\'D in database',
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
        'Dish added to Live Menu',
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
        'Dish updated in Live Menu',
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
        'Dish removed from database',
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
      stream: _menuStream,
      builder: (context, snapshot) {
        final rawDishes = snapshot.data ?? const <LiveMenuDish>[];

        final availCount = rawDishes.where((d) => d.isAvailable).length;
        final outOfStockCount = rawDishes.where((d) => !d.isAvailable).length;

        final dishes = rawDishes.where((d) {
          if (_selectedCategoryFilter != 'All Categories' && d.category.toLowerCase() != _selectedCategoryFilter.toLowerCase()) {
            return false;
          }
          if (_availabilityFilter != null && d.isAvailable != _availabilityFilter) {
            return false;
          }
          if (_searchQuery.isNotEmpty) {
            final q = _searchQuery.toLowerCase();
            final nameMatch = d.name.toLowerCase().contains(q);
            final descMatch = d.description.toLowerCase().contains(q);
            final catMatch = d.category.toLowerCase().contains(q);
            if (!nameMatch && !descMatch && !catMatch) return false;
          }
          return true;
        }).toList();
        final isLoading = snapshot.data == null && !snapshot.hasError;
        final loadError = snapshot.data == null ? snapshot.error : null;

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

            // --- Header Section: Title, View Switcher & + Add Dish Button ---
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
                Row(
                  children: [
                    // Layout Toggle Button (List vs Grid)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: IconButton(
                        tooltip: _isGridView ? 'Switch to List View' : 'Switch to Grid View',
                        icon: Icon(
                          _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        onPressed: () => setState(() => _isGridView = !_isGridView),
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
              ],
            ),
            const SizedBox(height: 14),

            // --- Live Menu Summary KPI Counter Chips ---
            Row(
              children: [
                _buildKpiChip(
                  label: 'Available',
                  count: availCount,
                  color: const Color(0xFF10B981),
                  isSelected: _availabilityFilter == true,
                  onTap: () {
                    setState(() {
                      _availabilityFilter = _availabilityFilter == true ? null : true;
                    });
                  },
                ),
                const SizedBox(width: 8),
                _buildKpiChip(
                  label: "86'd Out of Stock",
                  count: outOfStockCount,
                  color: const Color(0xFFEF4444),
                  isSelected: _availabilityFilter == false,
                  onTap: () {
                    setState(() {
                      _availabilityFilter = _availabilityFilter == false ? null : false;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),

            // --- Instant Search Bar ---
            TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              decoration: InputDecoration(
                hintText: 'Search dish name, description, or category...',
                hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textSecondary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16, color: AppColors.textMuted),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // --- Restaurant & Category Filter Pills ---
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ..._filterIds.map((restId) {
                    final isSelected = _selectedRestaurantFilter == restId;
                    final rest = restId == _allFilter ? 'All' : _restaurantName(restId);
                    return GestureDetector(
                      onTap: () => _setRestaurantFilter(restId),
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
                  }),
                  Container(
                    height: 20,
                    width: 1,
                    color: AppColors.border,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                  ),
                  ..._categoryFilterOptions.map((cat) {
                    final isSelected = _selectedCategoryFilter == cat;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategoryFilter = cat),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFE8F5E9) : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : Colors.transparent,
                          ),
                        ),
                        child: Text(
                          cat,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? AppColors.primary : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // --- Dish Cards (Grid or List View) ---
            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (loadError != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.cloud_off_rounded, color: AppColors.textMuted),
                    const SizedBox(height: 8),
                    Text(
                      'Could not load menu: $loadError',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                    TextButton(
                      onPressed: () => _setRestaurantFilter(_selectedRestaurantFilter),
                      child: const Text('Retry'),
                    ),
                  ],
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
                    'No dishes found for this selection. Tap + Add Dish to create one.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                ),
              )
            else if (_isGridView)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  mainAxisExtent: 160,
                ),
                itemCount: dishes.length,
                itemBuilder: (context, index) {
                  final dish = dishes[index];
                  return _buildGridDishCard(dish);
                },
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

  Widget _buildKpiChip({
    required String label,
    required int count,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              '$label: $count',
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? color : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridDishCard(LiveMenuDish dish) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: dish.isAvailable ? AppColors.border : const Color(0xFFEF4444).withValues(alpha: 0.35),
          width: dish.isAvailable ? 1 : 1.5,
        ),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  dish.category,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              _buildAvailabilityBadge(dish.isAvailable),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            dish.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            'Rs. ${dish.price.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          Text(
            dish.description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Transform.scale(
                scale: 0.7,
                child: Switch(
                  value: dish.isAvailable,
                  activeTrackColor: const Color(0xFFC8E6C9),
                  activeThumbColor: AppColors.primary,
                  onChanged: (val) => _toggleAvailability(dish.id, val),
                ),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => _showAddOrEditDishDialog(dish: dish),
                    child: const Icon(Icons.edit_outlined, size: 16, color: AppColors.textMuted),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _confirmDeleteDish(dish),
                    child: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
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
                  activeTrackColor: const Color(0xFFC8E6C9),
                  activeThumbColor: AppColors.primary,
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
            '${dish.category}  -  Rs. ${dish.price.toInt()}  ${dish.restaurant.isNotEmpty ? dish.restaurant : _restaurantName(dish.restaurantId)}',
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
    String selectedRestaurantId = isEditing
        ? dish.restaurantId
        : (_selectedRestaurantFilter == _allFilter ? widget.selectedRestaurantId : _selectedRestaurantFilter);
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

                    // Restaurant Selector Dropdown
                    const Text(
                      'Restaurant',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: widget.restaurants.any((r) => r.id == selectedRestaurantId)
                          ? selectedRestaurantId
                          : (widget.restaurants.isNotEmpty ? widget.restaurants.first.id : null),
                      isExpanded: true,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                        ),
                        prefixIcon: const Icon(Icons.storefront_rounded, color: AppColors.primary, size: 20),
                      ),
                      items: widget.restaurants.isEmpty
                          ? [
                              DropdownMenuItem<String>(
                                value: selectedRestaurantId,
                                child: Text(selectedRestaurantId),
                              ),
                            ]
                          : widget.restaurants.map((restaurant) {
                              return DropdownMenuItem<String>(
                                value: restaurant.id,
                                child: Text(
                                  restaurant.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              );
                            }).toList(),
                      onChanged: (newId) {
                        if (newId != null) {
                          setSheetState(() => selectedRestaurantId = newId);
                        }
                      },
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
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _categoryOptions.map((cat) {
                        final isSel = selectedCategory == cat;
                        return GestureDetector(
                          onTap: () => setSheetState(() => selectedCategory = cat),
                          child: Container(
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
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      ],
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
                            final priceText = priceController.text.trim();
                            final price = double.tryParse(priceText);
                            final desc = descController.text.trim();

                            if (name.isEmpty) {
                              AppToast.showError(
                                context,
                                'Please enter a dish name',
                                title: 'Missing Information',
                              );
                              return;
                            }

                            if (price == null || price <= 0) {
                              AppToast.showError(
                                context,
                                'Please enter a valid numeric price (e.g. 1500)',
                                title: 'Invalid Price',
                              );
                              return;
                            }

                            final restObj = _restaurantById(selectedRestaurantId);
                            final rName = restObj?.name ?? selectedRestaurantId;

                            if (isEditing) {
                              _editDish(dish.copyWith(
                                restaurantId: selectedRestaurantId,
                                name: name,
                                restaurant: rName,
                                category: selectedCategory,
                                price: price,
                                description: desc,
                              ));
                            } else {
                              _addDish(LiveMenuDish(
                                id: DateTime.now().millisecondsSinceEpoch.toString(),
                                restaurantId: selectedRestaurantId,
                                name: name,
                                restaurant: rName,
                                category: selectedCategory,
                                price: price,
                                description: desc,
                                isAvailable: true,
                              ));
                            }
                            Navigator.pop(context);
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
