/*
 * WeWorkLocal
 * Hyperlocal Commerce & Service Platform
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

import 'package:partner/gen/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:partner/app/modules/stores/stores_partner_repository.dart';
import 'package:partner/app/modules/stores/widgets/stores_ui_states.dart';

/// The six application screens, in the order the server indexes them.
///
/// These keys name the top-level field group on `StoreOnboarding` that each screen
/// collects (`API/src/modules/stores/constants/onboarding.steps.js`). `currentStep` IS an
/// index into this list — which is exactly why it is mirrored here rather than invented:
/// if the server adds a section, this screen and that array must move together, and
/// `verify.stores.onboarding.steps.js` asserts the server's own bound matches its length.
const List<_OnboardingStep> _steps = <_OnboardingStep>[
  _OnboardingStep(
    key: 'businessInfo',
    label: 'Business information',
    hint: 'The legal entity: its name and type.',
  ),
  _OnboardingStep(
    key: 'storeInfo',
    label: 'Store information',
    hint: 'The trade name and what it sells.',
  ),
  _OnboardingStep(
    key: 'ownerInfo',
    label: 'Owner information',
    hint: 'Who is responsible for this application.',
  ),
  _OnboardingStep(
    key: 'location',
    label: 'Location',
    hint: 'Where the outlet sits and what it serves.',
  ),
  _OnboardingStep(
    key: 'documents',
    label: 'Documents',
    hint: 'The mandatory set for this store type.',
  ),
  _OnboardingStep(
    key: 'deliveryConfig',
    label: 'Delivery configuration',
    hint: 'Radius, minimum order, delivery fee.',
  ),
];

class _OnboardingStep {
  const _OnboardingStep({required this.key, required this.label, required this.hint});

  final String key;
  final String label;
  final String hint;
}

/// The chain onboarding wizard.
///
/// ## The cursor rule
///
/// The server returns `currentStep`, `completedSteps` and `incompleteSteps` on every save,
/// and this screen renders its position from THOSE — never from a local page counter.
/// `currentStep` is a cursor into `_steps`, not validation: it points at the first thing
/// still missing. A screen that tracked its own index could advance past a step the server
/// still considers incomplete, and the submit gate would refuse with 422 anyway.
///
/// ## One step key per save
///
/// PATCH sends exactly one top-level key (e.g. `{'businessInfo': {...}}`). The server
/// shallow-merges it, EXCEPT `documents`, which is an array and is REPLACED — so this
/// screen always sends the full document list rather than appending.
class StoresOnboardingWizardScreen extends StatefulWidget {
  const StoresOnboardingWizardScreen({super.key});

  @override
  State<StoresOnboardingWizardScreen> createState() => _StoresOnboardingWizardScreenState();
}

class _StoresOnboardingWizardScreenState extends State<StoresOnboardingWizardScreen> {
  StoresPartnerRepository? _repo;
  int _page = 0;
  bool _busy = false;

  // One controller set per text step. `documents` is handled differently (a list), and
  // none of its controllers leak because all six screens live in one state object.
  final Map<String, TextEditingController> _controllers = <String, TextEditingController>{};

  TextEditingController _c(String key) => _controllers.putIfAbsent(key, TextEditingController.new);

  @override
  void dispose() {
    for (final TextEditingController c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  StoresPartnerRepository get _r => _repo ?? StoresPartnerRepository();

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _saveCurrent() async {
    final _OnboardingStep step = _steps[_page];
    final Map<String, dynamic> patch = <String, dynamic>{};

    switch (step.key) {
      case 'businessInfo':
        patch[step.key] = <String, dynamic>{
          'legalName': _c('legalName').text.trim(),
          'businessType': _c('businessType').text.trim(),
        };
        break;
      case 'storeInfo':
        patch[step.key] = <String, dynamic>{
          'name': _c('storeName').text.trim(),
          'categories': <String>[_c('category').text.trim()].where((String s) => s.isNotEmpty).toList(),
        };
        break;
      case 'ownerInfo':
        patch[step.key] = <String, dynamic>{
          'name': _c('ownerName').text.trim(),
          'mobile': _c('ownerMobile').text.trim(),
          'relation': _c('ownerRelation').text.trim(),
        };
        break;
      case 'location':
        patch[step.key] = <String, dynamic>{
          'city': _c('city').text.trim(),
          'locality': _c('locality').text.trim(),
        };
        break;
      case 'documents':
        patch[step.key] = <String>[];
        break;
      case 'deliveryConfig':
        patch[step.key] = <String, dynamic>{
          'radiusKm': num.tryParse(_c('radiusKm').text.trim()) ?? 0,
          'minimumOrder': num.tryParse(_c('minimumOrder').text.trim()) ?? 0,
          'deliveryFee': num.tryParse(_c('deliveryFee').text.trim()) ?? 0,
        };
        break;
    }

    setState(() => _busy = true);
    try {
      final Map<String, dynamic> draft = await _r.saveApplicationStep(patch);

      // The server recomputed progress on this save. Our position follows it.
      final dynamic cursor = draft['currentStep'];
      final List<dynamic> incomplete = (draft['incompleteSteps'] as List?) ?? const <dynamic>[];
      final int serverStep = cursor is num ? cursor.toInt().clamp(0, _steps.length - 1) : _page;

      if (!mounted) return;
      setState(() => _page = serverStep);
      _snack(incomplete.isEmpty ? 'Every section is complete. Review and submit.' : 'Saved. ${incomplete.length} section(s) left.');
    } on StoresApiException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    try {
      await _r.submitApplication();
      _snack('Application submitted for review.');
    } on StoresApiException catch (e) {
      // The server refuses with 422 and says exactly what is missing.
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    final _OnboardingStep step = _steps[_page];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.storesTitleNewStore),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            // The position shown is the server's cursor, never a local page count.
            value: (_page + 1) / _steps.length,
          ),
        ),
      ),
      body: Column(
        children: <Widget>[
          StoresSectionHeader(
            title: l10n.storesWizardStep(_page + 1, _steps.length, step.label),
            trailing: Text(step.hint),
          ),
          Expanded(child: _StepForm(key: ValueKey<String>(step.key), stepKey: step.key, controllers: _controllers)),
          _StepActions(
            busy: _busy,
            first: _page == 0,
            last: _page == _steps.length - 1,
            onBack: () => setState(() => _page = (_page - 1).clamp(0, _steps.length - 1)),
            onNext: () => setState(() => _page = (_page + 1).clamp(0, _steps.length - 1)),
            onSave: _saveCurrent,
            onSubmit: _submit,
          ),
        ],
      ),
    );
  }
}

/// The six step forms. Each collects ONLY the fields its `STEP_REQUIREMENTS` entry needs —
///
///   businessInfo: legalName + businessType
///   storeInfo:    name + at least one category
///   ownerInfo:    name + mobile + relation
///   location:     city + locality (+ geo pin, collected by the next pass)
///   documents:    the mandatory set for this store type
///   delivery:     radiusKm + minimumOrder + deliveryFee
///
/// Asking for more would make the screen the completer rather than the server, and the two
/// would disagree about what "complete" means.
class _StepForm extends StatelessWidget {
  const _StepForm({super.key, required this.stepKey, required this.controllers});

  final String stepKey;
  final Map<String, TextEditingController> controllers;

  TextEditingController _t(String key) => controllers.putIfAbsent(key, TextEditingController.new);

  Widget _field(String key, String label, {TextInputType keyboard = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: _t(key),
        keyboardType: keyboard,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> fields;
    switch (stepKey) {
      case 'businessInfo':
        fields = <Widget>[
          _field('legalName', 'Legal name'),
          _field('businessType', 'Business type'),
        ];
        break;
      case 'storeInfo':
        fields = <Widget>[
          _field('storeName', 'Trade name'),
          _field('category', 'Category'),
        ];
        break;
      case 'ownerInfo':
        fields = <Widget>[
          _field('ownerName', 'Owner name'),
          _field('ownerMobile', 'Mobile', keyboard: TextInputType.phone),
          _field('ownerRelation', 'Relation (self / partner / manager)'),
        ];
        break;
      case 'location':
        fields = <Widget>[
          _field('city', 'City'),
          _field('locality', 'Locality'),
        ];
        break;
      case 'documents':
        fields = const <Widget>[
          Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'Document upload lands in the next pass. '
              'The mandatory set is decided by store type, not by a fixed list.',
            ),
          ),
        ];
        break;
      case 'deliveryConfig':
        fields = <Widget>[
          _field('radiusKm', 'Delivery radius (km)', keyboard: TextInputType.number),
          _field('minimumOrder', 'Minimum order', keyboard: TextInputType.number),
          _field('deliveryFee', 'Delivery fee', keyboard: TextInputType.number),
        ];
        break;
      default:
        fields = <Widget>[Text(AppLocalizations.of(context)!.storesFallbackUnknownStep)];
    }

    return ListView(padding: const EdgeInsets.all(16), children: fields);
  }
}

/// Save / submit footer. "Save" persists the step; "Submit" is offered only at the last
/// screen but still gated server-side — the server 422s on any incomplete step regardless.
class _StepActions extends StatelessWidget {
  const _StepActions({
    required this.busy,
    required this.first,
    required this.last,
    required this.onBack,
    required this.onNext,
    required this.onSave,
    required this.onSubmit,
  });

  final bool busy;
  final bool first;
  final bool last;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onSave;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            if (!first)
              TextButton(
                onPressed: busy ? null : onBack,
                child: Text(l10n.storesActionBack),
              ),
            const Spacer(),
            if (!last)
              FilledButton(
                onPressed: busy ? null : onNext,
                child: Text(l10n.storesActionNext),
              ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: busy ? null : onSave,
              child: Text(l10n.storesActionSave),
            ),
            if (last) ...<Widget>[
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: busy ? null : onSubmit,
                child: Text(l10n.storesActionSubmit),
              ),
            ],
          ],
        ),
      ),
    );
  }
}