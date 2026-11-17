/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright Ac 2026 WeWorkLocal.
 * All Rights Reserved.
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:partner/app/modules/jhatka/partner/procurement/jhatka_receipt_decision_models.dart';

void main() {
  group('JhatkaReceipt.fromJson', () {
    test('reads the lean list shape and keeps raw paise', () {
      final JhatkaReceipt receipt = JhatkaReceipt.fromJson(_receiptJson());
      expect(receipt.id, 'r1');
      expect(receipt.receiptNo, 'RC-1');
      expect(receipt.supplierName, 'Green Farm');
      expect(receipt.poNo, 'PO-1');
      expect(receipt.acceptedValuePaise, 40000);
      expect(receipt.rejectedValuePaise, 10000);
      expect(receipt.rejectionRatePct, 12.5);
      expect(receipt.receivedAt, isNotNull);

      final JhatkaReceiptLine line = receipt.lines.single;
      expect(line.index, 0);
      expect(line.unitPricePaise, 40000);
      expect(line.amountPaise, 60000);
      expect(line.receivedQty?.display, '1.5 KG');
      expect(line.canDecide, isTrue);
    });

    test('a pending line with a batch cannot be decided', () {
      final Map<String, dynamic> json = _receiptJson();
      final Map<String, dynamic> line =
          (json['lines'] as List<dynamic>).single as Map<String, dynamic>;
      line['batch'] = 'b1';

      final JhatkaReceipt receipt = JhatkaReceipt.fromJson(json);
      expect(receipt.lines.single.canDecide, isFalse);
      expect(receipt.canPost, isFalse);
    });

    test('canPost only when draft and no line is pending', () {
      final Map<String, dynamic> json = _receiptJson();
      final Map<String, dynamic> line =
          (json['lines'] as List<dynamic>).single as Map<String, dynamic>;
      line['qualityStatus'] = 'accepted';
      line['payability'] = 'payable';
      line['batch'] = 'b1';

      final JhatkaReceipt receipt = JhatkaReceipt.fromJson(json);
      expect(receipt.pendingLineCount, 0);
      expect(receipt.canPost, isTrue);
    });

    test('posted receipts never post again', () {
      final Map<String, dynamic> json = _receiptJson();
      json['status'] = 'posted';
      final Map<String, dynamic> line =
          (json['lines'] as List<dynamic>).single as Map<String, dynamic>;
      line['qualityStatus'] = 'accepted';

      expect(JhatkaReceipt.fromJson(json).canPost, isFalse);
    });
  });

  group('rejection rows', () {
    test('applied reasons keep code and note', () {
      final JhatkaReceipt receipt = JhatkaReceipt.fromJson(
        _receiptJson(
          reasons: <dynamic>[
            <String, dynamic>{'code': 'DAMAGED', 'note': 'Torn bag'},
          ],
        ),
      );
      final JhatkaAppliedRejectionReason reason =
          receipt.lines.single.rejectionReasons.single;
      expect(reason.code, 'DAMAGED');
      expect(reason.note, 'Torn bag');
    });

    test('picker reasons parse governed metadata', () {
      final JhatkaRejectionReason reason =
          JhatkaRejectionReason.fromJson(<String, dynamic>{
            '_id': 'rr1',
            'code': 'DAMAGED',
            'label': 'Damaged',
            'description': 'Physical damage',
            'category': 'quality',
            'severity': 'high',
            'autoReject': true,
            'fault': 'supplier',
          });
      expect(reason.id, 'rr1');
      expect(reason.code, 'DAMAGED');
      expect(reason.label, 'Damaged');
      expect(reason.category, 'quality');
      expect(reason.severity, 'high');
      expect(reason.autoReject, isTrue);
      expect(reason.fault, 'supplier');
    });

    test('blank reason codes are dropped', () {
      final JhatkaReceipt receipt = JhatkaReceipt.fromJson(
        _receiptJson(
          reasons: <dynamic>[
            <String, dynamic>{'note': 'missing code'},
          ],
        ),
      );
      expect(receipt.lines.single.rejectionReasons, isEmpty);
    });
  });

  group('receiptErrorCodeFromBody', () {
    test('reads extra.code before the numeric envelope code', () {
      expect(
        receiptErrorCodeFromBody(
          '{"success":false,"code":409,"extra":{"code":"QUALITY_DECISION_PENDING"}}',
        ),
        'QUALITY_DECISION_PENDING',
      );
    });

    test('falls back to detail.code', () {
      expect(
        receiptErrorCodeFromBody(
          '{"success":false,"code":409,"detail":{"code":"REVERSE_BATCH_FIRST"}}',
        ),
        'REVERSE_BATCH_FIRST',
      );
    });

    test('accepts a semantic top-level code', () {
      expect(
        receiptErrorCodeFromBody(
          '{"success":false,"code":"RECEIPT_ALREADY_POSTED"}',
        ),
        'RECEIPT_ALREADY_POSTED',
      );
    });

    test('ignores a numeric top-level code and malformed bodies', () {
      expect(receiptErrorCodeFromBody('{"success":false,"code":409}'), isNull);
      expect(receiptErrorCodeFromBody('not json'), isNull);
      expect(receiptErrorCodeFromBody(null), isNull);
    });
  });
}

Map<String, dynamic> _receiptJson({List<dynamic>? reasons}) {
  return <String, dynamic>{
    'id': 'r1',
    'receiptNo': 'RC-1',
    'status': 'draft',
    'qualityStatus': 'pending',
    'receivedAt': '2026-11-17T10:30:00.000Z',
    'rejectionRatePct': 12.5,
    'supplier': <String, dynamic>{'id': 's1', 'name': 'Green Farm'},
    'purchaseOrder': <String, dynamic>{'id': 'p1', 'poNo': 'PO-1'},
    'totals': <String, dynamic>{
      'totalAcceptedValue': 40000,
      'totalRejectedValue': 10000,
    },
    'lines': <dynamic>[
      <String, dynamic>{
        'id': 'l1',
        'rawSku': 'TOM',
        'qualityStatus': 'pending',
        'payability': 'pending',
        'receivedQty': <String, dynamic>{'value': 1.5, 'unit': 'KG'},
        'unitPrice': 40000,
        'amount': 60000,
        'rejectedValue': 0,
        'rejectionReasons': reasons ?? <dynamic>[],
      },
    ],
  };
}
