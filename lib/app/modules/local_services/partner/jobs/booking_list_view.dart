import 'package:flutter/material.dart';
import 'package:partner/app/core/config/api_request_service.dart';
import 'package:partner/app/modules/local_services/models/booking.dart';
import 'package:partner/app/modules/local_services/partner/jobs/booking_detail_view.dart';
import 'package:partner/app/modules/local_services/partner/shared/ls_ui.dart';
import 'package:partner/app/modules/local_services/repository/provider_repository.dart';
import 'package:partner/gen/l10n/app_localizations.dart';

class BookingListScreen extends StatefulWidget {
  const BookingListScreen({super.key});

  @override
  State<BookingListScreen> createState() => _BookingListScreenState();
}

class _BookingListScreenState extends State<BookingListScreen> {
  final LocalServicesProviderRepository _repository =
      LocalServicesProviderRepository();

  bool _loading = true;
  String? _error;
  List<LsBooking> _bookings = const <LsBooking>[];
  String? _actingOn;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final DioApiResponse response = await _repository.bookings();
      final Map<String, dynamic> body = decodeBody(response);
      final List<dynamic> raw =
          (body['results'] ?? body['data'] ?? []) as List<dynamic>;
      setState(() {
        _bookings = raw
            .whereType<Map<String, dynamic>>()
            .map(LsBooking.fromJson)
            .toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Future<void> _act(LsBooking booking, String status) async {
    setState(() => _actingOn = booking.id + status);
    try {
      await _repository.transitionBooking(booking.id, status);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)?.ls_failed_error('$e') ?? 'Failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _actingOn = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return LsErrorState(message: _error!, onRetry: _load);
    }
    if (_bookings.isEmpty) {
      return LsEmptyState(
        icon: Icons.work_outline,
        title: AppLocalizations.of(context)?.ls_no_jobs ?? 'No jobs yet',
        subtitle: 'New bookings will appear here.',
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _bookings.length,
        itemBuilder: (BuildContext context, int i) {
          final LsBooking b = _bookings[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => Navigator.of(context)
                  .push(
                    MaterialPageRoute<void>(
                      builder: (_) => BookingDetailScreen(bookingId: b.id),
                    ),
                  )
                  .then((_) => _load()),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            b.code,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                        ),
                        LsStatusBadge(status: b.status),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${b.bookingMode} · ₹${b.labourAmount}',
                      style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
                    ),
                    if (b.actions.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        children: <Widget>[
                          for (final String a in b.actions)
                            _actingOn == b.id + a
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : FilledButton.tonal(
                                    onPressed: () => _act(b, a),
                                    style: FilledButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      textStyle: const TextStyle(fontSize: 12),
                                    ),
                                    child: Text(a),
                                  ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
