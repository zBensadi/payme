import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:payme/services/firebase_reauth_service.dart';
import 'package:payme/core/error/result.dart';

class FakeFirebaseAuth implements FirebaseAuth {
  User? fakeCurrentUser;

  @override
  User? get currentUser => fakeCurrentUser;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeUser implements User {
  String? fakeEmail;
  FirebaseAuthException? exceptionToThrow;
  Exception? genericExceptionToThrow;
  bool reauthenticateCalled = false;
  AuthCredential? lastCredential;

  @override
  String? get email => fakeEmail;

  @override
  Future<UserCredential> reauthenticateWithCredential(AuthCredential credential) async {
    reauthenticateCalled = true;
    lastCredential = credential;
    if (exceptionToThrow != null) {
      throw exceptionToThrow!;
    }
    if (genericExceptionToThrow != null) {
      throw genericExceptionToThrow!;
    }
    return FakeUserCredential();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeUserCredential implements UserCredential {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeFirebaseAuth fakeFirebaseAuth;
  late FakeUser fakeUser;
  late FirebaseReauthService reauthService;

  setUp(() {
    fakeFirebaseAuth = FakeFirebaseAuth();
    fakeUser = FakeUser();
    reauthService = FirebaseReauthService(fakeFirebaseAuth);
  });

  test('reauthenticate returns Failure when currentUser is null', () async {
    fakeFirebaseAuth.fakeCurrentUser = null;

    final result = await reauthService.reauthenticate('password');

    expect(result, isA<Failure>());
    expect((result as Failure).failure.message, 'Authentication failed. Please log in again.');
  });

  test('reauthenticate returns Failure when currentUser email is null', () async {
    fakeUser.fakeEmail = null;
    fakeFirebaseAuth.fakeCurrentUser = fakeUser;

    final result = await reauthService.reauthenticate('password');

    expect(result, isA<Failure>());
    expect((result as Failure).failure.message, 'Authentication failed. Please log in again.');
  });

  test('reauthenticate returns Success when reauthentication succeeds', () async {
    fakeUser.fakeEmail = 'test@example.com';
    fakeFirebaseAuth.fakeCurrentUser = fakeUser;

    final result = await reauthService.reauthenticate('correct_password');

    expect(result, isA<Success>());
    expect(fakeUser.reauthenticateCalled, isTrue);
  });

  test('reauthenticate maps wrong-password exception correctly', () async {
    fakeUser.fakeEmail = 'test@example.com';
    fakeFirebaseAuth.fakeCurrentUser = fakeUser;
    fakeUser.exceptionToThrow = FirebaseAuthException(code: 'wrong-password');

    final result = await reauthService.reauthenticate('wrong_password');

    expect(result, isA<Failure>());
    expect((result as Failure).failure.message, 'Incorrect password.');
  });

  test('reauthenticate maps invalid-credential exception correctly', () async {
    fakeUser.fakeEmail = 'test@example.com';
    fakeFirebaseAuth.fakeCurrentUser = fakeUser;
    fakeUser.exceptionToThrow = FirebaseAuthException(code: 'invalid-credential');

    final result = await reauthService.reauthenticate('invalid');

    expect(result, isA<Failure>());
    expect((result as Failure).failure.message, 'Incorrect password.');
  });

  test('reauthenticate maps too-many-requests exception correctly', () async {
    fakeUser.fakeEmail = 'test@example.com';
    fakeFirebaseAuth.fakeCurrentUser = fakeUser;
    fakeUser.exceptionToThrow = FirebaseAuthException(code: 'too-many-requests');

    final result = await reauthService.reauthenticate('password');

    expect(result, isA<Failure>());
    expect((result as Failure).failure.message, 'Too many attempts. Please try again later.');
  });
  
  test('reauthenticate maps requires-recent-login exception correctly', () async {
    fakeUser.fakeEmail = 'test@example.com';
    fakeFirebaseAuth.fakeCurrentUser = fakeUser;
    fakeUser.exceptionToThrow = FirebaseAuthException(code: 'requires-recent-login');

    final result = await reauthService.reauthenticate('password');

    expect(result, isA<Failure>());
    expect((result as Failure).failure.message, 'Please log out and log back in to perform this action.');
  });

  test('reauthenticate handles unknown FirebaseAuthException correctly', () async {
    fakeUser.fakeEmail = 'test@example.com';
    fakeFirebaseAuth.fakeCurrentUser = fakeUser;
    fakeUser.exceptionToThrow = FirebaseAuthException(code: 'unknown-error', message: 'Something went wrong.');

    final result = await reauthService.reauthenticate('password');

    expect(result, isA<Failure>());
    expect((result as Failure).failure.message, 'Authentication failed: Something went wrong.');
  });

  test('reauthenticate handles generic Exception correctly', () async {
    fakeUser.fakeEmail = 'test@example.com';
    fakeFirebaseAuth.fakeCurrentUser = fakeUser;
    fakeUser.genericExceptionToThrow = Exception('Unknown network error');

    final result = await reauthService.reauthenticate('password');

    expect(result, isA<Failure>());
    expect((result as Failure).failure.message, 'An unexpected error occurred.');
  });
}
