import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../categories/presentation/category_providers.dart';
import '../data/flash_repository.dart';

final flashRepositoryProvider = Provider<FlashRepository>(
  (ref) => FlashRepository(ref.watch(apiClientProvider)),
);

final nearbyFlashesProvider = FutureProvider<FlashFeed>((ref) {
  return ref.watch(flashRepositoryProvider).nearby(
        latitude: -1.286389,
        longitude: 36.817223,
        radiusKm: 10,
      );
});
