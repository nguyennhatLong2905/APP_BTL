import 'package:fpdart/fpdart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod_clean_architecture/core/constants/app_constants.dart';
import 'package:flutter_riverpod_clean_architecture/core/error/exceptions.dart';
import 'package:flutter_riverpod_clean_architecture/core/error/failures.dart';
import 'package:flutter_riverpod_clean_architecture/core/providers/storage_providers.dart';
import 'package:flutter_riverpod_clean_architecture/core/storage/local_storage_service.dart';
import 'package:flutter_riverpod_clean_architecture/core/storage/secure_storage_service.dart';
import 'package:flutter_riverpod_clean_architecture/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:flutter_riverpod_clean_architecture/features/auth/data/models/user_model.dart';
import 'package:flutter_riverpod_clean_architecture/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_riverpod_clean_architecture/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final LocalStorageService _localStorageService;
  final SecureStorageService _secureStorageService;

  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required LocalStorageService localStorageService,
    required SecureStorageService secureStorageService,
  })  : _remoteDataSource = remoteDataSource,
        _localStorageService = localStorageService,
        _secureStorageService = secureStorageService;

  @override
  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _remoteDataSource.login(
        email: email,
        password: password,
      );

      // Backend trả về { accessToken: "...", user: { _id, displayName, ... } }
      final accessToken = response['accessToken'] as String;
      final userData = response['user'] as Map<String, dynamic>;

      // Lưu JWT token thật vào secure storage
      await _secureStorageService.write(
        key: AppConstants.tokenKey,
        value: accessToken,
      );

      // Map backend user → UserModel
      final user = UserModel(
        id: userData['_id'] as String,
        name: userData['displayName'] as String? ?? '',
        email: email,
        createdAt: userData['createdAt'] != null
            ? DateTime.tryParse(userData['createdAt'].toString())
            : null,
        updatedAt: userData['updatedAt'] != null
            ? DateTime.tryParse(userData['updatedAt'].toString())
            : null,
      );

      // Cache user data locally
      await _localStorageService.setObject(
        AppConstants.userDataKey,
        user.toJson(),
      );

      return Right(user.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException {
      return const Left(NetworkFailure());
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(message: e.message));
    } on Exception {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, UserEntity>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _remoteDataSource.register(
        name: name,
        email: email,
        password: password,
      );

      final accessToken = response['accessToken'] as String;
      final userData = response['user'] as Map<String, dynamic>;

      await _secureStorageService.write(
        key: AppConstants.tokenKey,
        value: accessToken,
      );

      final user = UserModel(
        id: userData['_id'] as String,
        name: userData['displayName'] as String? ?? name,
        email: email,
        createdAt: userData['createdAt'] != null
            ? DateTime.tryParse(userData['createdAt'].toString())
            : null,
        updatedAt: userData['updatedAt'] != null
            ? DateTime.tryParse(userData['updatedAt'].toString())
            : null,
      );

      await _localStorageService.setObject(
        AppConstants.userDataKey,
        user.toJson(),
      );

      return Right(user.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException {
      return const Left(NetworkFailure());
    } on BadRequestException catch (e) {
      return Left(ValidationFailure(message: e.message));
    } on Exception {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await _localStorageService.remove(AppConstants.userDataKey);
      await _secureStorageService.delete(key: AppConstants.tokenKey);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } on Exception {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, bool>> isAuthenticated() async {
    try {
      final token = await _secureStorageService.read(
        key: AppConstants.tokenKey,
      );
      return Right(token != null && token.isNotEmpty);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } on Exception {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, UserEntity>> getCurrentUser() async {
    try {
      final userData = _localStorageService.getObject(AppConstants.userDataKey);
      if (userData == null) {
        return const Left(AuthFailure(message: 'User not found'));
      }
      final user = UserModel.fromJson(userData as Map<String, dynamic>);
      return Right(user.toEntity());
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } on Exception {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, UserEntity>> updateProfile(UserEntity user) async {
    try {
      final updated = UserModel.fromEntity(
        user.copyWith(updatedAt: DateTime.now()),
      );
      await _localStorageService.setObject(
        AppConstants.userDataKey,
        updated.toJson(),
      );
      return Right(updated.toEntity());
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } on Exception {
      return const Left(ServerFailure());
    }
  }
}

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService.create();
});

// Repository provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remoteDataSource: ref.watch(authRemoteDataSourceProvider),
    localStorageService: ref.watch(localStorageServiceProvider),
    secureStorageService: ref.watch(secureStorageServiceProvider),
  );
});
