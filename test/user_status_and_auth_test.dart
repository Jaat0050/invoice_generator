import 'package:flutter_test/flutter_test.dart';
import 'package:invoice_generator/features/auth/data/models/user_model.dart';
import 'package:invoice_generator/features/auth/data/models/business_model.dart';

void main() {
  group('UserModel is_active and is_deleted Tests', () {
    test('Default values are isActive=true and isDeleted=false', () {
      const user = UserModel(
        id: 1,
        name: 'Test Owner',
        email: 'test@example.com',
      );

      expect(user.isActive, true);
      expect(user.isDeleted, false);
      expect(user.isDelete, false);
    });

    test('fromJson correctly parses is_active and is_deleted', () {
      final json = {
        'id': 101,
        'name': 'John Doe',
        'email': 'john@example.com',
        'is_active': false,
        'is_deleted': true,
      };
      final user = UserModel.fromJson(json);
      expect(user.isActive, false);
      expect(user.isDeleted, true);
      expect(user.isDelete, true);
    });

    test('toJson serializes is_active and is_deleted', () {
      const user = UserModel(
        id: 1,
        name: 'John Doe',
        email: 'john@example.com',
        isActive: false,
        isDeleted: true,
      );

      final json = user.toJson();
      expect(json['is_active'], false);
      expect(json['is_deleted'], true);
    });

    test('copyWith updates isActive and isDeleted correctly', () {
      const user = UserModel(
        id: 1,
        name: 'John',
        email: 'john@example.com',
        isActive: true,
        isDeleted: false,
      );

      final deactivated = user.copyWith(isActive: false);
      expect(deactivated.isActive, false);
      expect(deactivated.isDeleted, false);

      final deleted = user.copyWith(isDeleted: true);
      expect(deleted.isActive, true);
      expect(deleted.isDeleted, true);
      expect(deleted.isDelete, true);
    });
  });

  group('BusinessModel is_active and is_deleted Tests', () {
    test('Default values are isActive=true and isDeleted=false', () {
      const business = BusinessModel(
        id: 1,
        name: 'My Store',
      );

      expect(business.isActive, true);
      expect(business.isDeleted, false);
      expect(business.isDelete, false);
    });

    test('fromJson and toJson handle is_active and is_deleted', () {
      final json = {
        'id': 5,
        'name': 'Super Enterprises',
        'is_active': false,
        'is_deleted': true,
      };

      final business = BusinessModel.fromJson(json);
      expect(business.isActive, false);
      expect(business.isDeleted, true);
      expect(business.isDelete, true);

      final serialized = business.toJson();
      expect(serialized['is_active'], false);
      expect(serialized['is_deleted'], true);
    });

    test('copyWith updates isActive and isDeleted correctly', () {
      const business = BusinessModel(
        id: 1,
        name: 'Store',
      );

      final updated = business.copyWith(isActive: false, isDeleted: true);
      expect(updated.isActive, false);
      expect(updated.isDeleted, true);
      expect(updated.isDelete, true);
    });
  });
}
