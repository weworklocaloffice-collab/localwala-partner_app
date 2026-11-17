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
import 'package:partner/app/modules/local_services/partner/shared/ls_ui.dart';
import 'package:partner/app/modules/local_services/models/provider.dart';
import 'package:partner/app/modules/local_services/repository/provider_repository.dart';
import 'package:partner/gen/l10n/app_localizations.dart';

class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  final LocalServicesProviderRepository _repository =
      LocalServicesProviderRepository();

  bool _loading = true;
  String? _error;
  List<dynamic> _reviews = <dynamic>[];

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
      final DioApiResponse providerResponse = await _repository.myProvider();
      final Map<String, dynamic> providerBody = decodeBody(providerResponse);
      final dynamic raw = providerBody['provider'];
      final String providerId = raw is Map<String, dynamic>
          ? LsProvider.fromJson(raw).id
          : '';
      if (providerId.isEmpty) {
        setState(() {
          _reviews = <dynamic>[];
          _loading = false;
        });
        return;
      }
      final DioApiResponse response = await _repository.reviews(providerId);
      final Map<String, dynamic> body = decodeBody(response);
      setState(() {
        _reviews = body['results'] ?? body['data'] ?? <dynamic>[];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  double get _average {
    if (_reviews.isEmpty) return 0;
    double total = 0;
    for (final dynamic raw in _reviews) {
      final Map<String, dynamic> review = (raw as Map).cast<String, dynamic>();
      total += double.tryParse('${review['rating'] ?? 0}') ?? 0;
    }
    return total / _reviews.length;
  }

  String _formatDate(dynamic value) {
    final DateTime? parsed = DateTime.tryParse('${value ?? ''}')?.toLocal();
    if (parsed == null) return '';
    final String month = parsed.month.toString().padLeft(2, '0');
    final String day = parsed.day.toString().padLeft(2, '0');
    return '${parsed.year}-$month-$day';
  }

  Widget _stars(int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 1; i <= 5; i++)
          Icon(
            i <= rating ? Icons.star : Icons.star_border,
            size: 18,
            color: Colors.amber,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.ls_reviews_title ?? 'Reviews'),
        actions: <Widget>[
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
            tooltip: l10n?.ls_refresh ?? 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
               ? LsErrorState(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
                    children: <Widget>[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: <Widget>[
                              Text(
                                _average.toStringAsFixed(1),
                                style: Theme.of(context)
                                    .textTheme
                                    .displaySmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    _stars(_average.round()),
                                    Text(
                                      '${_reviews.length} '
                                      '${l10n?.ls_reviews_title.toLowerCase() ?? 'reviews'}',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_reviews.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 48),
                          child: Column(
                            children: <Widget>[
                              const Icon(Icons.rate_review_outlined, size: 48),
                              const SizedBox(height: 12),
                              Text(l10n?.ls_no_reviews ?? 'No reviews yet'),
                            ],
                          ),
                        )
                      else
                        for (final dynamic raw in _reviews)
                          _reviewCard((raw as Map).cast<String, dynamic>()),
                    ],
                  ),
                ),
    );
  }

  Widget _reviewCard(Map<String, dynamic> review) {
    final int rating =
        (int.tryParse('${review['rating'] ?? 0}') ?? 1).clamp(1, 5).toInt();
    final String comment = '${review['comment'] ?? ''}'.trim();
    final String date = _formatDate(review['createdAt']);
    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                _stars(rating),
                const Spacer(),
                if (date.isNotEmpty)
                  Text(
                    date,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
            if (comment.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              Text(comment),
            ],
          ],
        ),
      ),
    );
  }
}
