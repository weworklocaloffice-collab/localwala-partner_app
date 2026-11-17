/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright Ac 2026 WeWorkLocal.
 * All Rights Reserved.
 */

import 'dart:convert';

/// A quantity as stored on a receipt line (`{ value, unit }`).
class JhatkaReceiptQuantity {
  const JhatkaReceiptQuantity({required this.value, required this.unit});

  final num value;
  final String unit;

  factory JhatkaReceiptQuantity.fromJson(dynamic raw) {
    final Map<String, dynamic> map = raw is Map
        ? Map<String, dynamic>.from(raw)
        : <String, dynamic>{};
    return JhatkaReceiptQuantity(
      value: _num(map['value']),
      unit: (map['unit'] ?? '').toString(),
    );
  }

  String get display => '${_trim(value)} $unit'.trim();

  static String _trim(num value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toString();
  }
}

/// A governed rejection reason attached to a rejected line.
class JhatkaAppliedRejectionReason {
  const JhatkaAppliedRejectionReason({required this.code, this.note});

  final String code;
  final String? note;

  factory JhatkaAppliedRejectionReason.fromJson(dynamic raw) {
    final Map<String, dynamic> map = raw is Map
        ? Map<String, dynamic>.from(raw)
        : <String, dynamic>{};
    return JhatkaAppliedRejectionReason(
      code: (map['code'] ?? '').toString(),
      note: _stringOrNull(map['note']),
    );
  }
}

/// An active row from the rejection picker's controlled vocabulary.
class JhatkaRejectionReason {
  const JhatkaRejectionReason({
    required this.id,
    required this.code,
    required this.label,
    this.description,
    this.category,
    this.severity,
    this.autoReject = false,
    this.fault,
  });

  final String id;
  final String code;
  final String label;
  final String? description;
  final String? category;
  final String? severity;
  final bool autoReject;
  final String? fault;

  factory JhatkaRejectionReason.fromJson(dynamic raw) {
    final Map<String, dynamic> map = raw is Map
        ? Map<String, dynamic>.from(raw)
        : <String, dynamic>{};
    return JhatkaRejectionReason(
      id: (map['id'] ?? map['_id'] ?? '').toString(),
      code: (map['code'] ?? '').toString(),
      label: (map['label'] ?? map['code'] ?? '').toString(),
      description: _stringOrNull(map['description']),
      category: _stringOrNull(map['category']),
      severity: _stringOrNull(map['severity']),
      autoReject: map['autoReject'] == true,
      fault: _stringOrNull(map['fault']),
    );
  }
}

/// One line on a receipt, including its quality verdict and batch link.
class JhatkaReceiptLine {
  const JhatkaReceiptLine({
    required this.index,
    required this.id,
    required this.rawSku,
    required this.qualityStatus,
    required this.payability,
    this.receivedQty,
    this.acceptedQty,
    this.rejectedQty,
    this.unitPricePaise = 0,
    this.amountPaise = 0,
    this.rejectedValuePaise = 0,
    this.qualityNotes,
    this.batch,
    this.rejectionReasons = const <JhatkaAppliedRejectionReason>[],
  });

  final int index;
  final String id;
  final String rawSku;
  final String qualityStatus;
  final String payability;
  final JhatkaReceiptQuantity? receivedQty;
  final JhatkaReceiptQuantity? acceptedQty;
  final JhatkaReceiptQuantity? rejectedQty;

  /// Raw paise, because the receipt list is a lean query and therefore
  /// bypasses the money getters that convert to rupees at the API edge.
  final int unitPricePaise;
  final int amountPaise;
  final int rejectedValuePaise;

  final String? qualityNotes;
  final String? batch;
  final List<JhatkaAppliedRejectionReason> rejectionReasons;

  bool get isPending => qualityStatus == 'pending';
  bool get canDecide => isPending && batch == null;

  factory JhatkaReceiptLine.fromJson(dynamic raw, int index) {
    final Map<String, dynamic> map = raw is Map
        ? Map<String, dynamic>.from(raw)
        : <String, dynamic>{};
    final List<dynamic> reasons =
        (map['rejectionReasons'] as List<dynamic>?) ?? const <dynamic>[];
    return JhatkaReceiptLine(
      index: index,
      id: (map['id'] ?? map['_id'] ?? '').toString(),
      rawSku: (map['rawSku'] ?? '').toString(),
      qualityStatus: (map['qualityStatus'] ?? 'pending').toString(),
      payability: (map['payability'] ?? 'pending').toString(),
      receivedQty: map['receivedQty'] is Map
          ? JhatkaReceiptQuantity.fromJson(map['receivedQty'])
          : null,
      acceptedQty: map['acceptedQty'] is Map
          ? JhatkaReceiptQuantity.fromJson(map['acceptedQty'])
          : null,
      rejectedQty: map['rejectedQty'] is Map
          ? JhatkaReceiptQuantity.fromJson(map['rejectedQty'])
          : null,
      unitPricePaise: _int(map['unitPrice']),
      amountPaise: _int(map['amount']),
      rejectedValuePaise: _int(map['rejectedValue']),
      qualityNotes: _stringOrNull(map['qualityNotes']),
      batch: _stringOrNull(map['batch']),
      rejectionReasons: reasons
          .map(JhatkaAppliedRejectionReason.fromJson)
          .where(
            (JhatkaAppliedRejectionReason reason) => reason.code.isNotEmpty,
          )
          .toList(growable: false),
    );
  }
}

