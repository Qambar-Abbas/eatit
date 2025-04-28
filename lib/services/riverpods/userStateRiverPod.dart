import 'package:eatit/services/userService.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eatit/models/userModel.dart';

/// Expose UserService so it can be overridden in tests:
final userServiceProvider = Provider<UserService>((ref) {
  return UserService();
});

/// Holds the current logged‑in user (or null):
final userStateProvider =
    StateNotifierProvider<UserStateNotifier, UserModel?>((ref) {
  return UserStateNotifier(ref);
});

class UserStateNotifier extends StateNotifier<UserModel?> {
  final Ref ref;
  UserStateNotifier(this.ref) : super(null);

  /// Load from SharedPreferences on app start:
  Future<void> loadUserData() async {
    final svc = ref.read(userServiceProvider);
    final user = await svc.loadCachedUserData();
    state = user;
  }

  /// After login/sign‑up:
  void setUser(UserModel? user) {
    state = user;
  }

  /// Logout locally + Firebase:
  Future<void> logout() async {
    final svc = ref.read(userServiceProvider);
    await svc.logout();
    state = null;
  }
}
