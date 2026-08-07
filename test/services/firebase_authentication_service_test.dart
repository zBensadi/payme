import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:payme/domain/entities/app_user.dart';
import 'package:payme/domain/repositories/authentication_repository.dart';
import 'package:payme/services/firebase_authentication_service.dart';
import 'package:payme/core/error/result.dart';
import 'package:payme/core/error/failures.dart';

class MockAuthenticationRepository implements AuthenticationRepository {
  AppUser? _currentUser;
  final _authStateController = StreamController<AppUser?>.broadcast();
  bool shouldFail = false;

  void emitUser(AppUser? user) {
    _currentUser = user;
    _authStateController.add(user);
  }

  @override
  Stream<AppUser?> authStateChanges() => _authStateController.stream;

  @override
  AppUser? get currentUser => _currentUser;

  @override
  Future<Result<void>> resetPassword(String email) async {
    if (shouldFail) {
      return const Failure(AuthFailure('Failed to reset'));
    }
    return const Success(null);
  }

  @override
  Future<Result<void>> signIn(String email, String password) async {
    if (shouldFail) {
      return const Failure(AuthFailure('Failed to sign in'));
    }
    final user = AppUser(
      uid: '123',
      email: email,
      isSuperAdmin: false,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    emitUser(user);
    return const Success(null);
  }

  @override
  Future<Result<void>> signOut() async {
    if (shouldFail) {
      return const Failure(AuthFailure('Failed to sign out'));
    }
    emitUser(null);
    return const Success(null);
  }
}

void main() {
  late MockAuthenticationRepository mockRepo;
  late FirebaseAuthenticationService authService;

  setUp(() {
    mockRepo = MockAuthenticationRepository();
    authService = FirebaseAuthenticationService(mockRepo);
  });

  group('FirebaseAuthenticationService', () {
    test('signIn succeeds with valid input', () async {
      final result = await authService.signIn('test@example.com', 'password');
      expect(result, isA<Success>());
      expect(mockRepo.currentUser, isNotNull);
      expect(mockRepo.currentUser!.email, 'test@example.com');
    });

    test('signIn fails with empty input', () async {
      final result = await authService.signIn('', 'password');
      expect(result, isA<Failure>());
      expect((result as Failure).failure.message, 'emailRequired');
      expect(mockRepo.currentUser, isNull);
    });

    test('signIn fails with invalid email format', () async {
      final result = await authService.signIn('invalidemail', 'password');
      expect(result, isA<Failure>());
      expect((result as Failure).failure.message, 'invalidEmailFormat');
      expect(mockRepo.currentUser, isNull);
    });

    test('signIn fails when repository fails', () async {
      mockRepo.shouldFail = true;
      final result = await authService.signIn('test@example.com', 'password');
      expect(result, isA<Failure>());
      expect((result as Failure).failure.message, 'Failed to sign in');
    });

    test('signOut clears current user', () async {
      await authService.signIn('test@example.com', 'password');
      expect(mockRepo.currentUser, isNotNull);
      
      final result = await authService.signOut();
      expect(result, isA<Success>());
      expect(mockRepo.currentUser, isNull);
    });

    test('resetPassword succeeds', () async {
      final result = await authService.resetPassword('test@example.com');
      expect(result, isA<Success>());
    });

    test('resetPassword fails with empty email', () async {
      final result = await authService.resetPassword('');
      expect(result, isA<Failure>());
      expect((result as Failure).failure.message, 'emailRequired');
    });
    test('resetPassword fails with invalid email format', () async {
      final result = await authService.resetPassword('invalidemail');
      expect(result, isA<Failure>());
      expect((result as Failure).failure.message, 'invalidEmailFormat');
    });
  });
}
