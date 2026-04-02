import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../services/auth/auth_controller.dart';
import '../../services/auth/auth_service.dart';
import 'auth_state.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authControllerProvider =
StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.read(authServiceProvider));
});
