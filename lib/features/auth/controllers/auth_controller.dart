import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_tracker/features/auth/repositories/auth_repository.dart';
import 'package:expense_tracker/features/transactions/controllers/transaction_controller.dart';
import 'package:expense_tracker/features/friends_money/controllers/friend_money_controller.dart';
import 'package:expense_tracker/features/budgets/controllers/budget_controller.dart';
import 'package:expense_tracker/features/savings_goal/controllers/savings_goal_controller.dart';

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  // Pass ref so the controller can invalidate stale providers on session change
  return AuthController(ref.watch(authRepositoryProvider), ref);
});

class AuthController extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _authRepository;
  final Ref _ref;

  AuthController(this._authRepository, this._ref)
      : super(const AsyncData(null));

  // ─── Invalidate all user-data providers ─────────────────────────────────────
  // Called after LOGOUT and after LOGIN to ensure Riverpod always
  // serves fresh Firestore streams for the new session.
  // Without this, the cached permission-denied error from the old session
  // persists and the home screen shows errors until the app is force-closed.
  void _invalidateUserProviders() {
    _ref.invalidate(transactionsStreamProvider);
    _ref.invalidate(friendMoneyStreamProvider);
    _ref.invalidate(budgetsStreamProvider);
    _ref.invalidate(savingsGoalStreamProvider);
    _ref.invalidate(budgetProgressProvider);
    _ref.invalidate(savingsProgressProvider);
  }

  // ─── Email Login ────────────────────────────────────────────────────────────
  Future<void> loginWithEmail(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final credential =
          await _authRepository.signInWithEmail(email, password);

      // Enforce email verification for email/password users
      if (credential.user != null && !credential.user!.emailVerified) {
        await _authRepository.signOut();
        throw Exception(
          'Please verify your email before logging in. Check your inbox.',
        );
      }
    });

    // Invalidate stale providers on successful login so fresh streams start
    if (!state.hasError) _invalidateUserProviders();
  }

  // ─── Sign Up ────────────────────────────────────────────────────────────────
  Future<void> signUpWithEmail(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => _authRepository.signUpWithEmail(email, password));
  }

  // ─── Google Login ───────────────────────────────────────────────────────────
  Future<void> loginWithGoogle() async {
    state = const AsyncLoading();
    state =
        await AsyncValue.guard(() => _authRepository.signInWithGoogle());

    // Invalidate stale providers on successful login so fresh streams start
    if (!state.hasError) _invalidateUserProviders();
  }

  // ─── Logout ─────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    state = const AsyncLoading();

    // Invalidate ALL user-specific providers BEFORE signing out.
    // This disposes the Firestore streams cleanly while the auth token
    // is still valid, preventing the permission-denied cascade.
    _invalidateUserProviders();

    state = await AsyncValue.guard(() => _authRepository.signOut());
  }
}