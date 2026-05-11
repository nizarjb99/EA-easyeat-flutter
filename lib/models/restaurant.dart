// lib/models/restaurant.dart

// Sub-models for Restaurant
class TimetableSlot {
  final String open; // "HH:MM"
  final String close; // "HH:MM"

  TimetableSlot({required this.open, required this.close});

  factory TimetableSlot.fromJson(Map<String, dynamic> json) {
    return TimetableSlot(
      open: json['open'] as String? ?? '',
      close: json['close'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'open': open,
      'close': close,
    };
  }
}

class Timetable {
  final List<TimetableSlot>? monday;
  final List<TimetableSlot>? tuesday;
  final List<TimetableSlot>? wednesday;
  final List<TimetableSlot>? thursday;
  final List<TimetableSlot>? friday;
  final List<TimetableSlot>? saturday;
  final List<TimetableSlot>? sunday;

  Timetable({
    this.monday,
    this.tuesday,
    this.wednesday,
    this.thursday,
    this.friday,
    this.saturday,
    this.sunday,
  });

  factory Timetable.fromJson(Map<String, dynamic> json) {
    return Timetable(
      monday: (json['monday'] as List<dynamic>?)
          ?.map((e) => TimetableSlot.fromJson(e as Map<String, dynamic>))
          .toList(),
      tuesday: (json['tuesday'] as List<dynamic>?)
          ?.map((e) => TimetableSlot.fromJson(e as Map<String, dynamic>))
          .toList(),
      wednesday: (json['wednesday'] as List<dynamic>?)
          ?.map((e) => TimetableSlot.fromJson(e as Map<String, dynamic>))
          .toList(),
      thursday: (json['thursday'] as List<dynamic>?)
          ?.map((e) => TimetableSlot.fromJson(e as Map<String, dynamic>))
          .toList(),
      friday: (json['friday'] as List<dynamic>?)
          ?.map((e) => TimetableSlot.fromJson(e as Map<String, dynamic>))
          .toList(),
      saturday: (json['saturday'] as List<dynamic>?)
          ?.map((e) => TimetableSlot.fromJson(e as Map<String, dynamic>))
          .toList(),
      sunday: (json['sunday'] as List<dynamic>?)
          ?.map((e) => TimetableSlot.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (monday != null) 'monday': monday!.map((e) => e.toJson()).toList(),
      if (tuesday != null) 'tuesday': tuesday!.map((e) => e.toJson()).toList(),
      if (wednesday != null) 'wednesday': wednesday!.map((e) => e.toJson()).toList(),
      if (thursday != null) 'thursday': thursday!.map((e) => e.toJson()).toList(),
      if (friday != null) 'friday': friday!.map((e) => e.toJson()).toList(),
      if (saturday != null) 'saturday': saturday!.map((e) => e.toJson()).toList(),
      if (sunday != null) 'sunday': sunday!.map((e) => e.toJson()).toList(),
    };
  }
}

class GeoPoint {
  final String type; // "Point"
  final List<double> coordinates; // [longitude, latitude]

  GeoPoint({required this.type, required this.coordinates});

  factory GeoPoint.fromJson(Map<String, dynamic> json) {
    return GeoPoint(
      type: json['type']?.toString() ?? 'Point',
      coordinates: (json['coordinates'] as List?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          const [0.0, 0.0],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'coordinates': coordinates,
    };
  }
}

class RestaurantLocation {
  final String city;
  final String? address;
  final String? googlePlaceId;
  final GeoPoint coordinates;

  RestaurantLocation({
    required this.city,
    this.address,
    this.googlePlaceId,
    required this.coordinates,
  });

  factory RestaurantLocation.fromJson(Map<String, dynamic> json) {
    final rawCoordinates = json['coordinates'];
    return RestaurantLocation(
      city: json['city']?.toString() ?? '',
      address: json['address']?.toString(),
      googlePlaceId: json['googlePlaceId']?.toString(),
      coordinates: rawCoordinates is Map<String, dynamic>
          ? GeoPoint.fromJson(rawCoordinates)
          : GeoPoint(type: 'Point', coordinates: [0.0, 0.0]),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'city': city,
      if (address != null) 'address': address,
      if (googlePlaceId != null) 'googlePlaceId': googlePlaceId,
      'coordinates': coordinates.toJson(),
    };
  }
}

class RestaurantContact {
  final String? phone;
  final String? email;

  RestaurantContact({this.phone, this.email});

  factory RestaurantContact.fromJson(Map<String, dynamic> json) {
    return RestaurantContact(
      phone: json['phone'] as String?,
      email: json['email'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
    };
  }
}

class RestaurantProfile {
  final String name;
  final String description;
  final double globalRating;
  final List<String> category; // RestaurantCategory[]
  final Timetable? timetable;
  final List<String>? image;
  final RestaurantContact? contact;
  final RestaurantLocation location;

  RestaurantProfile({
    required this.name,
    required this.description,
    this.globalRating = 0.0,
    required this.category,
    this.timetable,
    this.image,
    this.contact,
    required this.location,
  });

  factory RestaurantProfile.fromJson(Map<String, dynamic> json) {
    final rawLocation = json['location'];
    final location = rawLocation is Map<String, dynamic>
        ? RestaurantLocation.fromJson(rawLocation)
        : RestaurantLocation(
            city: '',
            coordinates: GeoPoint(type: 'Point', coordinates: [0.0, 0.0]),
          );

    return RestaurantProfile(
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      globalRating: (json['globalRating'] as num?)?.toDouble() ?? 0.0,
      category: (json['category'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      timetable: json['timetable'] is Map<String, dynamic>
          ? Timetable.fromJson(json['timetable'] as Map<String, dynamic>)
          : null,
      image: (json['image'] as List?)?.map((e) => e.toString()).toList(),
      contact: json['contact'] is Map<String, dynamic>
          ? RestaurantContact.fromJson(json['contact'] as Map<String, dynamic>)
          : null,
      location: location,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'globalRating': globalRating,
      'category': category,
      if (timetable != null) 'timetable': timetable!.toJson(),
      if (image != null) 'image': image,
      if (contact != null) 'contact': contact!.toJson(),
      'location': location.toJson(),
    };
  }
}

// Main Restaurant Model
class Restaurant {
  final String id;
  final RestaurantProfile profile;
  final List<String>? employees; // List of ObjectIds as Strings
  final List<String>? dishes;
  final String? statistics; // Single ObjectId as String
  final List<String>? rewards;
  final List<String>? badges;
  final List<String>? visits;
  final List<String>? reviews;
  final DateTime? deletedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Restaurant({
    required this.id,
    required this.profile,
    this.employees,
    this.dishes,
    this.statistics,
    this.rewards,
    this.badges,
    this.visits,
    this.reviews,
    this.deletedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      profile: RestaurantProfile.fromJson(json['profile'] as Map<String, dynamic>),
      employees: (json['employees'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      dishes: (json['dishes'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      statistics: json['statistics']?.toString(),
      rewards: (json['rewards'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      badges: (json['badges'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      visits: (json['visits'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      reviews: (json['reviews'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      deletedAt: json['deletedAt'] != null ? DateTime.parse(json['deletedAt']) : null,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'profile': profile.toJson(),
      if (employees != null) 'employees': employees,
      if (dishes != null) 'dishes': dishes,
      if (statistics != null) 'statistics': statistics,
      if (rewards != null) 'rewards': rewards,
      if (badges != null) 'badges': badges,
      if (visits != null) 'visits': visits,
      if (reviews != null) 'reviews': reviews,
      if (deletedAt != null) 'deletedAt': deletedAt!.toIso8601String(),
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }
}
