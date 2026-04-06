import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/core/layout/main_layout.dart';
import 'package:expense_tracker/features/settings/views/currency_selection_screen.dart';
import 'package:expense_tracker/features/transactions/views/add_transaction_screen.dart';
import 'package:expense_tracker/features/auth/views/login_screen.dart';
import 'package:expense_tracker/features/auth/views/signup_screen.dart';
import 'package:expense_tracker/features/auth/repositories/auth_repository.dart'; 

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/', 
    redirect: (context, state) {
      // While auth state is still loading, don't redirect
      if (authState.isLoading) return null;

      final user = authState.valueOrNull;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup';

      // 1. Not logged in → go to login
      if (user == null && !isAuthRoute) return '/login';

      if (user != null) {
      
        final isEmailPasswordUser = user.providerData
            .any((info) => info.providerId == 'password');

        // 2. Email/password users MUST have verified their email before entering the app
        if (isEmailPasswordUser && !user.emailVerified) {
          if (!isAuthRoute) return '/login';
          return null; // Stay on auth route while background sign-out happens
        }

        // 3. All verified/social users → redirect away from auth screens
        if (isAuthRoute) return '/';
      }

      // 4. Otherwise proceed normally
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/currency-setup',
        name: 'currency_setup',
        builder: (context, state) => const CurrencySelectionScreen(),
      ),
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const MainLayout(), 
      ),
      GoRoute(
        path: '/add-transaction',
        name: 'add_transaction',
        builder: (context, state) => const AddTransactionScreen(),
      ),
      GoRoute(
        path: '/analytics',
        name: 'analytics',
        builder: (context, state) => const Scaffold(body: Center(child: Text('Analytics'))),
      ),
      GoRoute(
        path: '/budgets',
        name: 'budgets',
        builder: (context, state) => const Scaffold(body: Center(child: Text('Budgets'))),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const Scaffold(body: Center(child: Text('Settings'))),
      ),
    ],
  );
});