import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_queue_app/models/user_role.dart';
import 'package:restaurant_queue_app/models/user_profile.dart';
import 'package:restaurant_queue_app/services/auth_service.dart';

void main() {
  group('AuthService Input Validation', () {
    test('Email validation returns error for empty or invalid emails', () {
      expect(AuthService.validateEmail(''), isNotNull);
      expect(AuthService.validateEmail('   '), isNotNull);
      expect(AuthService.validateEmail('notanemail'), isNotNull);
      expect(AuthService.validateEmail('user@'), isNotNull);
      expect(AuthService.validateEmail('user@domain'), isNotNull);
    });

    test('Email validation passes for valid emails', () {
      expect(AuthService.validateEmail('user@example.com'), isNull);
      expect(AuthService.validateEmail('customer.smart@dinequeue.lk'), isNull);
    });

    test('Password validation returns error for short or empty passwords', () {
      expect(AuthService.validatePassword(''), isNotNull);
      expect(AuthService.validatePassword('12345'), isNotNull);
    });

    test('Password validation passes for 6+ characters', () {
      expect(AuthService.validatePassword('123456'), isNull);
      expect(AuthService.validatePassword('securePass123!'), isNull);
    });

    test('Name validation enforces at least 2 characters', () {
      expect(AuthService.validateName(''), isNotNull);
      expect(AuthService.validateName('A'), isNotNull);
      expect(AuthService.validateName('Alex Morgan'), isNull);
    });
  });

  group('UserRole & UserProfile Serialization', () {
    test('UserRole string conversion and defaults', () {
      expect(UserRole.fromString('customer'), UserRole.customer);
      expect(UserRole.fromString('receptionist'), UserRole.receptionist);
      expect(UserRole.fromString('manager'), UserRole.manager);
      expect(UserRole.fromString('admin'), UserRole.admin);
      expect(UserRole.fromString('administrator'), UserRole.admin);
      expect(UserRole.fromString(null), UserRole.customer);
      expect(UserRole.fromString('unknown_role'), UserRole.customer);
    });

    test('UserProfile JSON serialization roundtrip', () {
      final json = {
        'id': 'usr_123',
        'full_name': 'John Doe',
        'role': 'receptionist',
        'phone_number': '+94771234567',
      };

      final profile = UserProfile.fromJson(json, defaultEmail: 'john@example.com');
      expect(profile.id, 'usr_123');
      expect(profile.fullName, 'John Doe');
      expect(profile.role, UserRole.receptionist);
      expect(profile.email, 'john@example.com');
      expect(profile.phoneNumber, '+94771234567');

      final serialized = profile.toJson();
      expect(serialized['role'], 'receptionist');
      expect(serialized['full_name'], 'John Doe');
    });
  });
}
