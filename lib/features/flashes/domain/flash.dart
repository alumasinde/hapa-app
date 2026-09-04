import '../../auth/domain/user.dart';
import 'engagement_statistics.dart';
import 'flash_location.dart';

class FlashCategory {
  const FlashCategory({required this.key, required this.name, this.icon});
  final String key;
  final String name;
  final String? icon;

  factory FlashCategory.fromJson(Map<String, dynamic> json) => FlashCategory(
        key: json['key']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        icon: json['icon']?.toString(),
      );
}

class Flash {
  const Flash({
    required this.id,
    required this.category,
    required this.status,
    required this.location,
    required this.engagement,
    required this.createdAt,
    required this.expiresAt,
    this.description,
    this.distanceKm,
    this.reporter,
    this.verificationState,
    this.confirmCount = 0,
    this.disputeCount = 0,
  });

  final int id;
  final FlashCategory category;
  final String status;
  final String? description;
  final FlashLocation location;
  final double? distanceKm;
  final User? reporter;
  final String? verificationState;
  final int confirmCount;
  final int disputeCount;
  final EngagementStatistics engagement;
  final DateTime createdAt;
  final DateTime expiresAt;

  factory Flash.fromJson(Map<String, dynamic> json) {
    final categoryData = json['category'] is Map
        ? Map<String, dynamic>.from(json['category'] as Map)
        : <String, dynamic>{};
    final locationData = json['location'] is Map
        ? Map<String, dynamic>.from(json['location'] as Map)
        : <String, dynamic>{};
    final engagementData = json['engagement'] is Map
        ? Map<String, dynamic>.from(json['engagement'] as Map)
        : <String, dynamic>{};

    return Flash(
      id: (json['id'] as num?)?.toInt() ?? 0,
      category: FlashCategory.fromJson(categoryData),
      status: json['status']?.toString() ?? '',
      description: json['description']?.toString(),
      location: FlashLocation.fromJson(locationData),
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      reporter: json['reporter'] is Map
          ? User.fromJson(Map<String, dynamic>.from(json['reporter'] as Map))
          : null,
      verificationState: json['verification_state']?.toString(),
      confirmCount: (json['confirm_count'] as num?)?.toInt() ?? 0,
      disputeCount: (json['dispute_count'] as num?)?.toInt() ?? 0,
      engagement: EngagementStatistics.fromJson(engagementData),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      expiresAt: DateTime.tryParse(json['expires_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
