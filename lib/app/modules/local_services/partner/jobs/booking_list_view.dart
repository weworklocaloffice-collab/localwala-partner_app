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

import 'package:flutter/material.dart';
import 'package:partner/app/core/config/api_request_service.dart';
import 'package:partner/app/modules/local_services/models/booking.dart';
import 'package:partner/app/modules/local_services/partner/jobs/booking_detail_view.dart';
import 'package:partner/app/modules/local_services/repository/provider_repository.dart';
import 'package:partner/gen/l10n/app_localizations.dart';

/// Provider job queue. Actions render from [LsBooking.actions] (display only —
/// the server allow-lists every transition and 403s foreign bookings).
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
          SnackBar(content: Text(AppLocalizations.of(context)?.ls_failed_error('$e') ?? 'Failed: $e'))
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
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(_error!),
            TextButton(onPressed: _load, child: Text(AppLocalizations.of(context)?.ls_retry ?? 'Retry')),
          ],
        ),
      );
    }
    if (_bookings.isEmpty) {
      return Center(child: Text(AppLocalizations.of(context)?.ls_no_jobs ?? 'No jobs yet'));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        itemCount: _bookings.length,
        itemBuilder: (BuildContext context, int i) {
          final LsBooking b = _bookings[i];
          return Card(
            child: ListTile(
              title: Text(b.code),
              subtitle: Text(
                '${b.status} · ${b.bookingMode} · ₹${b.labourAmount}',
              ),
              onTap: () => Navigator.of(context)
                  .push(
                    MaterialPageRoute<void>(
                      builder: (_) => BookingDetailScreen(bookingId: b.id),
                    ),
                  )
                  .then((_) => _load()),
              trailing: Wrap(
                spacing: 4,
                children: <Widget>[
                  for (final String a in b.actions)
                    _actingOn == b.id + a
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : TextButton(
                            onPressed: () => _act(b, a),
                            child: Text(a),
                          ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
