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

import 'package:partner/app/presentation/pages/auth/login/bloc/login_bloc.dart';
import 'package:partner/app/presentation/styles/theme.dart';
import 'package:partner/app/router/app_route_config.dart';
import 'package:partner/app/shell/role_gate/bloc/role_gate_bloc.dart';
import 'package:partner/gen/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otp_text_field/otp_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _mobileController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _mobileController.dispose();
    super.dispose();
  }

  void _sendOtp() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    context.read<LoginBloc>().add(
      LoginSendOtpEvent(_mobileController.text.trim()),
    );
  }

  void _verify(String code) {
    final String? otpId = context.read<LoginBloc>().state.otpId;
    if (otpId == null || otpId.isEmpty || code.trim().length != 6) return;
    context.read<LoginBloc>().add(
      LoginVerifyOtpEvent(otpId, code.trim(), userAgent: 'dairy_partner_app'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final AppThemeData theme =
        appThemeData[Theme.of(context).brightness == Brightness.dark
            ? AppTheme.dark
            : AppTheme.light]!;

    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<LoginBloc, LoginState>(
          listenWhen: (LoginState previous, LoginState current) =>
              previous.status != current.status ||
              previous.alertMessage != current.alertMessage,
          listener: (BuildContext context, LoginState state) {
            if (state.status == LoginStatus.failure &&
                state.alertMessage.isNotEmpty) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.alertMessage)));
            }
            if (state.status == LoginStatus.success) {
              context.read<RoleGateBloc>().add(const RoleGateResolveEvent());
              AppRouter.pushNamedAndRemoveAll(context, AppRouter.homeRoute);
            }
          },
          builder: (BuildContext context, LoginState state) {
            return ListView(
              padding: const EdgeInsets.all(24),
              children: <Widget>[
                const SizedBox(height: 40),
                Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    color: theme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.water_drop_outlined,
                    size: 40,
                    color: theme.primary,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.loginWithMobile,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  'Partners and delivery riders use the same sign-in. Your role decides what you see.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    icon: const Icon(Icons.person_add_alt_1_outlined),
                    label: const Text('Create a new account'),
                    onPressed: () =>
                        AppRouter.pushNamed(context, AppRouter.registerRoute),
                  ),
                ),
                const SizedBox(height: 28),
                Form(
                  key: _formKey,
                  child: TextFormField(
                    controller: _mobileController,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    decoration: const InputDecoration(
                      labelText: 'Mobile number',
                      prefixText: '+91 ',
                    ),
                    validator: (String? value) {
                      final String digits = (value ?? '').trim();
                      if (digits.length != 10) {
                        return 'Enter a 10 digit mobile number';
                      }
                      if (int.tryParse(digits) == null) return 'Digits only';
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 8),
                if (state.canVerify) ...<Widget>[
                  OTPTextField(length: 6, onCompleted: _verify),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: state.isBusy
                        ? null
                        : () => context.read<LoginBloc>().add(
                            LoginResendOtpEvent(_mobileController.text.trim()),
                          ),
                    child: Text(l10n.resendOtp),
                  ),
                ] else
                  ElevatedButton(
                    onPressed: state.isBusy ? null : _sendOtp,
                    child: state.isBusy
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(l10n.sendOtp),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
