import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/features/home/views/main_layout.dart';
import 'package:expense_tracker/features/settings/views/currency_selection_screen.dart';
import 'package:expense_tracker/features/transactions/views/add_transaction_screen.dart';
import 'package:expense_tracker/features/auth/views/login_screen.dart';
import 'package:expense_tracker/features/auth/views/signup_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
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
      // Corrected: Only one route for '/' pointing to MainLayout
      builder: (context, state) => const MainLayout(), 
    ),
    GoRoute(
      path: '/add-transaction',
      name: 'add_transaction',
      // Corrected: Only one route for '/add-transaction'
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