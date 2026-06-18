// lib/models/review.dart

class ReviewRatings {
  final int? foodQuality;
  final int? staffService;
  final int? cleanliness;
  final int? environment;

  ReviewRatings({
    this.foodQuality,
    this.staffService,
    this.cleanliness,
    this.environment,
  });

  factory ReviewRatings.fromJson(Map<String, dynamic> json) {
    return ReviewRatings(
      foodQuality: (json['foodQuality'] as num?)?.toInt(),
      staffService: (json['staffService'] as num?)?.toInt(),
      cleanliness: (json['cleanliness'] as num?)?.toInt(),
      environment: (json['environment'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (foodQuality != null) 'foodQuality': foodQuality,
      if (staffService != null) 'staffService': staffService,
      if (cleanliness != null) 'cleanliness': cleanliness,
      if (environment != null) 'environment': environment,
    };
  }
}

class Review {
  final String id;
  final String? employeeId;
  final String customerId;
  final String restaurantId;
  final DateTime date;
  final num globalRating;
  final List<String> images;
  final ReviewRatings? ratings;
  final String? comment;
  final int likes;
  final List<String> likedBy;
  final bool deleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Review({
    required this.id,
    this.employeeId,
    required this.customerId,
    required this.restaurantId,
    required this.date,
    required this.globalRating,
    required this.images,
    this.ratings,
    this.comment,
    this.likes = 0,
    required this.likedBy,
    this.deleted = false,
    this.createdAt,
    this.updatedAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      employeeId: json['employee_id']?.toString() ?? json['employeeId']?.toString(),
      customerId: (json['customer_id'] ?? json['customerId'] ?? '').toString(),
      restaurantId: (json['restaurant_id'] ?? json['restaurantId'] ?? '').toString(),
      date: json['date'] != null
          ? DateTime.tryParse(json['date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      globalRating: (json['globalRating'] as num?) ?? 0,
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      ratings: json['ratings'] != null
          ? ReviewRatings.fromJson(json['ratings'] as Map<String, dynamic>)
          : null,
      comment: json['comment']?.toString(),
      likes: (json['likes'] as num?)?.toInt() ?? 0,
      likedBy: (json['likedBy'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      deleted: json['deleted'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      if (employeeId != null) 'employee_id': employeeId,
      'customer_id': customerId,
      'restaurant_id': restaurantId,
      'date': date.toIso8601String(),
      'globalRating': globalRating,
      'images': images,
      if (ratings != null) 'ratings': ratings!.toJson(),
      if (comment != null) 'comment': comment,
      'likes': likes,
      'likedBy': likedBy,
      'deleted': deleted,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }
}
