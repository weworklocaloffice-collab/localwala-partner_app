/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 *
 * Website: https://localwala.tech
 * Email: weworklocal1@gmail.com
 *
 * Proprietary and Confidential.
 *
 * Unauthorized copying, modification, distribution,
 * publication, resale, reverse engineering, or use of
 * this software without prior written authorization is
 * strictly prohibited.
 */

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Scan directions for a reusable milk can.
///
/// Wire values must match `DairyCanLedger.eventType` in
/// `API/src/modules/dairy/models/dairy.can.ledger.model.js`.
enum DairyCanScanType {
  /// Loaded at the depot / store, on the way out.
  pickup('pickup'),

  /// Handed to the customer at a stop.
  issue('issue'),

  /// Empty can taken back from the customer.
  collect('collect'),

  /// Brought back to the depot at end of run.
  returnToStore('return_to_store');

  const DairyCanScanType(this.wire);

  final String wire;
}

/// A single queued can event awaiting sync.
class PendingCanScan {
  final String clientRef;
  final String runId;
  final String? stopId;
  final String? customerId;
  final String? orderId;
  final DairyCanScanType type;
  final List<String> canCodes;
  final int amountPaise;
  final DateTime capturedAt;
  final String? note;

  const PendingCanScan({
    required this.clientRef,
    required this.runId,
    this.stopId,
    this.customerId,
    this.orderId,
    required this.type,
    required this.canCodes,
    this.amountPaise = 0,
    required this.capturedAt,
    this.note,
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'clientRef': clientRef,
      'runId': runId,
      'stopId': stopId,
      'customerId': customerId,
      'orderId': orderId,
      'type': type.wire,
      'canCodes': canCodes,
      'amountPaise': amountPaise,
      'capturedAt': capturedAt.toIso8601String(),
      'note': note,
    };
  }

  factory PendingCanScan.fromJson(Map<String, dynamic> json) {
    return PendingCanScan(
      clientRef: json['clientRef']?.toString() ?? '',
      runId: json['runId']?.toString() ?? '',
      stopId: json['stopId']?.toString(),
      customerId: json['customerId']?.toString(),
      orderId: json['orderId']?.toString(),
      type: DairyCanScanType.values.firstWhere(
        (DairyCanScanType e) => e.wire == json['type']?.toString(),
        orElse: () => DairyCanScanType.issue,
      ),
      canCodes: (json['canCodes'] as List<dynamic>? ?? <dynamic>[]).map((dynamic e) => e.toString()).toList(),
      amountPaise: int.tryParse(json['amountPaise']?.toString() ?? '0') ?? 0,
      capturedAt: DateTime.tryParse(json['capturedAt']?.toString() ?? '') ?? DateTime.now(),
      note: json['note']?.toString(),
    );
  }
}

/// Durable outbox for can scans captured while offline.
///
/// Dairy routes run through low-coverage areas for hours, so a scan must never
/// block on network. The queue is persisted to `SharedPreferences` and replayed
/// in capture order. `clientRef` is the idempotency key the API dedupes on,
/// so a retry after a half-delivered batch cannot double-count a can.
class OfflineCanScanQueue {
  static const String _storageKey = '_dairyPendingCanScans';

  Future<List<PendingCanScan>> pending() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return <PendingCanScan>[];
    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(PendingCanScan.fromJson)
          .toList();
    } catch (_) {
      return <PendingCanScan>[];
    }
  }

  Future<void> enqueue(PendingCanScan scan) async {
    final List<PendingCanScan> current = await pending();
    if (current.any((PendingCanScan e) => e.clientRef == scan.clientRef)) return;
    current.add(scan);
    await _persist(current);
  }

  /// Removes scans by client reference once the API has acknowledged them.
  Future<void> acknowledge(List<String> clientRefs) async {
    final List<PendingCanScan> current = await pending();
    current.removeWhere((PendingCanScan e) => clientRefs.contains(e.clientRef));
    await _persist(current);
  }

  Future<int> count() async => (await pending()).length;

  /// Net can delta per scan type. Drives the depot reconciliation gate so the
  /// rider can see the imbalance before the shift is closed.
  Future<Map<DairyCanScanType, int>> balanceForRun(String runId) async {
    final List<PendingCanScan> scans = await pending();
    final Map<DairyCanScanType, int> balance = <DairyCanScanType, int>{};
    for (final PendingCanScan scan in scans.where((PendingCanScan e) => e.runId == runId)) {
      final int delta = scan.type == DairyCanScanType.issue || scan.type == DairyCanScanType.pickup ? scan.canCodes.length : -scan.canCodes.length;
      balance[scan.type] = (balance[scan.type] ?? 0) + delta;
    }
    return balance;
  }

  Future<void> clear() async => _persist(<PendingCanScan>[]);

  Future<void> _persist(List<PendingCanScan> scans) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(scans.map((PendingCanScan e) => e.toJson()).toList()));
  }

  /// Generates an idempotency key for a can scan.
  ///
  /// A monotonic counter is appended because `microsecondsSinceEpoch` alone is
  /// not unique — two scans in the same microsecond produce the same value, and
  /// the API dedupes on this key, so a collision would silently drop a can
  /// movement.
  static int _sequence = 0;

  static String newClientRef() {
    _sequence = (_sequence + 1) & 0x7fffffff;
    return '${DateTime.now().microsecondsSinceEpoch}_$_sequence';
  }
}
