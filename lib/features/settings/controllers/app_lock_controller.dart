import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Provides SharedPreferences asynchronously
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

// Provides the AppLockController
final appLockProvider = StateNotifierProvider<AppLockController, bool>((ref) {
  final prefsAsync = ref.watch(sharedPreferencesProvider);
  
  // We start offline/false until prefs load
  final prefs = prefsAsync.valueOrNull;
  if (prefs == null) {
    return AppLockController(null);
  }
  return AppLockController(prefs);
});

class AppLockController extends StateNotifier<bool> {
  final SharedPreferences? _prefs;
  static const _appLockKey = 'is_app_lock_enabled';

  AppLockController(this._prefs) : super(_prefs?.getBool(_appLockKey) ?? false);

  Future<void> toggleLock(bool value) async {
    state = value;
    if (_prefs != null) {
      await _prefs.setBool(_appLockKey, value);
    }
  }
}
