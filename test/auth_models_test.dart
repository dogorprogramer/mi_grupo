import 'package:flutter_test/flutter_test.dart';

import 'package:mi_grupo/features/auth/data/models/auth_response.dart';
import 'package:mi_grupo/features/auth/data/models/user_dto.dart';

void main() {
  group('AuthResponse.fromJson', () {
    test('parses a real DummyJSON login response', () {
      final json = {
        'id': 1,
        'username': 'emilys',
        'email': 'emily.johnson@x.dummyjson.com',
        'firstName': 'Emily',
        'lastName': 'Johnson',
        'gender': 'female',
        'image': 'https://dummyjson.com/icon/emilys/128',
        'accessToken': 'token-123',
        'refreshToken': 'refresh-123',
      };

      final response = AuthResponse.fromJson(json);

      expect(response.accessToken, 'token-123');
      expect(response.user.id, 1);
      expect(response.user.username, 'emilys');
      expect(response.user.firstName, 'Emily');
      expect(response.user.lastName, 'Johnson');
      expect(response.user.email, 'emily.johnson@x.dummyjson.com');
      expect(response.user.image, 'https://dummyjson.com/icon/emilys/128');
    });
  });

  group('UserDto.fromJson', () {
    test('parses a /auth/me response', () {
      final json = {
        'id': 1,
        'username': 'emilys',
        'email': 'emily.johnson@x.dummyjson.com',
        'firstName': 'Emily',
        'lastName': 'Johnson',
        'image': 'https://dummyjson.com/icon/emilys/128',
      };

      final user = UserDto.fromJson(json);

      expect(user.id, 1);
      expect(user.username, 'emilys');
      expect(user.email, 'emily.johnson@x.dummyjson.com');
    });
  });
}
