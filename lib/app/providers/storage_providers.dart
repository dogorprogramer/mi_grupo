import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/preferences_service.dart';
import '../../core/storage/secure_storage_service.dart';

final secureStorageServiceProvider = Provider<SecureStorageService>(
  (ref) => const SecureStorageService(),
);

final preferencesServiceProvider = Provider<PreferencesService>(
  (ref) => throw UnimplementedError(
    'preferencesServiceProvider debe ser sobrescrito en main()',
  ),
);
