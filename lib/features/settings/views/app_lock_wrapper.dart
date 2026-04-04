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
  
  // To avoid spamming auth requests
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Check initial state on app start 
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLockAndAuthenticate();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkLockAndAuthenticate();
    } else if (state == AppLifecycleState.paused) {
      final isLockEnabled = ref.read(appLockProvider);
      if (isLockEnabled) {
         setState(() {
           _isLocked = true;
         });
      }
    }
  }

  Future<void> _checkLockAndAuthenticate() async {
    final isLockEnabled = ref.read(appLockProvider);
    if (!isLockEnabled) {
      if (_isLocked) {
        setState(() => _isLocked = false);
      }
      return;
    }

    // Ensure the lock screen is visible before we prompt
    if (!_isLocked) {
      setState(() {
        _isLocked = true;
      });
    }

    if (_isAuthenticating) return;

    _authenticate();
  }

  Future<void> _authenticate() async {
    setState(() {
      _isAuthenticating = true;
    });

    final authService = ref.read(localAuthServiceProvider);
    bool authenticated = await authService.authenticate();

    if (authenticated) {
      setState(() {
        _isLocked = false;
      });
    }

    setState(() {
      _isAuthenticating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Listen to changes in the lock provider
    ref.listen<bool>(appLockProvider, (previous, current) {
      if (current && !_isLocked) {
        _checkLockAndAuthenticate();
      } else if (!current && _isLocked) {
        setState(() {
          _isLocked = false;
        });
      }
    });

    return Stack(
      children: [
        widget.child,
        
        if (_isLocked)
          Positioned.fill(
            child: Container(
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
                      decoration: TextDecoration.none, // Since it's outside Material/Scaffold
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _isAuthenticating ? null : _authenticate,
                    icon: _isAuthenticating 
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) 
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
