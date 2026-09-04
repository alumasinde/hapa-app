import '../../../core/network/api_client.dart';
import '../domain/flash.dart';
class FlashRepository { FlashRepository(this._api); final ApiClient _api;
 Future<List<Flash>> nearby({double latitude=-1.286389,double longitude=36.817223,double radiusKm=10}) async {final data=await _api.get('/flashes?latitude=$latitude&longitude=$longitude&radius_km=$radiusKm');final raw=data['flashes']??data['data']??[];return (raw as List).whereType<Map>().map((e)=>Flash.fromJson(Map<String,dynamic>.from(e))).toList();}
 Future<Flash> getById(int id) async {final data=await _api.get('/flashes/$id');final raw=data['flash'] is Map?data['flash']:data;return Flash.fromJson(Map<String,dynamic>.from(raw as Map));}
}
