import 'package:flutter_test/flutter_test.dart';
import 'package:weeding_app/app/core/utils/validators.dart';

void main() {
  group('Validators', () {
    group('Email Validation', () {
      test('returns null for valid email', () {
        expect(Validators.email('user.name@domain.co'), null);
        expect(Validators.email('john@example.co.uk'), null);
        expect(Validators.email('hello@world.org'), null);
      });

      test('returns error for empty email', () {
        expect(Validators.email(''), isNotNull);
        expect(Validators.email(null), isNotNull);
      });

      test('returns error for invalid email', () {
        expect(Validators.email('notanemail'), isNotNull);
        expect(Validators.email('@domain.com'), isNotNull);
        expect(Validators.email('user@'), isNotNull);
      });
    });

    group('Password Validation', () {
      test('returns null for valid password', () {
        expect(Validators.password('password123'), null);
        expect(Validators.password('Abcdef1!'), null);
      });

      test('returns error for empty password', () {
        expect(Validators.password(''), isNotNull);
        expect(Validators.password(null), isNotNull);
      });

      test('returns error for short password', () {
        expect(Validators.password('12345'), isNotNull);
      });
    });

    group('Phone Validation', () {
      test('returns null for valid phone (optional field)', () {
        expect(Validators.phone('+33612345678'), null);
        expect(Validators.phone('0612345678'), null);
        expect(Validators.phone('0033612345678'), null);
      });

      test('returns null for empty phone (optional)', () {
        expect(Validators.phone(''), null);
        expect(Validators.phone(null), null);
      });

      test('returns error for invalid phone', () {
        expect(Validators.phone('abcdefghij'), isNotNull);
      });
    });

    group('Required Validation', () {
      test('returns null for non-empty value', () {
        expect(Validators.required('hello'), null);
        expect(Validators.required('  hello  '), null);
      });

      test('returns error for empty value', () {
        expect(Validators.required(''), isNotNull);
        expect(Validators.required('   '), isNotNull);
        expect(Validators.required(null), isNotNull);
      });

      test('returns custom field name in error', () {
        final result = Validators.required('', 'Nom');
        expect(result, contains('Nom'));
      });
    });

    group('Positive Number Validation', () {
      test('returns null for valid positive number', () {
        expect(Validators.positiveNumber('1'), null);
        expect(Validators.positiveNumber('42'), null);
        expect(Validators.positiveNumber('100'), null);
      });

      test('returns error for zero or negative', () {
        expect(Validators.positiveNumber('0'), isNotNull);
        expect(Validators.positiveNumber('-5'), isNotNull);
      });

      test('returns error for non-numeric', () {
        expect(Validators.positiveNumber('abc'), isNotNull);
      });

      test('returns error for empty', () {
        expect(Validators.positiveNumber(''), isNotNull);
        expect(Validators.positiveNumber(null), isNotNull);
      });
    });
  });
}
