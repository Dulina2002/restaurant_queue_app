class RestaurantModel {
  final String id;
  final String name;
  final String cuisine;
  final String tag;
  final String location;
  final double rating;
  final int reviewsCount;
  final bool isActive;
  final bool isQueueAvailable;
  final String estWait;
  final int waitlistCount;
  final String? imageUrl;
  final DateTime? createdAt;

  const RestaurantModel({
    required this.id,
    required this.name,
    required this.cuisine,
    required this.tag,
    required this.location,
    required this.rating,
    required this.reviewsCount,
    this.isActive = true,
    this.isQueueAvailable = true,
    required this.estWait,
    required this.waitlistCount,
    this.imageUrl,
    this.createdAt,
  });

  factory RestaurantModel.fromJson(Map<String, dynamic> json) {
    return RestaurantModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      cuisine: json['cuisine'] as String? ?? 'General',
      tag: json['tag'] as String? ?? '',
      location: json['location'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 4.5,
      reviewsCount: (json['reviews_count'] as num?)?.toInt() ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      isQueueAvailable: json['is_queue_available'] as bool? ?? true,
      estWait: json['est_wait'] as String? ?? 'Direct Seating',
      waitlistCount: (json['waitlist_count'] as num?)?.toInt() ?? 0,
      imageUrl: json['image_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  factory RestaurantModel.fromMap(Map<String, dynamic> map) => RestaurantModel.fromJson(map);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'cuisine': cuisine,
      'tag': tag,
      'location': location,
      'rating': rating,
      'reviews_count': reviewsCount,
      'is_active': isActive,
      'is_queue_available': isQueueAvailable,
      'est_wait': estWait,
      'waitlist_count': waitlistCount,
      if (imageUrl != null) 'image_url': imageUrl,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  Map<String, dynamic> toMap() => toJson();

  RestaurantModel copyWith({
    String? id,
    String? name,
    String? cuisine,
    String? tag,
    String? location,
    double? rating,
    int? reviewsCount,
    bool? isActive,
    bool? isQueueAvailable,
    String? estWait,
    int? waitlistCount,
    String? imageUrl,
    DateTime? createdAt,
  }) {
    return RestaurantModel(
      id: id ?? this.id,
      name: name ?? this.name,
      cuisine: cuisine ?? this.cuisine,
      tag: tag ?? this.tag,
      location: location ?? this.location,
      rating: rating ?? this.rating,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      isActive: isActive ?? this.isActive,
      isQueueAvailable: isQueueAvailable ?? this.isQueueAvailable,
      estWait: estWait ?? this.estWait,
      waitlistCount: waitlistCount ?? this.waitlistCount,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
