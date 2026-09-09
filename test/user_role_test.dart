import 'package:flutter_test/flutter_test.dart';

import 'package:mi_grupo/features/auth/domain/user.dart';
import 'package:mi_grupo/features/auth/domain/user_role.dart';

const adminUser = User(
  id: 2,
  username: 'admin',
  firstName: 'Admin',
  lastName: 'User',
  email: 'admin@x.com',
);

const standardUser = User(
  id: 1,
  username: 'standard',
  firstName: 'Standard',
  lastName: 'User',
  email: 'standard@x.com',
);

void main() {
  test('an even id maps to admin', () {
    expect(adminUser.role, UserRole.admin);
  });

  test('an odd id maps to standard', () {
    expect(standardUser.role, UserRole.standard);
  });
}
