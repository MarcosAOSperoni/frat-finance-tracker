import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frat_finance_tracker/features/auth/data/auth_repository.dart';
import 'package:frat_finance_tracker/features/auth/domain/app_user.dart';

// Auth repository provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

// Auth state stream provider
final authStateProvider = StreamProvider<AppUser?>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.authStateChanges();
});

// Current user provider
final currentUserProvider = Provider<AppUser?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) => user,
    loading: () => null,
    error: (_, __) => null,
  );
});

// All users provider (for VP to view all brothers)
final allUsersProvider = FutureProvider<List<AppUser>>((ref) async {
  final repository = ref.watch(authRepositoryProvider);
  return await repository.getAllUsers();
});
