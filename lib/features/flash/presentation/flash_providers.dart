import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../categories/presentation/category_providers.dart';
import '../data/flash_repository.dart';
import '../domain/flash.dart';

final flashRepositoryProvider = Provider<FlashRepository>(
  (ref) => FlashRepository(ref.watch(apiClientProvider)),
);

final nearbyFlashesProvider = FutureProvider<List<Flash>>(
  (ref) => ref.watch(flashRepositoryProvider).nearby(),
);
