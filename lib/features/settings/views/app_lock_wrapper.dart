import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_tracker/features/settings/controllers/app_lock_controller.dart';
import 'package:expense_tracker/features/settings/services/local_auth_service.dart';

class AppLockWrapper extends ConsumerStatefulWidget {
  final Widget child;

  const AppLockWrapper({super.key, required this.child});

  @override
  ConsumerState<AppLockWrapper> createState() => _AppLockWrapperState();
}

class _AppLockWrapperState extends ConsumerState<AppLockWrapper> with WidgetsBindingObserver {
  bool _isLocked = false;
  bool _isAuthenticating = false;
  bool _wasPaused = false;

  // Tracks if we've done the initial cold-start check
  bool _initialCheckDone = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // User pressed home button or switched apps
      _wasPaused = true;
    } else if (state == AppLifecycleState.resumed && _wasPaused) {
      // User is back from background - this only fires after a real "paused"
      _wasPaused = false;

      final isLockEnabled = ref.read(appLockProvider);
      if (isLockEnabled && !_isLocked && !_isAuthenticating) {
        setState(() => _isLocked = true);
        _authenticate();
      }
    }
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;

    setState(() => _isAuthenticating = true);

    final authService = ref.read(localAuthServiceProvider);
    bool authenticated = await authService.authenticate();

    if (mounted) {
      setState(() {
        _isAuthenticating = false;
        if (authenticated) {
          _isLocked = false;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for SharedPreferences finishing loading on cold start.
    // When the provider goes from false (default) → true (loaded from disk),
    // we know the user had lock enabled, so we lock immediately.
    ref.listen<bool>(appLockProvider, (previous, current) {
      if (!_initialCheckDone && current && !(previous ?? false)) {
        // SharedPreferences just loaded and lock is enabled → cold start lock
        _initialCheckDone = true;
        setState(() => _isLocked = true);
        _authenticate();
      }
    });

    // Also read the current value so we can mark initial check as done 
    // even if lock is disabled (prevents stale flag)
    final currentLockValue = ref.watch(appLockProvider);
    final prefsLoaded = ref.watch(sharedPreferencesProvider).hasValue;
    if (!_initialCheckDone && prefsLoaded) {
      _initialCheckDone = true;
      // If lock is enabled on cold start and we haven't locked yet
      if (currentLockValue && !_isLocked && !_isAuthenticating) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_isLocked && !_isAuthenticating) {
            setState(() => _isLocked = true);
            _authenticate();
          }
        });
      }
    }

    return Stack(
      children: [
        widget.child,

        if (_isLocked)
          Positioned.fill(
            child: Material(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.lock_outline,
                    size: 80,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'App Locked',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _isAuthenticating ? null : _authenticate,
                    icon: _isAuthenticating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.fingerprint),
                    label: const Text('Unlock'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
