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
import 'package:partner/app/core/repositories/partner_repository.dart';
import 'package:partner/app/presentation/styles/theme.dart';
import 'package:partner/app/presentation/styles/widgets.dart';
import 'package:partner/gen/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Own-fleet riders for this outlet.
///
/// Backed by `GET /partner/drivers/list`, which returns only riders whose
/// `DairyDriver.business` is this outlet. Platform-pool riders have no business
/// and are not listed — they belong to whoever dispatches them, so showing them
/// here would imply the partner can manage them.
///
/// Inviting, approving, blocking, removing and paying are wired to
/// `/partner/drivers/...`. An invitation is a phone number: the rider joins when
/// they register with it, which is what proves the invitation was genuine rather
/// than a partner typing in a stranger.
class PartnerDriverListScreen extends StatefulWidget {
  const PartnerDriverListScreen({super.key, this.repository});

  final PartnerRepository? repository;

  @override
  State<PartnerDriverListScreen> createState() =>
      _PartnerDriverListScreenState();
}

class _PartnerDriverListScreenState extends State<PartnerDriverListScreen> {
  late final PartnerRepository _partnerRepository;

  bool _loading = true;
  String? _error;
  List<dynamic> _drivers = const <dynamic>[];
  List<dynamic> _invites = const <dynamic>[];

  /// The rider currently mid-action, so only their row shows a spinner.
  String? _actingOn;

  @override
  void initState() {
    super.initState();
    _partnerRepository = widget.repository ?? PartnerRepository();
    _load();
  }
Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final DioApiResponse response = await _partnerRepository.drivers();
    // Pending invitations are shown alongside the roster: a partner who has
    // invited someone and sees no rider is otherwise left thinking it failed.
    final DioApiResponse invites = await _partnerRepository.driverInvites();

    if (!mounted) return;

    if (response.errorType != NetErrorType.none) {
      setState(() {
        _loading = false;
        _error = AppLocalizations.of(context)!.couldNotLoadRiders;
      });
      return;
    }

