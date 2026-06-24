import 'package:flutter_test/flutter_test.dart';
import 'package:app_flutter/domain/types.dart';
import 'package:app_flutter/domain/validation.dart';

void main() {
  group('validateAstronomicalBody', () {
    test('passes on lowercase ASCII without leading "the "', () {
      expect(validateAstronomicalBody('earth'), isTrue);
      expect(validateAstronomicalBody('mars'), isTrue);
      expect(validateAstronomicalBody('moon'), isTrue);
      expect(validateAstronomicalBody('wgs-84'), isTrue);
    });

    test('fails on empty string', () {
      expect(validateAstronomicalBody(''), isFalse);
    });

    test('fails on uppercase letters', () {
      expect(validateAstronomicalBody('Earth'), isFalse);
      expect(validateAstronomicalBody('MARS'), isFalse);
    });

    test('fails on leading "the "', () {
      expect(validateAstronomicalBody('the earth'), isFalse);
      expect(validateAstronomicalBody('the mars'), isFalse);
    });
  });

  group('validateGeodeticDatum', () {
    test('passes on lowercase ASCII without spaces', () {
      expect(validateGeodeticDatum('wgs-84'), isTrue);
      expect(validateGeodeticDatum('nad83'), isTrue);
    });

    test('fails on uppercase letters', () {
      expect(validateGeodeticDatum('WGS-84'), isFalse);
      expect(validateGeodeticDatum('Nad83'), isFalse);
    });

    test('fails on spaces', () {
      expect(validateGeodeticDatum('wgs 84'), isFalse);
    });
  });

  group('validateAccuracy', () {
    test('passes on null', () {
      expect(validateAccuracy(null), isTrue);
    });

    test('passes on non-negative with <= 6 decimal places', () {
      expect(validateAccuracy(0.0), isTrue);
      expect(validateAccuracy(12.0), isTrue);
      expect(validateAccuracy(0.123456), isTrue);
      expect(validateAccuracy(1.000001), isTrue);
    });

    test('fails on negative', () {
      expect(validateAccuracy(-0.000001), isFalse);
      expect(validateAccuracy(-12.0), isFalse);
    });

    test('fails on > 6 decimal places', () {
      expect(validateAccuracy(0.0000001), isFalse);
      expect(validateAccuracy(1.1234567), isFalse);
    });
  });

  group('validateReferenceFrame', () {
    test('passes with valid config', () {
      final validFrame = ReferenceFrame(
        alternateSystem: 'test-system',
        astronomicalBody: 'earth',
        geodeticSystem: GeodeticSystem(
          geodeticDatum: 'wgs-84',
          coordAccuracy: 0.123,
          heightAccuracy: 0.456,
        ),
      );
      expect(validateReferenceFrame(validFrame), isTrue);
    });

    test('fails if body is invalid', () {
      final invalidFrame = ReferenceFrame(
        alternateSystem: '',
        astronomicalBody: 'Earth', // Uppercase
        geodeticSystem: GeodeticSystem(
          geodeticDatum: 'wgs-84',
        ),
      );
      expect(validateReferenceFrame(invalidFrame), isFalse);
    });

    test('fails if datum is invalid', () {
      final invalidFrame = ReferenceFrame(
        alternateSystem: '',
        astronomicalBody: 'earth',
        geodeticSystem: GeodeticSystem(
          geodeticDatum: 'Wgs-84', // Uppercase
        ),
      );
      expect(validateReferenceFrame(invalidFrame), isFalse);
    });

    test('fails if accuracy is invalid', () {
      final invalidFrame = ReferenceFrame(
        alternateSystem: '',
        astronomicalBody: 'earth',
        geodeticSystem: GeodeticSystem(
          geodeticDatum: 'wgs-84',
          coordAccuracy: -0.1, // Negative
        ),
      );
      expect(validateReferenceFrame(invalidFrame), isFalse);
    });
  });
}
