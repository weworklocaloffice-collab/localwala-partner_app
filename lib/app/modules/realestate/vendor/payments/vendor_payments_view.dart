/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright Ac 2026 WeWorkLocal.
 * All Rights Reserved.
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:partner/app/modules/realestate/models/listing_order.dart';
import 'package:partner/app/modules/realestate/models/property.dart';
import 'package:partner/app/core/services/razorpay_payment_service.dart';
import 'package:partner/app/modules/realestate/vendor/payments/bloc/vendor_payments_bloc.dart';
import 'package:partner/app/presentation/styles/theme.dart';
import 'package:partner/gen/l10n/app_localizations.dart';

/// Payment history: package orders with status, pay and cancel.
///
/// A pending order can be settled after an app restart. Payment always goes
/// through the pay endpoint + `paid_success` verification, never the list.
class VendorPaymentsScreen extends StatefulWidget {
  const VendorPaymentsScreen({super.key});

  @override
  State<VendorPaymentsScreen> createState() => _VendorPaymentsScreenState();
}

class _VendorPaymentsScreenState extends State<VendorPaymentsScreen> {
  final RazorpayPaymentService _razorpay = RazorpayPaymentService();
  String? _openedPayLink;

  @override
  void dispose() {
    _razorpay.dispose();
    super.dispose();
  }

  void _onStateChanged(BuildContext context, VendorPaymentsState state) {
    final String? payLink = state.payLink;
    final Map<String, dynamic>? options = state.paymentOptions;
    if (payLink == null) {
      _openedPayLink = null;
      return;
    }
    if (options == null || payLink == _openedPayLink) return;
    _openedPayLink = payLink;

    _razorpay.open(
      options,
      onSuccess: (String? paymentId, String? orderId, String? signature) {
        if (!mounted) return;
        if (paymentId == null || orderId == null || signature == null) {
          context.read<VendorPaymentsBloc>().add(
            const VendorPaymentFailed('Payment confirmation is incomplete'),
          );
          return;
        }
        context.read<VendorPaymentsBloc>().add(
          VendorPaymentSucceeded(
            paymentId: paymentId,
            orderId: orderId,
            signature: signature,
          ),
        );
      },
      onFailure: (String message) {
        if (!mounted) return;
        context.read<VendorPaymentsBloc>().add(VendorPaymentFailed(message));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return BlocProvider<VendorPaymentsBloc>(
      create: (_) =>
          VendorPaymentsBloc()..add(const VendorPaymentsLoadRequested()),
      child: BlocConsumer<VendorPaymentsBloc, VendorPaymentsState>(
        listener: _onStateChanged,
        builder: (BuildContext context, VendorPaymentsState state) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.realEstateNavPayments)),
            body: Builder(
              builder: (BuildContext context) {
                switch (state.status) {
                  case VendorPaymentsStatus.initial:
                  case VendorPaymentsStatus.loading:
                    return const Center(child: CircularProgressIndicator());
                  case VendorPaymentsStatus.failure:
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            l10n.somethingWentWrong,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => context
                                .read<VendorPaymentsBloc>()
                                .add(const VendorPaymentsRefreshed()),
                            child: Text(l10n.retry),
                          ),
                        ],
                      ),
                    );
                  case VendorPaymentsStatus.loaded:
                    return _PaymentsBody(state: state, l10n: l10n);
                }
              },
            ),
          );
        },
      ),
    );
  }
}

class _PaymentsBody extends StatelessWidget {
  const _PaymentsBody({required this.state, required this.l10n});

  final VendorPaymentsState state;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final AppThemeData theme =
        appThemeData[Theme.of(context).brightness == Brightness.dark
            ? AppTheme.dark
            : AppTheme.light]!;

    return Column(
      children: <Widget>[
        if (state.paymentError.isNotEmpty)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).colorScheme.error),
            ),
            child: Text(
              state.paymentError,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        Expanded(
          child: state.orders.isEmpty
              ? Center(child: Text(l10n.realEstatePaymentsEmpty))
              : RefreshIndicator(
                  onRefresh: () async => context.read<VendorPaymentsBloc>().add(
                    const VendorPaymentsRefreshed(),
                  ),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.orders.length,
                    separatorBuilder: (BuildContext context, int index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (BuildContext context, int index) {
                      final RealEstateOrderModel order = state.orders[index];
                      final bool pending = order.status == 'PENDING_PAYMENT';
                      final bool paying = state.payingOrderId == order.id;
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: theme.cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.divider),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: Text(
                                    order.orderCode ?? order.id,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: theme.titleText,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ),
                                Text(
                                  order.amount != null
                                      ? '₹${formatIndianPrice(order.amount!)}'
                                      : '-',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(color: theme.titleText),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              order.status ?? '-',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: theme.bodyText),
                            ),
                            if (pending) ...<Widget>[
                              const SizedBox(height: 8),
                              Row(
                                children: <Widget>[
                                  FilledButton(
                                    onPressed: paying
                                        ? null
                                        : () => context
                                              .read<VendorPaymentsBloc>()
                                              .add(
                                                VendorPaymentPayRequested(
                                                  order.id,
                                                ),
                                              ),
                                    child: paying
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Text(l10n.realEstateCheckoutPayNow),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton(
                                    onPressed: paying
                                        ? null
                                        : () => context
                                              .read<VendorPaymentsBloc>()
                                              .add(
                                                VendorPaymentCancelRequested(
                                                  order.id,
                                                ),
                                              ),
                                    child: Text(l10n.realEstatePaymentsCancel),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}
