import '../../../core/network/api_client.dart';

class EngagementResult {
  const EngagementResult({required this.engagement});
  final Map<String, dynamic> engagement;
}

class EngagementRepository {
  EngagementRepository(this._api);
  final ApiClient _api;

  Future<EngagementResult> markHelpful(int id) async {
    final data = await _api.post('/flashes/$id/helpful', {});
    return EngagementResult(
      engagement: _engagementFrom(data),
    );
  }

  Future<EngagementResult> removeHelpful(int id) async {
    final data = await _api.delete('/flashes/$id/helpful');
    return EngagementResult(
      engagement: _engagementFrom(data),
    );
  }

  Future<EngagementResult> recordShare(int id) async {
    final data = await _api.post('/flashes/$id/share', {});
    return EngagementResult(
      engagement: _engagementFrom(data),
    );
  }

  Map<String, dynamic> _engagementFrom(Map<String, dynamic> data) {
    final value = data['engagement'];
    if (value is Map) return Map<String, dynamic>.from(value);
    return const {};
  }
}
