class FlashLocation {
  const FlashLocation({
    this.latitude,
    this.longitude,
    this.label,
  });

  final double? latitude;
  final double? longitude;
  final String? label;

  factory FlashLocation.fromJson(Map<String, dynamic> json) {
    final areaName = json['area_name']?.toString();
    final label = areaName != null && areaName.trim().isNotEmpty
        ? areaName.trim()
        : json['label']?.toString();

    return FlashLocation(
      latitude: _asDouble(json['lat'] ?? json['latitude']),
      longitude: _asDouble(json['lng'] ?? json['longitude']),
      label: label,
    );
  }
}

class EngagementStatistics {
  const EngagementStatistics({
    this.helpful = 0,
    this.shares = 0,
    this.views = 0,
    this.markedHelpful = false,
  });

  final int helpful;
  final int shares;
  final int views;
  final bool markedHelpful;

  factory EngagementStatistics.fromJson(Map<String, dynamic> json) {
    return EngagementStatistics(
      helpful: _asInt(json['helpful_count'] ?? json['helpful']),
      shares: _asInt(json['share_count'] ?? json['shares']),
      views: _asInt(json['view_count'] ?? json['views']),
      markedHelpful: json['marked_helpful'] == true,
    );
  }

  EngagementStatistics copyWith({
    int? helpful,
    int? shares,
    int? views,
    bool? markedHelpful,
  }) {
    return EngagementStatistics(
      helpful: helpful ?? this.helpful,
      shares: shares ?? this.shares,
      views: views ?? this.views,
      markedHelpful: markedHelpful ?? this.markedHelpful,
    );
  }
}

class Flash {
  const Flash({
    required this.id,
    required this.title,
    this.description,
    this.category,
    this.mode,
    this.status,
    this.verificationState,
    this.location,
    this.createdAt,
    this.expiresAt,
    this.distanceKm,
    this.reporterName,
    this.confirmCount = 0,
    this.disputeCount = 0,
    this.engagement = const EngagementStatistics(),
  });

  final int id;
  final String title;
  final String? description;
  final String? category;
  final String? mode;
  final String? status;
  final String? verificationState;
  final FlashLocation? location;
  final DateTime? createdAt;
  final DateTime? expiresAt;
  final double? distanceKm;
  final String? reporterName;
  final int confirmCount;
  final int disputeCount;
  final EngagementStatistics engagement;

  factory Flash.fromJson(Map<String, dynamic> json) {
    final category = json['category'] is Map
        ? Map<String, dynamic>.from(json['category'] as Map)
        : <String, dynamic>{};
    final location = json['location'] is Map
        ? Map<String, dynamic>.from(json['location'] as Map)
        : <String, dynamic>{};
    final reporter = json['reporter'] is Map
        ? Map<String, dynamic>.from(json['reporter'] as Map)
        : <String, dynamic>{};
    final engagement = json['engagement'] is Map
        ? Map<String, dynamic>.from(json['engagement'] as Map)
        : <String, dynamic>{};

    final description = json['description']?.toString();
    final title = json['title']?.toString() ??
        (description != null && description.trim().isNotEmpty
            ? description.trim().split('\n').first
            : 'Community report');

    return Flash(
      id: _asInt(json['id']),
      title: title,
      description: description,
      category: category['name']?.toString() ?? json['category_name']?.toString(),
      mode: json['mode_name']?.toString() ?? json['mode']?.toString(),
      status: json['status']?.toString(),
      verificationState: json['verification_state']?.toString(),
      location: location.isEmpty ? null : FlashLocation.fromJson(location),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      expiresAt: DateTime.tryParse(json['expires_at']?.toString() ?? ''),
      distanceKm: _asDouble(json['distance_km']),
      reporterName: reporter['display_name']?.toString(),
      confirmCount: _asInt(json['confirm_count']),
      disputeCount: _asInt(json['dispute_count']),
      engagement: EngagementStatistics.fromJson(engagement),
    );
  }

  Flash copyWith({
    EngagementStatistics? engagement,
  }) {
    return Flash(
      id: id,
      title: title,
      description: description,
      category: category,
      mode: mode,
      status: status,
      verificationState: verificationState,
      location: location,
      createdAt: createdAt,
      expiresAt: expiresAt,
      distanceKm: distanceKm,
      reporterName: reporterName,
      confirmCount: confirmCount,
      disputeCount: disputeCount,
      engagement: engagement ?? this.engagement,
    );
  }
}

int _asInt(dynamic value) => value is num ? value.toInt() : int.tryParse('$value') ?? 0;

double? _asDouble(dynamic value) => value is num ? value.toDouble() : double.tryParse('$value');
