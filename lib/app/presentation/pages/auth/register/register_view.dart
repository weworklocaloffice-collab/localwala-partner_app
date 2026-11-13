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

import 'package:partner/app/presentation/pages/auth/register/bloc/registration_bloc.dart';
import 'package:partner/app/modules/stores/partner/onboarding/stores_onboarding_wizard_screen.dart';
import 'package:partner/app/router/app_route_config.dart';
import 'package:partner/app/shell/role_gate/bloc/role_gate_bloc.dart';
import 'package:partner/gen/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:otp_text_field/otp_text_field.dart';

/// Self-registration.
///
/// Step 1 picks the business vertical, step 2 collects identity details, step 3 verifies the
/// mobile. A partner additionally supplies business details, which seed the
/// `Business` and the pending `DairyJoiningRequest`.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, this.initialInviteCode, this.initialMobile});

  final String? initialInviteCode;
  final String? initialMobile;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _firstName = TextEditingController();
  final TextEditingController _lastName = TextEditingController();
  final TextEditingController _mobile = TextEditingController();
  final TextEditingController _inviteCode = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirmPassword = TextEditingController();
  final TextEditingController _businessName = TextEditingController();
  final TextEditingController _address = TextEditingController();
  final TextEditingController _fssai = TextEditingController();
  final TextEditingController _fssaiExpiry = TextEditingController();

  @override
  void initState() {
    super.initState();
    final String? code = widget.initialInviteCode;
    final String? mobile = widget.initialMobile;
    if (code == null || code.isEmpty) return;
    _inviteCode.text = code;
    if (mobile != null) _mobile.text = mobile;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<RegistrationBloc>().add(
        RegistrationVerticalSelected(RegistrationVertical.dairyDriver),
      );
      context.read<RegistrationBloc>().add(
        RegistrationFieldChanged(inviteCode: code, mobile: mobile),
      );
    });
  }

  void _businessChanged({
    String? businessName,
    String? businessModel,
    String? requestedBusinessModel,
    String? city,
    String? locality,
    String? fssaiLicence,
    String? fssaiExpiry,
  }) {
    final RegistrationState current = context.read<RegistrationBloc>().state;
    context.read<RegistrationBloc>().add(
      RegistrationBusinessChanged(
        businessName: businessName ?? current.businessName,
        businessModel: businessModel ?? current.businessModel,
        requestedBusinessModel:
            requestedBusinessModel ?? current.requestedBusinessModel,
        city: city ?? current.city,
        locality: locality ?? current.locality,
        fssaiLicence: fssaiLicence ?? current.fssaiLicence,
        fssaiExpiry: fssaiExpiry ?? current.fssaiExpiry,
        addressLine1: _address.text,
      ),
    );
  }

  Future<void> _pickFssaiExpiry() async {
    final DateTime now = DateTime.now();
    final DateTime? parsed = DateTime.tryParse(
      context.read<RegistrationBloc>().state.fssaiExpiry,
    );
    final DateTime initial = parsed != null && parsed.isAfter(now)
        ? parsed
        : DateTime(now.year + 1, now.month, now.day);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now,
      lastDate: DateTime(now.year + 20),
      helpText: 'FSSAI expiry',
    );
    if (!mounted || picked == null) return;
    _fssaiExpiry.text = _displayDate(picked);
    _businessChanged(fssaiExpiry: _isoDate(picked));
  }

  String _isoDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  String _displayDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _mobile.dispose();
    _inviteCode.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    _businessName.dispose();
    _address.dispose();
    _fssai.dispose();
    _fssaiExpiry.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: BlocConsumer<RegistrationBloc, RegistrationState>(
        listenWhen: (RegistrationState p, RegistrationState c) =>
            p.status != c.status || p.alertMessage != c.alertMessage,
        listener: (BuildContext context, RegistrationState state) {
          if (state.status == RegistrationStatus.failure &&
              state.alertMessage.isNotEmpty) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.alertMessage)));
          }
          if (state.status == RegistrationStatus.success) {
            if (state.isStores) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute<void>(
                  builder: (_) => const StoresOnboardingWizardScreen(),
                ),
                (Route<dynamic> _) => false,
              );
            } else {
              context.read<RoleGateBloc>().add(const RoleGateResolveEvent());
              AppRouter.pushNamedAndRemoveAll(context, AppRouter.homeRoute);
            }
          }
        },
        builder: (BuildContext context, RegistrationState state) {
          if (state.vertical == null) {
            return _verticalPicker(context);
          }

          final bool canCreateAccount =
              state.canSubmit &&
              (state.otpVerified || state.canVerifyOtp) &&
              !state.submitting;

          return ListView(
            padding: const EdgeInsets.all(24),
            children: <Widget>[
              Row(
                children: <Widget>[
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.read<RegistrationBloc>().add(
                      const RegistrationVerticalCleared(),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      state.vertical!.label,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _firstName,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'First name'),
                onChanged: (String value) => context
                    .read<RegistrationBloc>()
                    .add(RegistrationFieldChanged(firstName: value)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _lastName,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Last name'),
                onChanged: (String value) => context
                    .read<RegistrationBloc>()
                    .add(RegistrationFieldChanged(lastName: value)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _mobile,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: const InputDecoration(
                  labelText: 'Mobile number',
                  prefixText: '+91 ',
                ),
                onChanged: (String value) => context
                    .read<RegistrationBloc>()
                    .add(RegistrationFieldChanged(mobile: value.trim())),
              ),

              if (state.isDriver) ...<Widget>[
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(
                      'Use the phone number invited by your dairy outlet. '
                      'Your account will remain pending until the outlet approves it.',
                    ),
                  ),
                ),
                TextField(
                  controller: _inviteCode,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 48,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(RegExp('[a-fA-F0-9]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Invitation code',
                    helperText: 'Get this code from the outlet owner.',
                  ),
                  onChanged: (String value) => context
                      .read<RegistrationBloc>()
                      .add(RegistrationFieldChanged(inviteCode: value.trim())),
                ),
              ],

              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
                onChanged: (String value) => context
                    .read<RegistrationBloc>()
                    .add(RegistrationFieldChanged(email: value.trim())),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  helperText:
                      'At least 8 characters, with a letter and a number',
                ),
                onChanged: (String value) => context
                    .read<RegistrationBloc>()
                    .add(RegistrationFieldChanged(password: value)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _confirmPassword,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Confirm password',
                  errorText:
                      _confirmPassword.text.isNotEmpty &&
                          _confirmPassword.text != _password.text
                      ? 'The two passwords do not match'
                      : null,
                ),
                onChanged: (String value) => context
                    .read<RegistrationBloc>()
                    .add(RegistrationFieldChanged(confirmPassword: value)),
              ),

              if (state.needsBusinessDetails) ...<Widget>[
                const SizedBox(height: 8),
                TextField(
                  controller: _businessName,
                  decoration: const InputDecoration(labelText: 'Business name'),
                  onChanged: (String value) =>
                      _businessChanged(businessName: value),
                ),
                if (state.isJhatka) ...<Widget>[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _address,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Shop address',
                      helperText: 'Building, street and area of the outlet.',
                    ),
                    onChanged: (String _) => _businessChanged(),
                  ),
                ],
                const SizedBox(height: 12),
                if (state.isDairy) ...<Widget>[
                  DropdownButtonFormField<String>(
                    initialValue: state.requestedBusinessModel,
                    decoration: const InputDecoration(
                      labelText: 'Preferred partnership model',
                      helperText:
                          'This is a request only. Admin confirms the final model and agreement.',
                    ),
                    items: const <DropdownMenuItem<String>>[
                      DropdownMenuItem<String>(
                        value: '',
                        child: Text('Select a preference'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'commission_partner',
                        child: Text('Commission partner'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'franchise',
                        child: Text('Franchise'),
                      ),
                    ],
                    onChanged: (String? value) => _businessChanged(
                      requestedBusinessModel: value ?? '',
                    ),
                  ),
                  const SizedBox(height: 12),
                ] else ...<Widget>[
                  DropdownButtonFormField<String>(
                    initialValue: state.businessModel,
                    decoration: const InputDecoration(labelText: 'Business model'),
                    items: const <DropdownMenuItem<String>>[
                      DropdownMenuItem<String>(value: 'direct', child: Text('Direct')),
                      DropdownMenuItem<String>(value: 'franchise', child: Text('Franchise')),
                      DropdownMenuItem<String>(value: 'commission_partner', child: Text('Commission partner')),
                    ],
                    onChanged: (String? value) =>
                        _businessChanged(businessModel: value ?? 'direct'),
                  ),
                ],
                const SizedBox(height: 12),
                // No "I run my own delivery riders" switch any more.
                //
                // It used to offer a choice between hiring your own riders and having
                // the platform pool deliver. There is no platform pool in dairy, so
                // the off state described a service that does not exist â€” and the
                // field is now rejected by the API rather than ignored, so leaving it
                // here would have failed every partner registration.
                //
                // Every outlet runs its own riders, and pays them.
                // City then locality, both required.
                //
                // The locality list is fetched per city and the chosen locality is
                // cleared whenever the city changes, so a stale pair cannot be
                // submitted. The server re-checks the pairing regardless â€” this
                // cascade exists so the operator is never offered a combination
                // that will be refused.
                DropdownButtonFormField<String>(
                  initialValue: state.city.isEmpty ? null : state.city,
                  decoration: InputDecoration(
                    labelText: 'City',
                    errorText:
                        state.cityOptions.isEmpty && !state.loadingLocations
                        ? 'No cities are available yet'
                        : null,
                  ),
                  items: state.cityOptions
                      .map(
                        (LocationOption option) => DropdownMenuItem<String>(
                          value: option.id,
                          child: Text(option.name),
                        ),
                      )
                      .toList(),
                  onChanged: state.cityOptions.isEmpty
                      ? null
                      : (String? value) => context.read<RegistrationBloc>().add(
                          RegistrationCityChanged(value ?? ''),
                        ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: state.locality.isEmpty ? null : state.locality,
                  decoration: InputDecoration(
                    labelText: 'Locality',
                    helperText:
                        'Choose the city first. Your delivery zone is set from this.',
                  ),
                  items: state.localityOptions
                      .map(
                        (LocationOption option) => DropdownMenuItem<String>(
                          value: option.id,
                          child: Text(option.name),
                        ),
                      )
                      .toList(),
                  onChanged: state.localityOptions.isEmpty
                      ? null
                      : (String? value) => context.read<RegistrationBloc>().add(
                          RegistrationLocalityChanged(value ?? ''),
                        ),
                ),
                if (state.isJhatka) ...<Widget>[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _fssai,
                    decoration: const InputDecoration(
                      labelText: 'FSSAI licence (optional now)',
                      helperText:
                          'Add the expiry too, or leave both blank and submit it later from Compliance.',
                    ),
                    onChanged: (String value) =>
                        _businessChanged(fssaiLicence: value.trim()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _fssaiExpiry,
                    readOnly: true,
                    onTap: _pickFssaiExpiry,
                    decoration: const InputDecoration(
                      labelText: 'FSSAI expiry',
                      helperText:
                          'Required with the licence number. The licence is reviewed after registration.',
                      suffixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                  ),
                ],
              ],

              const SizedBox(height: 20),
              if (state.otpId != null &&
                  state.status != RegistrationStatus.success) ...<Widget>[
                OTPTextField(
                  length: 6,
                  onChanged: (String value) => context
                      .read<RegistrationBloc>()
                      .add(RegistrationOtpChanged(value)),
                  onCompleted: (String value) => context
                      .read<RegistrationBloc>()
                      .add(RegistrationVerifyOtp(value)),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: canCreateAccount
                      ? () => context.read<RegistrationBloc>().add(
                          state.otpVerified
                              ? const RegistrationSubmit()
                              : RegistrationVerifyOtp(state.otpCode),
                        )
                      : null,
                  child: state.otpVerifying || state.submitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Create account'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: state.otpVerifying || state.submitting
                      ? null
                      : () => context.read<RegistrationBloc>().add(
                          const RegistrationSendOtp(),
                        ),
                  child: Text(l10n.resendOtp),
                ),
              ] else
                ElevatedButton(
                  onPressed: state.canSendOtp
                      ? () => context.read<RegistrationBloc>().add(
                          const RegistrationSendOtp(),
                        )
                      : null,
                  child: Text(l10n.sendOtp),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _verticalPicker(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const SizedBox(height: 20),
          Text(
            'How will you use this app?',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            'Choose the account type you were invited to use.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          DropdownButtonFormField<RegistrationVertical>(
            decoration: const InputDecoration(
              labelText: 'Select Vertical',
              border: OutlineInputBorder(),
            ),
            items: RegistrationVertical.values
                .map(
                  (RegistrationVertical vertical) =>
                      DropdownMenuItem<RegistrationVertical>(
                        value: vertical,
                        child: Text(vertical.label),
                      ),
                )
                .toList(),
            onChanged: (RegistrationVertical? vertical) {
              if (vertical != null) {
                context.read<RegistrationBloc>().add(
                  RegistrationVerticalSelected(vertical),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
