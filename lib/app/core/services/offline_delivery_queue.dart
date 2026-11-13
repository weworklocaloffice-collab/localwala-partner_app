import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PendingDelivery {
  PendingDelivery({
    required this.clientRef,
    required this.runId,
    required this.stopId,
    required this.cansDelivered,
    required this.emptyCansCollected,
    required this.amountCollected,
    this.shortfallReason,
    this.localProofPath,
    required this.capturedAt,
  });

  final String clientRef;
  final String runId;
  final String stopId;
  final int cansDelivered;
  final int emptyCansCollected;
  final num amountCollected;
  final String? shortfallReason;
  final String? localProofPath;
  final String capturedAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'clientRef': clientRef,
        'runId': runId,
        'stopId': stopId,
        'cansDelivered': cansDelivered,
        'emptyCansCollected': emptyCansCollected,
        'amountCollected': amountCollected,
        'shortfallReason': shortfallReason,
        'localProofPath': localProofPath,
        'capturedAt': capturedAt,
      };

  static PendingDelivery fromJson(Map<String, dynamic> json) => PendingDelivery(
        clientRef: json['clientRef']?.toString() ?? '',
        runId: json['runId']?.toString() ?? '',
        stopId: json['stopId']?.toString() ?? '',
        cansDelivered: int.tryParse(json['cansDelivered']?.toString() ?? '0') ?? 0,
        emptyCansCollected:
            int.tryParse(json['emptyCansCollected']?.toString() ?? '0') ?? 0,
        amountCollected: num.tryParse(json['amountCollected']?.toString() ?? '0') ?? 0,
        shortfallReason: json['shortfallReason']?.toString(),
        localProofPath: json['localProofPath']?.toString(),
        capturedAt: json['capturedAt']?.toString() ?? DateTime.now().toUtc().toIso8601String(),
      );
}

class OfflineDeliveryQueue {
  static const String _storageKey = '_dairyPendingDeliveries';

  Future<List<PendingDelivery>> pending() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return <PendingDelivery>[];
    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map>()
          .map((Map<dynamic, dynamic> e) => PendingDelivery.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return <PendingDelivery>[];
    }
  }

  Future<void> enqueue(PendingDelivery delivery) async {
    final List<PendingDelivery> current = await pending();
    if (current.any((PendingDelivery e) => e.clientRef == delivery.clientRef)) return;
    current.add(delivery);
    await _persist(current);
  }

  Future<void> acknowledge(List<String> clientRefs) async {
    final List<PendingDelivery> current = await pending();
    current.removeWhere((PendingDelivery e) => clientRefs.contains(e.clientRef));
    await _persist(current);
  }

  Future<String> persistPhoto(String sourcePath, String stopId) async {
    final Directory base = await getApplicationDocumentsDirectory();
    final Directory dir = Directory('${base.path}/pending_pods');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    final String ext = sourcePath.contains('.') ? sourcePath.split('.').last : 'jpg';
    final String target = '${dir.path}/$stopId-${DateTime.now().millisecondsSinceEpoch}.$ext';
    await File(sourcePath).copy(target);
    return target;
  }

  Future<void> _persist(List<PendingDelivery> list) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(list.map((PendingDelivery e) => e.toJson()).toList()),
    );
  }

  static String newClientRef() =>
      'delivery-${DateTime.now().microsecondsSinceEpoch}';
}
