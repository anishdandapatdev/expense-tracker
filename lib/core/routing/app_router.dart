import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/features/home/views/main_layout.dart';
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
      if (authState.isLoading) return null;

      // Get the actual Firebase User object
      final user = authState.valueOrNull;
      final isAuthRoute = state.matchedLocation == '/login' || state.matchedLocation == '/signup';

      // 1. If the user is NOT logged in and trying to access a secure route, kick to login
      if (user == null && !isAuthRoute) {
        return '/login';
      }

      // 2. If the user IS logged in...
      if (user != null) {
        // ...but their email is NOT verified, prevent them from going to the Home screen.
        // This stops the screen flashing bug during sign-up.
        if (!user.emailVerified) {
           if (!isAuthRoute) return '/login'; // Keep them out of the main app
           return null; // Let them stay on the signup screen while the background sign-out happens
        }
        
        // ...and their email IS verified, send them Home if they try to view login/signup
        if (isAuthRoute) {
          return '/';
        }
      }

      // 3. Otherwise, let them proceed normally
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