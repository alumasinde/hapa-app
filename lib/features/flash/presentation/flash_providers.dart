import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../data/flash_repository.dart';
import '../domain/flash.dart';
final flashRepositoryProvider=Provider((ref)=>FlashRepository(ref.watch(apiClientProvider)));
final nearbyFlashesProvider=FutureProvider<List<Flash>>((ref)=>ref.watch(flashRepositoryProvider).nearby());
