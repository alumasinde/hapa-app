import '../../../core/network/api_client.dart';
class EngagementRepository { EngagementRepository(this._api); final ApiClient _api;
 Future<void> markHelpful(int id)=>_api.post('/flashes/$id/helpful',{});
 Future<void> removeHelpful(int id)=>_api.post('/flashes/$id/helpful/remove',{});
 Future<void> recordShare(int id)=>_api.post('/flashes/$id/share',{});
}
