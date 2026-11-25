import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod_clean_architecture/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_riverpod_clean_architecture/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:flutter_riverpod_clean_architecture/features/auth/providers/auth_providers.dart';
import '../../../home/presentation/providers/home_provider.dart';
import '../../../notifications/presentation/providers/timeline_provider.dart';
import '../../../report/presentation/providers/report_provider.dart';
import '../../../settings/presentation/providers/budget_provider.dart';
import '../../../transaction/presentation/providers/transaction_provider.dart';
import '../../../transaction/providers/transaction_provider.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../../wallet/providers/smart_spending_provider.dart';

// Auth state
class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final UserEntity? user;
  final String? errorMessage;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    UserEntity? user,
    bool clearUser = false,
    String? errorMessage,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      user: clearUser ? null : (user ?? this.user),
      errorMessage: errorMessage,
    );
  }
}

// Auth notifier
class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    return const AuthState();
  }

  /// Kiểm tra token còn trong storage không → gọi khi app khởi động
  Future<void> checkAuthStatus() async {
    state = state.copyWith(isLoading: true);

    final authRepo = ref.read(authRepositoryProvider);

    // Kiểm tra token
    final authResult = await authRepo.isAuthenticated();
    final hasToken = authResult.fold((_) => false, (v) => v);

    if (!hasToken) {
      state = const AuthState(isAuthenticated: false, isLoading: false);
      return;
    }

    // Lấy user đã cache
    final userResult = await authRepo.getCurrentUser();
    userResult.fold(
      (_) {
        state = const AuthState(isAuthenticated: false, isLoading: false);
      },
      (user) {
        state = AuthState(isAuthenticated: true, isLoading: false, user: user);
      },
    );
  }

  // Login thật
  Future<void> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final loginUseCase = ref.read(loginUseCaseProvider);
    final result = await loginUseCase.execute(email: email, password: password);

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        errorMessage: failure.message,
      ),
      (user) => state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        user: user,
        errorMessage: null,
      ),
    );
  }

  // Demo login (backend: POST /auth/demo, chỉ bật trên localhost dev)
  Future<void> demoLogin() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final authRepo = ref.read(authRepositoryProvider);
    final result = await authRepo.demoLogin();

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        errorMessage: failure.message,
      ),
      (user) => state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        user: user,
        errorMessage: null,
      ),
    );
  }

  // Register thật
  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final registerUseCase = ref.read(registerUseCaseProvider);
    final result = await registerUseCase.execute(
      name: name,
      email: email,
      password: password,
    );

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        errorMessage: failure.message,
      ),
      (user) => state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        user: user,
        errorMessage: null,
      ),
    );
  }

  // Logout
  Future<void> logout() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final logoutUseCase = ref.read(logoutUseCaseProvider);
    final result = await logoutUseCase.execute();

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      ),
      (_) {
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: false,
          clearUser: true,
          errorMessage: null,
        );
        ref.invalidate(homeProvider);
        ref.invalidate(reportProvider);
        ref.invalidate(transactionProvider);
        ref.invalidate(transactionFormProvider);
        ref.invalidate(budgetProvider);
        ref.invalidate(timelineProvider);
        ref.invalidate(smartSpendingProvider);
        ref.invalidate(walletProvider);
      },
    );
  }

  // Update profile
  Future<bool> updateProfile(UserEntity user) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final updateProfileUseCase = ref.read(updateProfileUseCaseProvider);
    final result = await updateProfileUseCase.execute(user);

    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
      (updatedUser) {
        state = state.copyWith(
          isLoading: false,
          user: updatedUser,
          errorMessage: null,
        );
        return true;
      },
    );
  }

  // Đổi mật khẩu
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final changePasswordUseCase = ref.read(changePasswordUseCaseProvider);
    final result = await changePasswordUseCase.execute(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );

    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
      (_) {
        state = state.copyWith(isLoading: false, errorMessage: null);
        return true;
      },
    );
  }
}

// Auth provider
final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
