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

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:partner/gen/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Shown only when a call cannot proceed at all.
///
/// Dairy riders are frequently offline for long stretches of a route, so most
/// screens degrade to their cached state instead of navigating here. This is the
/// last resort for an action that genuinely requires connectivity.
class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({super.key});

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  bool _online = true;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final List<ConnectivityResult> results = await Connectivity().checkConnectivity();
    final bool online = !results.contains(ConnectivityResult.none);
    if (mounted) setState(() => _online = online);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Image.asset('assets/images/error/internetfailed.png', height: 160),
              const SizedBox(height: 16),
              Text(
                _online ? l10n.retry : l10n.noInternet,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'Scans you have already made are queued and will sync automatically.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _check, child: Text(l10n.retry)),
            ],
          ),
        ),
      ),
    );
  }
}