    final Map<String, dynamic> body = decodeBody(response);
    setState(() {
      _loading = false;
      _drivers = (body['drivers'] as List?) ?? const <dynamic>[];
      _invites =
          invites.errorType == NetErrorType.none
              ? ((decodeBody(invites)['invites'] as List?) ?? const <dynamic>[])
              : const <dynamic>[];
    });
  }

  /// Runs a fleet action, then reloads so the row reflects what the API decided.
  Future<void> _act(Future<DioApiResponse> Function() action, String label) async {
    setState(() => _actingOn = label);
    final DioApiResponse response = await action();

    if (!mounted) return;
    setState(() => _actingOn = null);

    if (response.errorType == NetErrorType.none) {
      await _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.couldNotCompleteAction)),
      );
    }
  }

  Future<void> _promptCreateDriver() async {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final TextEditingController firstNameController = TextEditingController();
    final TextEditingController lastNameController = TextEditingController();
    final TextEditingController emailController = TextEditingController();
    final TextEditingController mobileController = TextEditingController();
    String vehicleType = 'cycle';
    final Map<String, String>? details = await showDialog<Map<String, String>>(
      context: context,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setDialogState) => AlertDialog(
          title: const Text('Create driver account'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: firstNameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'First name'),
                ),
                TextField(
                  controller: lastNameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Last name'),
                ),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                TextField(
                  controller: mobileController,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  decoration: InputDecoration(
                    labelText: l10n.mobileNumber,
                    hintText: l10n.tenDigitNumber,
                    prefixText: '+91 ',
                  ),
                ),
                DropdownButtonFormField<String>(
                  initialValue: vehicleType,
                  decoration: const InputDecoration(labelText: 'Vehicle type'),
                  items: const <DropdownMenuItem<String>>[
                    DropdownMenuItem(value: 'cycle', child: Text('Bicycle')),
                    DropdownMenuItem(value: 'on_foot', child: Text('On foot')),
                    DropdownMenuItem(value: 'bike', child: Text('Motorbike')),
                    DropdownMenuItem(value: 'mini_truck', child: Text('Mini truck')),
                  ],
                  onChanged: (String? value) {
                    if (value != null) setDialogState(() => vehicleType = value);
                  },
                ),
                const SizedBox(height: 8),
                const Text(
                  'The driver will verify this phone and set their own password before the account can be approved.',
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(<String, String>{
                'firstName': firstNameController.text.trim(),
                'lastName': lastNameController.text.trim(),
                'email': emailController.text.trim(),
                'mobile': mobileController.text.trim(),
                'vehicleType': vehicleType,
              }),
              child: const Text('Create account'),
            ),
          ],
        ),
      ),
    );

    final String mobile = details?['mobile'] ?? '';
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    mobileController.dispose();
    if (details == null || !mounted) return;
    if (details['firstName']!.isEmpty || details['lastName']!.isEmpty ||
        !details['email']!.contains('@') || mobile.length != 10 ||
        int.tryParse(mobile) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mobile.length != 10 || int.tryParse(mobile) == null
            ? l10n.invalidMobile
            : 'Enter the driver name and a valid email address.')),
      );
      return;
    }
    await _createAndShare(details);
  }

  Future<void> _createAndShare(Map<String, String> details) async {
    setState(() => _actingOn = 'create');
    final DioApiResponse response = await _partnerRepository.createDriverAccount(
      <String, dynamic>{
        ...details,
        'mobile': int.parse(details['mobile']!),
        'countryCode': '+91',
      },
    );
    if (!mounted) return;
    setState(() => _actingOn = null);

    if (response.errorType != NetErrorType.none) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.couldNotCompleteAction)),
      );
      return;
    }

    final Map<String, dynamic> body = decodeBody(response);
    await _load();
    if (!mounted) return;
    final String code = body['inviteCode']?.toString() ?? '';
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Driver account is already awaiting activation.')),
      );
      return;
    }
    await _showInviteShare(
      details['mobile']!,
      code,
      body['businessName']?.toString() ?? 'your dairy outlet',
      driverName: '${details['firstName']} ${details['lastName']}',
    );
  }

  Future<void> _inviteAndShare(String mobile) async {
    setState(() => _actingOn = 'invite');
    final DioApiResponse response = await _partnerRepository.inviteDriver(
      int.parse(mobile),
      '+91',
    );
    if (!mounted) return;
    setState(() => _actingOn = null);

    if (response.errorType != NetErrorType.none) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.couldNotCompleteAction)),
      );
      return;
    }

    final Map<String, dynamic> body = decodeBody(response);
    await _load();
    if (!mounted) return;

    final String code = body['inviteCode']?.toString() ?? '';
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Driver account linked. Approve the driver from the roster after reviewing their details.'),
        ),
      );
      return;
    }
    await _showInviteShare(mobile, code, body['businessName']?.toString() ?? 'your dairy outlet');
  }

  Future<void> _showInviteShare(
    String mobile,
    String code,
    String outletName, {
    String? driverName,
  }) async {
    final String inviteLink = Uri(
      scheme: 'localwala',
      host: 'register',
      queryParameters: <String, String>{
        'role': 'dairyDriver',
        'mobile': mobile,
        'invite': code,
      },
    ).toString();
    final String message =
        '${driverName == null ? 'You are invited' : 'Hi $driverName, your driver account has been created'} '
        'for $outletName on LocalWala Dairy. '
        'Open this link on a device with the LocalWala Partner app: $inviteLink '
        'Verify the invited phone by OTP, choose your password, and enter activation code: $code. '
        'Delivery access starts after the outlet approves your profile.';

    final String? channel = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Invitation created'),
        content: SelectableText(
          'Send this one-time activation code only to the driver. It expires in 14 days.\n\n$message',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
          TextButton.icon(
            onPressed: () => Navigator.of(dialogContext).pop('sms'),
            icon: const Icon(Icons.sms_outlined),
            label: const Text('SMS'),
          ),
          TextButton.icon(
            onPressed: () => Navigator.of(dialogContext).pop('whatsapp'),
            icon: const Icon(Icons.send_outlined),
            label: const Text('WhatsApp'),
          ),
        ],
      ),
    );

    if (channel == null || !mounted) return;
    final Uri target = channel == 'sms'
        ? Uri(scheme: 'sms', path: mobile, queryParameters: <String, String>{'body': message})
        : Uri.https('wa.me', '91$mobile', <String, String>{'text': message});
    try {
      final bool launched = await launchUrl(target, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the messaging app. Copy the invitation code and send it to the driver.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the messaging app. Copy the invitation code and send it to the driver.')),
        );
      }
    }
  }

  Future<void> _reissueAndShare(String inviteId, String mobile, String driverName) async {
    setState(() => _actingOn = 'reissue:$inviteId');
    final DioApiResponse response = await _partnerRepository.reissueDriverActivation(inviteId);
    if (!mounted) return;
    setState(() => _actingOn = null);
    if (response.errorType != NetErrorType.none) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.couldNotCompleteAction)),
      );
      return;
    }
    final Map<String, dynamic> body = decodeBody(response);
    await _load();
    if (!mounted) return;
    final String code = body['inviteCode']?.toString() ?? '';
    if (code.isNotEmpty) {
      await _showInviteShare(
        mobile,
        code,
        body['businessName']?.toString() ?? 'your dairy outlet',
        driverName: driverName,
      );
    }
  }

  Future<void> _promptPayout(Map<String, dynamic> driver, String name) async {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final TextEditingController controller = TextEditingController();
    final String? amount = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text('${l10n.payAction} $name'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: '${l10n.amount} (₹)'),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: Text(l10n.payAction),
          ),
        ],
      ),
    );

    controller.dispose();
    final double? parsed = double.tryParse(amount ?? '');
    if (parsed == null || parsed <= 0 || !mounted) return;

    await _act(
      () => _partnerRepository.driverPayout(
        (driver['id'] ?? driver['_id']).toString(),
        parsed,
      ),
      'pay:${(driver['id'] ?? driver['_id'])}',
    );
  }

  Future<void> _confirmRemove(Map<String, dynamic> driver, String name) async {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(l10n.removeRiderNamed(name)),
        content: Text(l10n.removeRiderHint),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.remove),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await _act(
      () => _partnerRepository.removeDriver(
        (driver['id'] ?? driver['_id']).toString(),
      ),
      'remove:${(driver['id'] ?? driver['_id'])}',
    );
  }

  Future<void> _promptReject(String driverId, String name) async {
    final TextEditingController controller = TextEditingController();
    final String? reason = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text('Reject $name?'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          maxLength: 500,
          decoration: const InputDecoration(
            labelText: 'Reason for rejection',
            hintText: 'This reason will be shown to the driver.',
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('Reject application'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!mounted || reason == null) return;
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a reason before rejecting the application.')),
      );
      return;
    }
    await _act(
      () => _partnerRepository.approveDriver(driverId, false, reason: reason),
      'reject:$driverId',
    );
  }

  String _riderName(Map<String, dynamic> driver, AppLocalizations l10n) {
    final Map<String, dynamic> user = Map<String, dynamic>.from(
      (driver['userId'] as Map?) ?? <String, dynamic>{},
    );
    final String name = <String>[
      user['firstName']?.toString() ?? '',
      user['lastName']?.toString() ?? '',
    ].where((String part) => part.isNotEmpty).join(' ');
    if (name.isEmpty) return l10n.riderFallback;
    final String mobile = user['mobile']?.toString() ?? '';
    return mobile.isEmpty ? name : '$name · $mobile';
  }

  /// Payout mode decides how this rider is paid, so it belongs on the row rather
  /// than behind a detail tap.
  String _detail(Map<String, dynamic> driver, AppLocalizations l10n) {
    final String mode = driver['payoutMode']?.toString() ?? '';
    final num? rate = driver['payoutRate'] as num?;
    final num? capacity = driver['canCapacity'] as num?;
    final String vehicle = driver['vehicleType']?.toString() ?? '';

    final List<String> parts = <String>[];
    if (mode.isNotEmpty) {
      switch (mode) {
        case 'per_can':
          parts.add(l10n.earningsPerCan);
          break;
        case 'per_litre':
          parts.add(l10n.earningsPerLitre);
          break;
        case 'salary':
          parts.add(l10n.earningsSalary);
          break;
        default:
          parts.add(mode.replaceAll('_', ' '));
      }
    }
    if (rate != null) {
      parts.add('${l10n.earningsRate} $rate');
    }
    if (capacity != null && capacity > 0) {
      parts.add('${capacity.toInt()} ${l10n.cans}');
    }
    if (vehicle.isNotEmpty) {
      parts.add(vehicle);
    }
    return parts.isEmpty ? l10n.riderFallback : parts.join(' · ');
  }

  Color _statusColour(Map<String, dynamic> driver) {
    if (driver['approvalStatus'] == 'pending') {
      return AppColors.expirySoon;
    }
    if (driver['approvalStatus'] == 'rejected' ||
        driver['isBlocked'] == true ||
        driver['activeStatus'] != true ||
        driver['status'] != true) {
      return AppColors.expired;
    }
    return AppColors.canInStore;
  }

  String _driverStatusLabel(Map<String, dynamic> driver, AppLocalizations l10n) {
    if (driver['status'] != true) return 'Removed';
    final Map<String, dynamic> user =
        (driver['userId'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    if (driver['approvalStatus'] == 'pending' && user['isMobileVerified'] != true) {
      return 'Awaiting phone verification';
    }
    switch (driver['approvalStatus']?.toString()) {
      case 'pending':
        return 'Pending approval';
      case 'rejected':
        return 'Rejected';
      case 'approved':
        if (driver['isBlocked'] == true || driver['activeStatus'] != true) {
          return l10n.blocked;
        }
        return 'Active';
      default:
        return driver['isBlocked'] == true ? l10n.blocked : l10n.onFleet;
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final AppThemeData theme =
        appThemeData[Theme.of(context).brightness == Brightness.dark
            ? AppTheme.dark
            : AppTheme.light]!;

    return SectionListScreen(
      title: l10n.navDrivers,
      icon: Icons.pedal_bike_outlined,
      onRefresh: _load,
      children: <Widget>[
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null)
          EmptyState(
            title: l10n.ridersUnavailable,
            message: _error!,
            icon: Icons.cloud_off_outlined,
          )
        else ...<Widget>[
          Card(
            child: ListTile(
              leading: Icon(Icons.person_add_alt_1_outlined, color: theme.primary),
              title: const Text('Create driver account'),
              subtitle: const Text('Add the driver’s details and share their activation code.'),
              trailing: _actingOn == 'create'
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.chevron_right),
              onTap: _actingOn == null ? _promptCreateDriver : null,
            ),
          ),

          if (_invites.isNotEmpty)
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  ListTile(
                    dense: true,
                  title: const Text('Driver invitations'),
                  subtitle: const Text('Codes expire after 14 days. Resending replaces the previous code.'),
                  ),
                  ..._invites.map((dynamic raw) {
                    final Map<String, dynamic> invite =
                        Map<String, dynamic>.from(raw as Map);
                    final String id = (invite['id'] ?? invite['_id']).toString();
                    final String status = invite['status']?.toString() ?? 'pending';
                    final String mobile = invite['mobile']?.toString() ?? '';
                    final Map<String, dynamic> invitedRider =
                        (invite['rider'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
                    final bool accountCreated = invitedRider.isNotEmpty;
                    final String invitedName = <String?>[
                      invitedRider['firstName']?.toString(),
                      invitedRider['lastName']?.toString(),
                    ].whereType<String>().where((String value) => value.isNotEmpty).join(' ');
                    final String inviteLabel = accountCreated && invitedRider['isMobileVerified'] == true
                        ? 'Phone verified · awaiting owner approval'
                        : accountCreated
                            ? 'Account created · awaiting phone verification'
                            : status[0].toUpperCase() + status.substring(1);
                    return ListTile(
                      dense: true,
                      leading: Icon(
                        status == 'accepted'
                            ? Icons.mark_email_read_outlined
                            : status == 'expired' || status == 'revoked'
                                ? Icons.mail_outline
                                : Icons.mark_email_unread_outlined,
                      ),
                      title: Text(invitedName.isEmpty ? '+91 ${invite['mobile'] ?? ''}' : invitedName),
                      subtitle: Text('$inviteLabel · +91 $mobile'),
                      trailing: Wrap(
                        spacing: 4,
                        children: <Widget>[
                          if (status == 'pending' || status == 'expired')
                            TextButton(
                              onPressed: _actingOn == null && mobile.length == 10
                                  ? () => accountCreated
                                      ? _reissueAndShare(id, mobile, invitedName)
                                      : _inviteAndShare(mobile)
                                  : null,
                              child: Text(status == 'expired' ? 'Renew code' : 'Resend code'),
                            ),
                          if (status == 'pending')
                            TextButton(
                              onPressed: _actingOn == null
                                  ? () => _act(
                                        () => _partnerRepository.revokeDriverInvite(id),
                                        'revoke:$id',
                                      )
                                  : null,
                              child: Text(l10n.revoke),
                            ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

          if (_drivers.isEmpty)
            EmptyState(
              title: l10n.noOwnRiders,
              message: l10n.noOwnRidersHint,
              icon: Icons.pedal_bike_outlined,
            )
          else
            Card(
              child: Column(
                children: _drivers.map((dynamic raw) {
                  final Map<String, dynamic> driver =
                      Map<String, dynamic>.from(raw as Map);
                  final String id = (driver['id'] ?? driver['_id']).toString();
                  final bool blocked = driver['isBlocked'] == true ||
                      driver['activeStatus'] != true ||
                      driver['status'] != true;
                  final bool pendingApproval = driver['approvalStatus'] == 'pending';
                  final bool rejected = driver['approvalStatus'] == 'rejected';
                  final bool busy = _actingOn != null;
                  final Map<String, dynamic> user =
                      (driver['userId'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
                  final bool awaitingActivation = pendingApproval && user['isMobileVerified'] != true;
                  final bool canReview = pendingApproval && !awaitingActivation;
                  final String name = _riderName(driver, l10n);

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.primary.withValues(alpha: 0.15),
                      child: Icon(
                        Icons.pedal_bike_outlined,
                        color: theme.primary,
                      ),
                    ),
                    title: Text(name),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(_detail(driver, l10n)),
                          const SizedBox(height: 6),
                          StatusChip(
                            label: _driverStatusLabel(driver, l10n),
                            color: _statusColour(driver),
                          ),
                          if (driver['approvalStatus'] == 'rejected' &&
                              (driver['approvalReason']?.toString().isNotEmpty ?? false))
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text('Reason: ${driver['approvalReason']}'),
                            ),
                        ],
                      ),
                    ),
                    trailing: busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : PopupMenuButton<_DriverAction>(
                            tooltip: l10n.navDrivers,
                            onSelected: (_DriverAction action) {
                              switch (action) {
                                case _DriverAction.toggleStatus:
                                  _act(
                                    () => _partnerRepository.approveDriver(
                                      id,
                                      blocked,
                                    ),
                                    'approve:$id',
                                  );
                                  break;
                                case _DriverAction.approve:
                                  _act(
                                    () => _partnerRepository.approveDriver(id, true),
                                    'approve:$id',
                                  );
                                  break;
                                case _DriverAction.reject:
                                  _promptReject(id, name);
                                  break;
                                case _DriverAction.payout:
                                  _promptPayout(driver, name);
                                  break;
                                case _DriverAction.remove:
                                  _confirmRemove(driver, name);
                                  break;
                              }
                            },
                            itemBuilder: (BuildContext context) => <PopupMenuEntry<_DriverAction>>[
                                  if (canReview) ...<PopupMenuEntry<_DriverAction>>[
                                    PopupMenuItem<_DriverAction>(
                                      value: _DriverAction.approve,
                                      child: Row(children: <Widget>[const Icon(Icons.check_circle_outline), const SizedBox(width: 12), Text(l10n.approve)]),
                                    ),
                                    PopupMenuItem<_DriverAction>(
                                      value: _DriverAction.reject,
                                      child: Row(children: <Widget>[const Icon(Icons.cancel_outlined), const SizedBox(width: 12), const Text('Reject application')]),
                                    ),
                                  ] else if (!awaitingActivation && (rejected || blocked))
                                    PopupMenuItem<_DriverAction>(
                                      value: _DriverAction.approve,
                                      child: Row(children: <Widget>[const Icon(Icons.check_circle_outline), const SizedBox(width: 12), Text(rejected ? 'Approve driver' : l10n.approve)]),
                                    )
                                  else if (!awaitingActivation)
                                    PopupMenuItem<_DriverAction>(
                                      value: _DriverAction.toggleStatus,
                                      child: Row(children: <Widget>[const Icon(Icons.pause_circle_outline), const SizedBox(width: 12), Text(l10n.block)]),
                                    ),
                                  if (!awaitingActivation)
                                    PopupMenuItem<_DriverAction>(
                                      value: _DriverAction.payout,
                                      child: Row(
                                        children: <Widget>[
                                          const Icon(Icons.payments_outlined),
                                          const SizedBox(width: 12),
                                          Text(l10n.payAction),
                                        ],
                                      ),
                                    ),
                                  PopupMenuItem<_DriverAction>(
                                    value: _DriverAction.remove,
                                    child: Row(
                                      children: <Widget>[
                                        const Icon(Icons.person_remove_outlined),
                                        const SizedBox(width: 12),
                                        Text(l10n.remove),
                                      ],
                                    ),
                                  ),
                                ],
                          ),
                    isThreeLine: true,
                  );
                }).toList(),
              ),
            ),
        ],
      ],
    );
  }
}

enum _DriverAction { toggleStatus, approve, reject, payout, remove }
