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

  factory RestaurantModel.fromFirestore(dynamic doc) {
    final Map<String, dynamic> data = doc is Map<String, dynamic>
        ? doc
        : (doc is Map ? Map<String, dynamic>.from(doc) : {});
    return RestaurantModel(
      id: data['id'] as String? ?? '',
      name: data['name'] as String? ?? '',
      cuisine: data['cuisine'] as String? ?? 'General',
      tag: data['tag'] as String? ?? '',
      location: data['location'] as String? ?? '',
      rating: (data['rating'] as num?)?.toDouble() ?? 4.5,
      reviewsCount: (data['reviews_count'] as num?)?.toInt() ?? 0,
      isActive: data['is_active'] as bool? ?? true,
      isQueueAvailable: data['is_queue_available'] as bool? ?? true,
      estWait: data['est_wait'] as String? ?? 'Direct Seating',
      waitlistCount: (data['waitlist_count'] as num?)?.toInt() ?? 0,
      imageUrl: data['image_url'] as String?,
      createdAt: data['created_at'] != null ? DateTime.tryParse(data['created_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toFirestore() {
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
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
