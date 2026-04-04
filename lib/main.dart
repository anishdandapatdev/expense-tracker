import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart'; // Ensure this points to where routerProvider is defined
import 'features/settings/views/app_lock_wrapper.dart';
import 'features/notifications/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Enable offline persistence with unlimited cache
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // Initialize the Notification Service
  final notificationService = NotificationService();
  await notificationService.init();
  await notificationService.requestPermission();
  
  runApp(
    // ProviderScope is required for Riverpod
    const ProviderScope(
      child: SpendWiseApp(),
    ),
  );
}

// Changed to ConsumerWidget to access Riverpod providers
class SpendWiseApp extends ConsumerWidget {
  const SpendWiseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the router provider to keep navigation in sync with auth state
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'SpendWise',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Automatically switch based on device settings
      routerConfig: router, // Pass the dynamic router here instead of the static appRouter
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return AppLockWrapper(
          child: child!,
        );
      },
    );
  }
}