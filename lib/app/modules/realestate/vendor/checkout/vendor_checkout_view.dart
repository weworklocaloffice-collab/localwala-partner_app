/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright Ac 2026 WeWorkLocal.
 * All Rights Reserved.
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:partner/app/modules/realestate/models/listing_package.dart';
import 'package:partner/app/modules/realestate/models/property.dart';
import 'package:partner/app/core/services/razorpay_payment_service.dart';
import 'package:partner/app/modules/realestate/vendor/checkout/bloc/vendor_checkout_bloc.dart';
import 'package:partner/app/presentation/styles/theme.dart';
import 'package:partner/gen/l10n/app_localizations.dart';

/// Package checkout: confirm the catalogue row, purchase, then pay.
///
/// The order is created before the gateway sheet (amount from the server).
/// Success is only shown after `paid_success` verifies the HMAC - the native
/// callback alone never grants the entitlement.
class VendorCheckoutScreen extends StatefulWidget {
  const VendorCheckoutScreen({super.key, required this.packageCode});

  final String packageCode;

  @override
  State<VendorCheckoutScreen> createState() => _VendorCheckoutScreenState();
}

class _VendorCheckoutScreenState extends State<VendorCheckoutScreen> {
  final RazorpayPaymentService _razorpay = RazorpayPaymentService();
  String? _openedPayLink;

  @override
  void dispose() {
    _razorpay.dispose();
    super.dispose();
  }

  void _onStateChanged(BuildContext context, VendorCheckoutState state) {
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
          context.read<VendorCheckoutBloc>().add(
            const VendorCheckoutPaymentFailed(
              'Payment confirmation is incomplete',
            ),
          );
          return;
        }
        context.read<VendorCheckoutBloc>().add(
          VendorCheckoutPaymentSucceeded(
            paymentId: paymentId,
            orderId: orderId,
            signature: signature,
          ),
        );
      },
      onFailure: (String message) {
        if (!mounted) return;
        context.read<VendorCheckoutBloc>().add(
          VendorCheckoutPaymentFailed(message),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return BlocProvider<VendorCheckoutBloc>(
      create: (_) =>
          VendorCheckoutBloc()..add(VendorCheckoutStarted(widget.packageCode)),
      child: BlocConsumer<VendorCheckoutBloc, VendorCheckoutState>(
        listener: _onStateChanged,
        builder: (BuildContext context, VendorCheckoutState state) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.realEstateCheckoutTitle)),
            body: switch (state.status) {
              VendorCheckoutStatus.initial ||
              VendorCheckoutStatus.loading ||
              VendorCheckoutStatus.confirming => const Center(
                child: CircularProgressIndicator(),
              ),
              VendorCheckoutStatus.paying => const _CheckoutProgress(
                label: 'Preparing payment...',
              ),
              VendorCheckoutStatus.verifying => const _CheckoutProgress(
                label: 'Verifying payment...',
              ),
              VendorCheckoutStatus.failure => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      state.message,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => context.read<VendorCheckoutBloc>().add(
                        VendorCheckoutStarted(widget.packageCode),
                      ),
                      child: Text(l10n.retry),
                    ),
                  ],
                ),
              ),
              VendorCheckoutStatus.done => _CheckoutBody(
                state: state,
                l10n: l10n,
                onPay: () => context.read<VendorCheckoutBloc>().add(
                  const VendorCheckoutPayRequested(),
                ),
                onDone: () => Navigator.of(context).pop(true),
              ),
            },
          );
        },
      ),
    );
  }
}

class _CheckoutProgress extends StatelessWidget {
  const _CheckoutProgress({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _CheckoutBody extends StatelessWidget {
  const _CheckoutBody({
    required this.state,
    required this.l10n,
    required this.onPay,
    required this.onDone,
  });

  final VendorCheckoutState state;
  final AppLocalizations l10n;
  final VoidCallback onPay;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final AppThemeData theme =
        appThemeData[Theme.of(context).brightness == Brightness.dark
            ? AppTheme.dark
            : AppTheme.light]!;
    final RealEstatePackageModel? package = state.package;

    if (state.order != null) {
      final bool paid = state.order!.status == 'PAID';
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Icon(
              paid ? Icons.check_circle_outline : Icons.schedule,
              size: 64,
              color: paid ? theme.primary : theme.bodyText,
            ),
            const SizedBox(height: 16),
            Text(
              paid
                  ? l10n.realEstateCheckoutPaid
                  : l10n.realEstateCheckoutOrderPlaced,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: theme.titleText),
            ),
            const SizedBox(height: 8),
            Text(
              state.order!.orderCode ?? state.order!.id,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: theme.bodyText),
            ),
            const SizedBox(height: 8),
            Text(
              '${l10n.realEstateCheckoutStatus}: ${state.order!.status ?? '-'}',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: theme.bodyText),
            ),
            if (!paid) ...<Widget>[
              const SizedBox(height: 12),
              Text(
                l10n.realEstateCheckoutPending,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: theme.bodyText),
              ),
            ],
            if (state.paymentError.isNotEmpty) ...<Widget>[
              const SizedBox(height: 12),
              Text(
                state.paymentError,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 24),
            if (!paid)
              FilledButton(
                onPressed: onPay,
                child: Text(l10n.realEstateCheckoutPayNow),
              ),
            if (!paid) const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: onDone,
              child: Text(l10n.realEstateCheckoutDone),
            ),
          ],
        ),
      );
    }

    if (package == null) {
      return Center(child: Text(l10n.somethingWentWrong));
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            package.name ?? package.code ?? '-',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: theme.titleText,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            package.price != null
                ? '₹${formatIndianPrice(package.price!)}'
                : '-',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: theme.titleText),
          ),
          const SizedBox(height: 8),
          Text(
            package.description ?? '',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: theme.bodyText),
          ),
          const Spacer(),
          FilledButton(
            onPressed: () => context.read<VendorCheckoutBloc>().add(
              const VendorCheckoutConfirmed(),
            ),
            child: Text(l10n.realEstateCheckoutConfirm),
          ),
        ],
      ),
    );
  }
}