/// A procurement receipt as returned by `GET /inventory/receipts`.
class JhatkaReceipt {
  const JhatkaReceipt({
    required this.id,
    required this.receiptNo,
    required this.status,
    required this.qualityStatus,
    required this.lines,
    this.receivedAt,
    this.acceptedValuePaise = 0,
    this.rejectedValuePaise = 0,
    this.rejectionRatePct = 0,
    this.supplierName,
    this.poNo,
  });

  final String id;
  final String receiptNo;
  final String status;
  final String qualityStatus;
  final List<JhatkaReceiptLine> lines;
  final DateTime? receivedAt;
  final int acceptedValuePaise;
  final int rejectedValuePaise;
  final num rejectionRatePct;
  final String? supplierName;
  final String? poNo;

  bool get isDraft => status == 'draft';

  int get pendingLineCount =>
      lines.where((JhatkaReceiptLine line) => line.isPending).length;

  bool get canPost => isDraft && lines.isNotEmpty && pendingLineCount == 0;

  factory JhatkaReceipt.fromJson(Map<String, dynamic> raw) {
    final List<dynamic> rawLines =
        (raw['lines'] as List<dynamic>?) ?? const <dynamic>[];
    final Map<String, dynamic> totals = raw['totals'] is Map
        ? Map<String, dynamic>.from(raw['totals'] as Map)
        : <String, dynamic>{};
    final Map<String, dynamic> supplier = raw['supplier'] is Map
        ? Map<String, dynamic>.from(raw['supplier'] as Map)
        : <String, dynamic>{};
    final Map<String, dynamic> purchaseOrder = raw['purchaseOrder'] is Map
        ? Map<String, dynamic>.from(raw['purchaseOrder'] as Map)
        : <String, dynamic>{};

    return JhatkaReceipt(
      id: (raw['id'] ?? raw['_id'] ?? '').toString(),
      receiptNo: (raw['receiptNo'] ?? '').toString(),
      status: (raw['status'] ?? '').toString(),
      qualityStatus: (raw['qualityStatus'] ?? '').toString(),
      receivedAt: DateTime.tryParse((raw['receivedAt'] ?? '').toString()),
      acceptedValuePaise: _int(totals['totalAcceptedValue']),
      rejectedValuePaise: _int(totals['totalRejectedValue']),
      rejectionRatePct: _num(raw['rejectionRatePct']),
      supplierName: _stringOrNull(supplier['name']),
      poNo: _stringOrNull(purchaseOrder['poNo']),
      lines: List<JhatkaReceiptLine>.generate(
        rawLines.length,
        (int index) => JhatkaReceiptLine.fromJson(rawLines[index], index),
        growable: false,
      ),
    );
  }
}

/// Extract the semantic error code from an API error body.
///
/// Partner requests use `ResponseType.plain`, so the error payload arrives as a
/// JSON string rather than a map. The envelope's top-level `code` is the HTTP
/// status; the actionable code is nested under `extra` or `detail`.
String? receiptErrorCodeFromBody(String? rawBody) {
  if (rawBody == null || rawBody.isEmpty) return null;
  dynamic decoded;
  try {
    decoded = jsonDecode(rawBody);
  } on FormatException {
    return null;
  }
  if (decoded is! Map) return null;
  final Map<dynamic, dynamic> map = decoded;

  for (final String key in const <String>['extra', 'detail']) {
    final dynamic nested = map[key];
    if (nested is Map) {
      final dynamic code = nested['code'];
      if (code is String && code.isNotEmpty) return code;
    }
  }

  final dynamic direct = map['code'];
  if (direct is String && direct.isNotEmpty && int.tryParse(direct) == null) {
    return direct;
  }
  return null;
}

int _int(dynamic raw) {
  if (raw is num) return raw.round();
  return int.tryParse(raw?.toString() ?? '') ?? 0;
}

num _num(dynamic raw) {
  if (raw is num) return raw;
  return num.tryParse(raw?.toString() ?? '') ?? 0;
}

String? _stringOrNull(dynamic raw) {
  final String value = raw?.toString() ?? '';
  return value.isEmpty || value == 'null' ? null : value;
}
