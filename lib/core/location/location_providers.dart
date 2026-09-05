import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'location_service.dart';

final locationServiceProvider = Provider<LocationService>(
  (ref) => LocationService(),
);

final currentLocationProvider = FutureProvider<AppLocation>(
  (ref) => ref.watch(locationServiceProvider).getCurrentLocation(),
);
