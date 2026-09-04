import '../../../core/network/api_client.dart';
import '../domain/flash.dart';

class FlashRepository {
  FlashRepository(this._api);
  final ApiClient _api;

  Future<FlashFeed> nearby({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
    int limit = 30,
    String? cursor,
    String? since,
  }) async {
    final query = <String, String>{
      'lat': latitude.toString(),
      'lng': longitude.toString(),
      'radius': radiusKm.toString(),
      'limit': limit.toString(),
      if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
      if (since != null && since.isNotEmpty) 'since': since,
    };

    final path = Uri(path: '/flashes', queryParameters: query).toString();
    final data = await _api.get(path);
    final raw = data['flashes'];

    final items = raw is List
        ? raw.whereType<Map>().map(
            (item) => Flash.fromJson(Map<String, dynamic>.from(item)),
          )
        : const <Flash>[];

    return FlashFeed(
      flashes: List<Flash>.unmodifiable(items),
      nextCursor: data['next_cursor']?.toString(),
    );
  }

  Future<Flash> getById(int id) async {
    final data = await _api.get('/flashes/$id');
    final raw = data['flash'] is Map ? data['flash'] : data;
    return Flash.fromJson(Map<String, dynamic>.from(raw as Map));
  }

  Future<Flash> create({
    required String category,
    required String description,
    required double latitude,
    required double longitude,
    String? areaName,
    String source = 'user',
  }) async {
    final data = await _api.post('/flashes', {
      'category': category,
      'source': source,
      'description': description,
      'area_name': areaName,
      'lat': latitude,
      'lng': longitude,
    });
    final raw = data['flash'] is Map ? data['flash'] : data;
    return Flash.fromJson(Map<String, dynamic>.from(raw as Map));
  }
}

class FlashFeed {
  const FlashFeed({required this.flashes, this.nextCursor});
  final List<Flash> flashes;
  final String? nextCursor;
}
