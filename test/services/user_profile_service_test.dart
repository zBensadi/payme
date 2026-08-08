import 'package:flutter_test/flutter_test.dart';

import 'package:payme/core/error/result.dart';
import 'package:payme/domain/entities/app_user.dart';
import 'package:payme/domain/entities/user_profile.dart';
import 'package:payme/domain/repositories/user_profile_repository.dart';
import 'package:payme/services/user_profile_service.dart';

class MockUserProfileRepository implements UserProfileRepository {
  final Future<Result<UserProfile?>> Function(String, String, String?) getUserProfileMock;

  MockUserProfileRepository(this.getUserProfileMock);

  @override
  Future<Result<UserProfile?>> getUserProfile({
    required String uid,
    required String email,
    String? displayName,
  }) {
    return getUserProfileMock(uid, email, displayName);
  }
}

void main() {
  late UserProfileService service;

  setUp(() {
    // Service is initialized in tests with specific mocks
  });

  test('getUserProfile returns profile from repository', () async {
    final mockUser = AppUser(
      uid: 'user1',
      email: 'test@test.com',
      displayName: 'Test',
      businessId: 'biz1',
      roleId: 'role1',
      isSuperAdmin: true,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final mockProfile = UserProfile(user: mockUser);

    final repo = MockUserProfileRepository((uid, email, displayName) async {
      return Success(mockProfile);
    });

    service = UserProfileService(repo);

    final result = await service.getUserProfile(
      uid: 'user1',
      email: 'test@test.com',
      displayName: 'Test',
    );

    expect(result, isA<Success<UserProfile?>>());
    expect((result as Success).value, mockProfile);
  });
}
