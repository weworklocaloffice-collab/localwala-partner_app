/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:partner/app/modules/jhatka/partner/weighing/jhatka_money.dart'
    as jhatka_money;

void main() {
  group('formatPaise', () {
    test('formats whole rupees with two decimals', () {
      expect(jhatka_money.formatPaise(40000), 'Rs 400.00');
    });

    test('pads single-digit paise', () {
      expect(jhatka_money.formatPaise(40005), 'Rs 400.05');
    });

    test('handles zero and negatives', () {
      expect(jhatka_money.formatPaise(0), 'Rs 0.00');
      expect(jhatka_money.formatPaise(-3200), '-Rs 32.00');
    });
  });

  group('rupees round-trip', () {
    test('rupeesToPaise then formatPaise is the identity', () {
      expect(
        jhatka_money.formatPaise(jhatka_money.rupeesToPaise(400)),
        'Rs 400.00',
      );
    });

    test('formatRupees matches formatPaise', () {
      expect(jhatka_money.formatRupees(432.0), 'Rs 432.00');
    });
  });

  group('toGrams', () {
    test('GRAM passes through rounded', () {
      expect(jhatka_money.toGrams(1050, 'GRAM'), 1050);
    });

    test('KG scales by 1000', () {
      expect(jhatka_money.toGrams(1, 'KG'), 1000);
      expect(jhatka_money.toGrams(0.9, 'KG'), 900);
    });

    test('is case-insensitive', () {
      expect(jhatka_money.toGrams(2, 'kg'), 2000);
    });

    test('unconvertible units return null, never a guess', () {
      expect(jhatka_money.toGrams(12, 'PIECE'), isNull);
      expect(jhatka_money.toGrams(1, 'DOZEN'), isNull);
    });
  });

  group('estimatedLinePaise floors like the server', () {
    test('1 kg @ Rs 400/kg is exactly 40000', () {
      expect(
        jhatka_money.estimatedLinePaise(
          requestedGrams: 1000,
          unitPricePaise: 40000,
        ),
        40000,
      );
    });

    test('1.08 kg @ Rs 400/kg floors to 43200', () {
      expect(
        jhatka_money.estimatedLinePaise(
          requestedGrams: 1080,
          unitPricePaise: 40000,
        ),
        43200,
      );
    });
  });

  group('withinEstimate (client-side VW-01)', () {
    test('equal is within', () {
      expect(
        jhatka_money.withinEstimate(
          finalPaise: 40000,
          estimatedPaise: 40000,
        ),
        isTrue,
      );
    });

    test('below is within', () {
      expect(
        jhatka_money.withinEstimate(
          finalPaise: 36000,
          estimatedPaise: 40000,
        ),
        isTrue,
      );
    });

    test('above is not', () {
      expect(
        jhatka_money.withinEstimate(
          finalPaise: 40001,
          estimatedPaise: 40000,
        ),
        isFalse,
      );
    });
  });
}
