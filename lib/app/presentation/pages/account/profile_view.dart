/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright Â© 2026 WeWorkLocal.
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

import 'package:partner/app/core/config/api_request_service.dart';
import 'package:partner/app/core/models/user_session_model.dart';
import 'package:partner/app/core/repositories/auth_repository.dart';
import 'package:partner/app/core/repositories/partner_repository.dart';
import 'package:partner/app/core/services/razorpay_payment_service.dart';
import 'package:partner/app/presentation/styles/theme.dart';
import 'package:partner/app/presentation/styles/widgets.dart';
import 'package:partner/app/router/app_route_config.dart';
import 'package:partner/gen/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Profile, role visibility, and logout.
///
/// Riders need licence and FSSAI document visibility, and an owner-operator
/// needs to see both roles listed explicitly — the whole point of the merged
/// app is that one account can be both, and this screen is where that is
/// legible.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.session,
    this.partnerRepository,
  });

  final UserSessionModel session;
  final PartnerRepository? partnerRepository;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthRepository _authRepository = AuthRepository();
  final PartnerRepository _defaultPartnerRepository = PartnerRepository();
  final RazorpayPaymentService _razorpay = RazorpayPaymentService();
  Map<String, dynamic>? _businessProfile;
  bool _loggingOut = false;
  bool _payingJoiningFee = false;

  PartnerRepository get _partnerRepository =>
      widget.partnerRepository ?? _defaultPartnerRepository;

  @override
  void initState() {
    super.initState();
    _loadBusinessProfile();
  }

  @override
  void dispose() {
    _razorpay.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session.business != widget.session.business ||
        oldWidget.session.activeRole != widget.session.activeRole) {
      _businessProfile = null;
      _loadBusinessProfile();
    }
  }

  Future<void> _loadBusinessProfile() async {
    final UserSessionModel session = widget.session;
    final String? businessId = session.business;
    if (session.activeRole != DairyAppRole.partner ||
        businessId == null ||
        businessId.isEmpty) {
      return;
    }

    try {
      final DioApiResponse response =
          await _partnerRepository.partnerBusinessProfile();
      if (!mounted ||
          widget.session.activeRole != DairyAppRole.partner ||
          widget.session.business != businessId ||
          response.errorType != NetErrorType.none) {
        return;
      }
      final Map<String, dynamic> body = decodeBody(response);
      final dynamic data = body['profile'];
      final Map<String, dynamic> profile = data is Map
          ? Map<String, dynamic>.from(data)
          : body;
      if (profile.isNotEmpty) {
        setState(() => _businessProfile = profile);
      }
    } catch (_) {
      // Keep the signed-in account details visible if public outlet data is down.
    }
  }

  Future<void> _payJoiningFee() async {
    if (_payingJoiningFee) return;
    setState(() => _payingJoiningFee = true);
    try {
      final DioApiResponse initiation =
          await _partnerRepository.payFranchiseJoiningFee();
      final Map<String, dynamic> initiationBody = decodeBody(initiation);
      if (initiation.errorType != NetErrorType.none) {
        throw StateError(
          initiationBody['message']?.toString() ??
              'Could not start the joining-fee payment.',
        );
      }
      final String payLink = initiationBody['payLink']?.toString() ?? '';
      if (payLink.isEmpty) throw StateError('Payment reference was not returned.');

      final DioApiResponse orderResponse =
          await _partnerRepository.franchiseJoiningFeePaymentOrder(payLink);
      final Map<String, dynamic> order = decodeBody(orderResponse);
      if (orderResponse.errorType != NetErrorType.none ||
          order['success'] != true ||
          order['key'] == null ||
          order['order_id'] == null) {
        throw StateError(
          order['message']?.toString() ?? 'Payment gateway is unavailable.',
        );
      }

      _razorpay.open(
        <String, dynamic>{
          'key': order['key'],
          'amount': order['amount'],
          'order_id': order['order_id'],
          'name': order['name'] ?? 'LocalWala Dairy franchise',
          'description': 'Franchise joining fee',
          'prefill': order['prefill'] ?? <String, dynamic>{},
        },
        onSuccess: (String? paymentId, String? orderId, String? signature) async {
          if (!mounted) return;
          if (paymentId == null || orderId == null || signature == null) {
            _showMessage('Payment confirmation was incomplete. Refresh payment status.');
            return;
          }
          final DioApiResponse verified =
              await _partnerRepository.verifyFranchiseJoiningFeePayment(
            payLink,
            paymentId: paymentId,
            orderId: orderId,
            signature: signature,
          );
          if (!mounted) return;
          final Map<String, dynamic> verifiedBody = decodeBody(verified);
          if (verified.errorType == NetErrorType.none &&
              verifiedBody['success'] == true) {
            _showMessage('Joining fee paid. Your franchise agreement is active.');
            await _loadBusinessProfile();
          } else {
            _showMessage(
              verifiedBody['message']?.toString() ??
                  'Payment is being verified. Refresh shortly.',
            );
          }
          if (mounted) setState(() => _payingJoiningFee = false);
        },
        onFailure: (String message) {
          _showMessage(message);
          if (mounted) setState(() => _payingJoiningFee = false);
        },
      );
    } catch (error) {
      _showMessage(error.toString().replaceFirst('Bad state: ', ''));
      if (mounted) setState(() => _payingJoiningFee = false);
    }
  }

  void _showMessage(String value) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
    }
  }

  Future<void> _confirmLogout() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(AppLocalizations.of(dialogContext)!.logout),
        content: const Text('Queued scans that have not synced will be lost.'),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Logout')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _loggingOut = true);
    await _authRepository.logout();
    if (!mounted) return;
    AppRouter.pushNamedAndRemoveAll(context, AppRouter.loginRoute);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final AppThemeData theme = appThemeData[Theme.of(context).brightness == Brightness.dark ? AppTheme.dark : AppTheme.light]!;
    final UserSessionModel session = widget.session;

    if (session.activeRole == DairyAppRole.partner) {
      return _buildPartnerProfile(
        context,
        session,
        theme,
        l10n,
        _businessProfile,
      );
    }

    return _buildStandardProfile(context, session, theme, l10n);
  }

  Widget _buildPartnerProfile(
    BuildContext context,
    UserSessionModel session,
    AppThemeData theme,
    AppLocalizations l10n,
    Map<String, dynamic>? business,
  ) {
    final String accountOwner = '${session.firstName} ${session.lastName}'.trim();
    final String businessName = business?['name']?.toString().trim() ?? '';
    final String displayName = businessName.isNotEmpty
        ? businessName
        : accountOwner.isEmpty
        ? l10n.partnerShell
        : accountOwner;
    final String businessId = session.business?.trim() ?? '';
    final String? modelValue = business?['businessModel']?.toString();
    final String businessModel = (modelValue == null || modelValue.isEmpty
            ? 'Agreement pending'
            : modelValue)
        .toString()
        .replaceAll('_', ' ')
        .split(' ')
        .map((String word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
    final String locality = _placeName(business?['locality']);
    final String city = _placeName(business?['city']);
    final String serviceArea = <String>[locality, city]
        .where((String value) => value.isNotEmpty)
        .join(', ');
    final String phone = session.mobile == null || session.mobile!.isEmpty
        ? 'Not provided'
        : '+${session.countryCode ?? ''} ${session.mobile}'.trim();
    final String email = session.email?.trim().isNotEmpty == true
        ? session.email!.trim()
        : 'Not provided';

    return Scaffold(
      appBar: AppBar(title: const Text('Business profile')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: <Widget>[
            _partnerProfileHero(context, displayName, theme),
            const SizedBox(height: 24),
            _sectionHeading(context, 'Business workspace', theme),
            _profileCard(
              theme,
              <Widget>[
                _detailRow(
                  context,
                  icon: Icons.corporate_fare_outlined,
                  title: 'Business model',
                  value: businessModel,
                ),
                if ((business?['requestedBusinessModel'] ?? '').toString().isNotEmpty) ...<Widget>[
                  Divider(height: 1, indent: 56, color: theme.divider),
                  _detailRow(
                    context,
                    icon: Icons.assignment_outlined,
                    title: 'Requested partnership model',
                    value: business!['requestedBusinessModel'].toString()
                        .replaceAll('_', ' ')
                        .split(' ')
                        .map((String word) => word.isEmpty
                            ? word
                            : '${word[0].toUpperCase()}${word.substring(1)}')
                        .join(' '),
                  ),
                ],
                if ((business?['applicationStatus'] ?? '').toString().isNotEmpty) ...<Widget>[
                  Divider(height: 1, indent: 56, color: theme.divider),
                  _detailRow(
                    context,
                    icon: Icons.fact_check_outlined,
                    title: 'Application review',
                    value: business!['applicationStatus'].toString(),
                  ),
                ],
                if ((business?['agreementStatus'] ?? '').toString().isNotEmpty) ...<Widget>[
                  Divider(height: 1, indent: 56, color: theme.divider),
                  _detailRow(
                    context,
                    icon: Icons.description_outlined,
                    title: 'Commercial agreement',
                    value: business!['agreementStatus'].toString(),
                  ),
                ],
                if (serviceArea.isNotEmpty) ...<Widget>[
                  Divider(height: 1, indent: 56, color: theme.divider),
                  _detailRow(
                    context,
                    icon: Icons.location_on_outlined,
                    title: 'Service area',
                    value: serviceArea,
                  ),
                ],
                if (business?['verified'] is bool) ...<Widget>[
                  Divider(height: 1, indent: 56, color: theme.divider),
                  _detailRow(
                    context,
                    icon: business?['verified'] == true
                        ? Icons.verified_outlined
                        : Icons.pending_outlined,
                    title: 'Outlet verification',
                    value: business?['verified'] == true
                        ? 'Verified'
                        : 'Verification pending',
                  ),
                ],
                if (businessId.isNotEmpty) ...<Widget>[
                  Divider(height: 1, indent: 56, color: theme.divider),
                  ListTile(
                    dense: true,
                    leading: Icon(Icons.fingerprint, color: theme.primary),
                    title: const Text('Outlet reference'),
                    subtitle: Text(
                      businessId,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      tooltip: 'Copy business reference',
                      icon: const Icon(Icons.copy_outlined),
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: businessId));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Business reference copied')),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ],
            ),
            if (business?['businessModel']?.toString() == 'franchise' &&
                (double.tryParse(business?['joiningFee']?.toString() ?? '') ?? 0) > 0) ...<Widget>[
              const SizedBox(height: 20),
              _sectionHeading(context, 'Franchise joining fee', theme),
              _profileCard(theme, <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    business?['joiningFeePaymentStatus']?.toString() == 'paid'
                        ? 'Payment has been verified and the franchise agreement is active.'
                        : business?['joiningFeePaymentStatus']?.toString() == 'waived'
                            ? 'The platform waived this joining fee.'
                            : 'The agreed upfront joining fee must be paid before this franchise can trade.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                ListTile(
                  leading: Icon(
                    business?['joiningFeePaymentStatus']?.toString() == 'paid' ||
                            business?['joiningFeePaymentStatus']?.toString() == 'waived'
                        ? Icons.verified_outlined
                        : Icons.payments_outlined,
                    color: theme.primary,
                  ),
                  title: const Text('Joining fee'),
                  subtitle: Text(
                    '₹${(double.tryParse(business?['joiningFee']?.toString() ?? '') ?? 0).toStringAsFixed(2)} · ${_joiningFeeStatus(business?['joiningFeePaymentStatus']?.toString())}',
                  ),
                ),
                if (business?['joiningFeePaymentStatus']?.toString() == 'paid') ...<Widget>[
                  if (business?['joiningFeePaidAt'] != null)
                    _detailRow(
                      context,
                      icon: Icons.event_available_outlined,
                      title: 'Paid on',
                      value: _dateLabel(business?['joiningFeePaidAt']),
                    ),
                  if ((business?['joiningFeePaymentReference'] ?? '').toString().isNotEmpty)
                    _detailRow(
                      context,
                      icon: Icons.receipt_long_outlined,
                      title: 'Payment reference',
                      value: business!['joiningFeePaymentReference'].toString(),
                    ),
                ] else if (business?['joiningFeePaymentStatus']?.toString() != 'waived')
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _payingJoiningFee ? null : _payJoiningFee,
                        icon: _payingJoiningFee
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.lock_open_outlined),
                        label: Text(_payingJoiningFee ? 'Opening secure checkout…' : 'Pay joining fee'),
                      ),
                    ),
                  ),
              ]),
            ],
            const SizedBox(height: 20),
            _sectionHeading(context, 'Account contact', theme),
            _profileCard(
              theme,
              <Widget>[
                _detailRow(
                  context,
                  icon: Icons.person_outline,
                  title: 'Account owner',
                  value: accountOwner.isEmpty ? 'Not provided' : accountOwner,
                ),
                Divider(height: 1, indent: 56, color: theme.divider),
                _detailRow(
                  context,
                  icon: Icons.phone_outlined,
                  title: 'Phone number',
                  value: phone,
                ),
                Divider(height: 1, indent: 56, color: theme.divider),
                _detailRow(
                  context,
                  icon: Icons.mail_outline,
                  title: 'Email address',
                  value: email,
                ),
              ],
            ),
            const SizedBox(height: 20),
            _sectionHeading(context, 'Workspace access', theme),
            _profileCard(
              theme,
              <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Roles available to this account',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: session.availableRoles.map((DairyAppRole role) {
                      final bool active = role == session.activeRole;
                      final String label = switch (role) {
                        DairyAppRole.partner => l10n.partnerShell,
                        DairyAppRole.driver => l10n.deliveryShell,
                        _ => role.label,
                      };
                      return Chip(
                        avatar: Icon(
                          role == DairyAppRole.driver || role == DairyAppRole.storeDriver
                              ? Icons.local_shipping_outlined
                              : Icons.storefront_outlined,
                          size: 18,
                          color: active ? theme.primary : AppColors.grey,
                        ),
                        label: Text(label),
                        side: BorderSide(
                          color: active ? theme.primary : theme.divider,
                        ),
                        backgroundColor: active
                            ? theme.primary.withValues(alpha: 0.08)
                            : theme.cardBg,
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _sectionHeading(context, 'Delivery configuration', theme),
            _profileCard(
              theme,
              <Widget>[
                _detailRow(
                  context,
                  icon: session.ownDeliveryPartner
                      ? Icons.local_shipping_outlined
                      : Icons.delivery_dining_outlined,
                  title: 'Fulfilment model',
                  value: session.ownDeliveryPartner
                      ? 'In-house delivery fleet'
                      : 'Platform delivery fleet',
                ),
                Divider(height: 1, indent: 56, color: theme.divider),
                _detailRow(
                  context,
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'Driver payout responsibility',
                  value: (session.driverPayoutMode ?? 'business_pays')
                      .replaceAll('_', ' ')
                      .split(' ')
                      .map((String word) => word.isEmpty
                          ? word
                          : '${word[0].toUpperCase()}${word.substring(1)}')
                      .join(' '),
                ),
              ],
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _loggingOut ? null : _confirmLogout,
              icon: const Icon(Icons.logout),
              label: Text(l10n.logout),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.expired,
                minimumSize: const Size.fromHeight(50),
                side: BorderSide(color: AppColors.expired.withValues(alpha: 0.45)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _partnerProfileHero(
    BuildContext context,
    String displayName,
    AppThemeData theme,
  ) {
    final List<String> initials = displayName
        .split(RegExp(r'\s+'))
        .where((String part) => part.isNotEmpty)
        .take(2)
        .map((String part) => part[0].toUpperCase())
        .toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[theme.primary, theme.primary.withValues(alpha: 0.78)],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: theme.primary.withValues(alpha: 0.18),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white.withValues(alpha: 0.18),
            child: Text(
              initials.isEmpty ? 'D' : initials.join(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'DAIRY OPERATIONS',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  displayName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: const Text(
                    'PARTNER ACCOUNT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _placeName(dynamic place) {
    if (place is Map) return place['name']?.toString() ?? '';
    return place?.toString() ?? '';
  }

  String _joiningFeeStatus(String? status) => switch (status) {
        'paid' => 'Paid',
        'waived' => 'Waived',
        'initiated' => 'Payment started',
        'failed' => 'Payment failed',
        _ => 'Due',
      };

  String _dateLabel(dynamic value) {
    final DateTime? parsed = value is DateTime
        ? value
        : DateTime.tryParse(value?.toString() ?? '');
    if (parsed == null) return '—';
    final DateTime date = parsed.toLocal();
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  Widget _sectionHeading(
    BuildContext context,
    String title,
    AppThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 2),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: theme.titleText,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _profileCard(AppThemeData theme, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.divider),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }

  Widget _detailRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
  }) {
    final AppThemeData theme = appThemeData[
      Theme.of(context).brightness == Brightness.dark ? AppTheme.dark : AppTheme.light
    ]!;
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(icon, color: theme.primary),
      title: Text(title, style: Theme.of(context).textTheme.bodySmall),
      subtitle: Text(
        value,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: theme.titleText,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStandardProfile(
    BuildContext context,
    UserSessionModel session,
    AppThemeData theme,
    AppLocalizations l10n,
  ) {

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navAccount)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[theme.primary, theme.primary.withValues(alpha: 0.7)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: theme.primary.withValues(alpha: 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: <Widget>[
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: Text(
                      session.firstName.isEmpty ? '?' : session.firstName[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          '${session.firstName} ${session.lastName}'.trim(),
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          session.mobile == null ? (session.email ?? '') : '+${session.countryCode ?? ''}${session.mobile}',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: CircleAvatar(
                radius: 24,
                child: Text(session.firstName.isEmpty ? '?' : session.firstName[0]),
              ),
              title: Text('${session.firstName} ${session.lastName}'.trim()),
              subtitle: Text(session.mobile == null ? (session.email ?? '') : '+${session.countryCode ?? ''}${session.mobile}'),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(l10n.activeRole, style: Theme.of(context).textTheme.bodySmall),
          ),
          Card(
            child: Column(
              children: session.availableRoles
                  .map(
                    (DairyAppRole role) => ListTile(
                      dense: true,
                      leading: Icon(
                        role == DairyAppRole.partner
                            ? Icons.storefront_outlined
                            : role == DairyAppRole.driver ||
                                      role == DairyAppRole.jhatkaDriver ||
                                      role == DairyAppRole.storeDriver
                                ? Icons.pedal_bike_outlined
                                : Icons.handyman_outlined,
                        color: role == session.activeRole ? theme.primary : AppColors.grey,
                      ),
                      title: Text(
                        role == DairyAppRole.partner
                            ? l10n.partnerShell
                            : role == DairyAppRole.driver ||
                                      role == DairyAppRole.jhatkaDriver ||
                                      role == DairyAppRole.storeDriver
                                ? l10n.deliveryShell
                                : role.label,
                      ),
                      trailing: role == session.activeRole
                          ? Icon(Icons.check_circle, color: theme.primary)
                          : null,
                    ),
                  )
                  .toList(),
            ),
          ),

          if (session.isDriver) ...<Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text('Delivery', style: Theme.of(context).textTheme.bodySmall),
            ),
            Card(
              child: Column(
                children: <Widget>[
                  ListTile(
                    dense: true,
                    title: const Text('Agent source'),
                    trailing: StatusChip(
                      label: session.agentMode == DairyAgentMode.ownFleet ? 'Own fleet' : 'Platform pool',
                      color: session.agentMode == DairyAgentMode.ownFleet
                          ? theme.primary
                          : AppColors.canWithAgent,
                    ),
                  ),
                  ListTile(
                    dense: true,
                    title: const Text('Driver payout'),
                    trailing: Text(
                      (session.driverPayoutMode ?? 'business_pays').replaceAll('_', ' '),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),
          Card(
            child: Column(
              children: <Widget>[
                if (session.isDriver)
                  ListTile(
                    leading: Icon(Icons.badge_outlined, color: theme.primary),
                    title: const Text('Licence & FSSAI documents'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Document upload arrives with the compliance slice')),
                    ),
                  ),
                ListTile(
                  leading: Icon(Icons.support_agent_outlined, color: theme.primary),
                  title: const Text('Support'),
                  trailing: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              onPressed: _loggingOut ? null : _confirmLogout,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.expired),
              icon: const Icon(Icons.logout),
              label: Text(l10n.logout),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
