import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/location/location_providers.dart';
import '../../../core/network/api_client.dart';
import '../data/flash_repository.dart';

final flashRepositoryProvider = Provider<FlashRepository>(
  (ref) => FlashRepository(ref.watch(apiClientProvider)),
);

final nearbyFlashesProvider = FutureProvider<FlashFeed>((ref) async {
  final location = await ref.watch(currentLocationProvider.future);
  return ref.watch(flashRepositoryProvider).nearby(
        latitude: location.latitude,
        longitude: location.longitude,
        radiusKm: 10,
      );
});
