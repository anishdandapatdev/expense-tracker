import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_tracker/features/auth/repositories/auth_repository.dart';

final authControllerProvider = StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});

class AuthController extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _authRepository;

  AuthController(this._authRepository) : super(const AsyncData(null));

  Future<void> loginWithEmail(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final credential = await _authRepository.signInWithEmail(email, password);
      
      // Enforce Email Verification
      if (credential.user != null && !credential.user!.emailVerified) {
        await _authRepository.signOut(); // Sign them back out
        throw Exception('Please verify your email before logging in. Check your inbox.');
      }
    });
  }

  Future<void> signUpWithEmail(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _authRepository.signUpWithEmail(email, password));
  }

  Future<void> loginWithGoogle() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _authRepository.signInWithGoogle());
  }

  Future<void> logout() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _authRepository.signOut());
  }
}