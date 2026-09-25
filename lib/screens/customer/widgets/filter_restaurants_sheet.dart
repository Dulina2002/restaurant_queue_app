import 'package:flutter/material.dart';
import '../../../shared/theme/app_colors.dart';

class FilterRestaurantsBottomSheet extends StatefulWidget {
  final Set<String>? initialCuisines;
  final double? initialMaxDistance;
  final String? initialRating;
  final String? initialAvailability;
  final int? initialPartySize;
  final Function(Map<String, dynamic> filters)? onApply;

  const FilterRestaurantsBottomSheet({
    super.key,
    this.initialCuisines,
    this.initialMaxDistance,
    this.initialRating,
    this.initialAvailability,
    this.initialPartySize,
    this.onApply,
  });

  @override
  State<FilterRestaurantsBottomSheet> createState() =>
      _FilterRestaurantsBottomSheetState();
}

class _FilterRestaurantsBottomSheetState
    extends State<FilterRestaurantsBottomSheet> {
  late Set<String> _selectedCuisines;
  late double _maxDistance;
  late String _selectedRating;
  late String _selectedAvailability;
  late int _partySize;

  final List<String> _cuisines = [
    'Sri Lankan',
    'Italian',
    'Chinese',
    'Indian',
    'Japanese',
    'Fast Food',
    'Café',
  ];

  final List<String> _ratingOptions = [
    '4.5+ ★',
    '4.0+ ★',
    '3.5+ ★',
  ];

  final List<String> _availabilityOptions = [
    'Available Now',
    'Available Today',
  ];

  @override
  void initState() {
    super.initState();
    _selectedCuisines = widget.initialCuisines != null
        ? Set.from(widget.initialCuisines!)
        : {'Italian'};
    _maxDistance = widget.initialMaxDistance ?? 10.0;
    _selectedRating = widget.initialRating ?? '4.5+ ★';
    _selectedAvailability = widget.initialAvailability ?? 'Available Today';
    _partySize = widget.initialPartySize ?? 2;
  }

  void _resetFilters() {
    setState(() {
      _selectedCuisines = {'Italian'};
      _maxDistance = 10.0;
      _selectedRating = '4.5+ ★';
      _selectedAvailability = 'Available Today';
      _partySize = 2;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle Bar
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header: Title + Reset
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filter Restaurants',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              GestureDetector(
                onTap: _resetFilters,
                child: const Text(
                  'Reset Filters',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFE57373),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 1. Cuisine Section
          const Text(
            'Cuisine',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 10,
            children: _cuisines.map((cuisine) {
              final isSelected = _selectedCuisines.contains(cuisine);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedCuisines.remove(cuisine);
                    } else {
                      _selectedCuisines.add(cuisine);
                    }
                  });
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF0D3B2E) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF0D3B2E)
                          : AppColors.border,
                    ),
                  ),
                  child: Text(
                    cuisine,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 22),

          // 2. Max Distance Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Max Distance',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${_maxDistance.round()} km',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D3B2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF0D3B2E),
              inactiveTrackColor: const Color(0xFFE2E8F0),
              thumbColor: const Color(0xFF0D3B2E),
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
            ),
            child: Slider(
              value: _maxDistance,
              min: 1,
              max: 30,
              divisions: 29,
              onChanged: (val) {
                setState(() => _maxDistance = val);
              },
            ),
          ),
          const SizedBox(height: 14),

          // 3. Rating Section
          const Text(
            'Rating',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: _ratingOptions.map((rating) {
              final isSelected = _selectedRating == rating;
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: GestureDetector(
                  onTap: () {
                    setState(() => _selectedRating = rating);
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color:
                          isSelected ? const Color(0xFF0D3B2E) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF0D3B2E)
                            : AppColors.border,
                      ),
                    ),
                    child: Text(
                      rating,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 22),

          // 4. Availability Section
          const Text(
            'Availability',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: _availabilityOptions.map((avail) {
              final isSelected = _selectedAvailability == avail;
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: GestureDetector(
                  onTap: () {
                    setState(() => _selectedAvailability = avail);
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color:
                          isSelected ? const Color(0xFF0D3B2E) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF0D3B2E)
                            : AppColors.border,
                      ),
                    ),
                    child: Text(
                      avail,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 22),

          // 5. Party Size Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Party Size',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (_partySize > 1) {
                        setState(() => _partySize--);
                      }
                    },
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.remove,
                        size: 18,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    '$_partySize',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  GestureDetector(
                    onTap: () {
                      setState(() => _partySize++);
                    },
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8F8F0),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.add,
                        size: 18,
                        color: Color(0xFF0D3B2E),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 6. Apply Filters Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                if (widget.onApply != null) {
                  widget.onApply!({
                    'cuisines': _selectedCuisines,
                    'maxDistance': _maxDistance,
                    'rating': _selectedRating,
                    'availability': _selectedAvailability,
                    'partySize': _partySize,
                  });
                }
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D3B2E),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Apply Filters',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
