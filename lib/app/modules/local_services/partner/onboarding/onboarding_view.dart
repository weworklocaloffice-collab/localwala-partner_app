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
import 'package:partner/app/modules/local_services/models/provider.dart';
import 'package:partner/app/modules/local_services/repository/provider_repository.dart';
import 'package:partner/app/modules/local_services/partner/catalogue/offerings_view.dart';
import 'package:partner/gen/l10n/app_localizations.dart';

/// Provider onboarding wizard per §7 spec:
/// type > business+owner > address+areas > docs > Admin review > approve > subscribe? > activate > publish
/// States: DRAFT > SUBMITTED > UNDER_REVIEW > APPROVED > ACTIVE
/// (+CHANGES_REQUIRED/REJECTED/SUSPENDED/INACTIVE/CLOSED)
/// Approved but incomplete setup ≠ bookable.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

enum OnboardingStep {
  registration,
  providerType,
  businessDetails,
  documents,
  review,
  activated,
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final LocalServicesProviderRepository _repository =
      LocalServicesProviderRepository();
  OnboardingStep _step = OnboardingStep.registration;
  final TextEditingController _businessName = TextEditingController();
  final TextEditingController _address = TextEditingController();
  final TextEditingController _areas = TextEditingController();
  final TextEditingController _docKind = TextEditingController();
  final TextEditingController _docUrl = TextEditingController();

  bool _loading = true;
  String? _error;
  LsProvider? _provider;
  Map<String, String>? _providerType;
  List<Map<String, dynamic>> _documents = const <Map<String, dynamic>>[];
  bool _hasSubscription = false;

  @override
  void dispose() {
    _businessName.dispose();
    _address.dispose();
    _areas.dispose();
    _docKind.dispose();
    _docUrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _load(syncStep: true);
  }

  Future<void> _load({bool syncStep = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final DioApiResponse response = await _repository.myProvider();
      final Map<String, dynamic> body = decodeBody(response);
      final dynamic raw = body['provider'];
      final LsProvider? provider = raw is Map<String, dynamic>
          ? LsProvider.fromJson(raw)
          : null;
      final String? providerType = raw is Map<String, dynamic>
          ? raw['providerType'] as String?
          : null;
      if (provider != null &&
          _address.text.isEmpty &&
          provider.businessAddress.isNotEmpty) {
        _address.text = provider.businessAddress;
      }
      await _loadDocuments();
      await _loadCoverage();
      setState(() {
        _provider = provider;
        _providerType = _mapProviderType(providerType);
        if (syncStep) _step = _stepFor(provider);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _provider = null;
        _error = '$e';
        _loading = false;
      });
    }
  }

  Map<String, String>? _mapProviderType(String? type) {
    if (type == null || type.isEmpty) return null;
    return <String, String>{'type': type};
  }

  OnboardingStep _stepFor(LsProvider? provider) {
    if (provider == null) return OnboardingStep.registration;
    if (provider.status == 'SUBMITTED' || provider.status == 'UNDER_REVIEW') {
      return OnboardingStep.review;
    }
    if (provider.status == 'APPROVED' || provider.status == 'ACTIVE') {
      return OnboardingStep.activated;
    }
    if (provider.status == 'DRAFT' || provider.status == 'REJECTED') {
      return OnboardingStep.providerType;
    }
    return OnboardingStep.businessDetails;
  }

  Future<void> _loadDocuments() async {
    try {
      final DioApiResponse docs = await _repository.documents();
      final List<dynamic> list =
          (decodeBody(docs)['results'] ?? []) as List<dynamic>;
      setState(
        () => _documents = list.whereType<Map<String, dynamic>>().toList(),
      );
    } catch (_) {
      setState(() => _documents = const <Map<String, dynamic>>[]);
    }
  }

  Future<void> _loadCoverage() async {
    try {
      final DioApiResponse response = await _repository.coverage();
      if (response.statusCode == null || response.statusCode! >= 400) return;
      final dynamic raw = decodeBody(response)['coverage'];
      if (raw is! Map<String, dynamic> || _areas.text.isNotEmpty) return;
      final List<dynamic> localities =
          (raw['localities'] ?? <dynamic>[]) as List<dynamic>;
      _areas.text = localities.whereType<String>().join(', ');
    } catch (_) {
      return;
    }
  }

  void _ensureOk(DioApiResponse response) {
    final int? status = response.statusCode;
    if (status == null || status >= 400) {
      final dynamic message = decodeBody(response)['message'];
      throw Exception(
        message is String && message.isNotEmpty
            ? message
            : 'Request failed${status == null ? '' : ' ($status)'}',
      );
    }
  }

  // ---- Step: Registration ----
  Future<void> _register() async {
    if (_businessName.text.trim().isEmpty) return;
    try {
      final DioApiResponse response = await _repository.register(
        <String, dynamic>{'businessName': _businessName.text.trim()},
      );
      _ensureOk(response);
      await _load();
      setState(() => _step = OnboardingStep.providerType);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)?.ls_failed_error('$e') ?? 'Failed: $e')));
      }
    }
  }

  // ---- Step: Provider Type ----
  final List<String> _providerTypes = <String>[
    'independent',
    'business',
    'salon',
    'hotel',
    'rental',
    'trainer',
    'multi_location',
  ];

  void _selectProviderType(String type) {
    setState(() => _providerType = <String, String>{'type': type});
  }

  // ---- Step: Business Details ----
  Future<void> _saveBusinessDetails() async {
    if (_provider == null || _providerType == null) return;
    try {
      final DioApiResponse update = await _repository
          .saveBusinessDetails(_provider!.id, <String, dynamic>{
            'providerType': _providerType!['type'],
            'businessAddress': _address.text.trim(),
          });
      _ensureOk(update);
      final List<String> localities = _areas.text
          .split(',')
          .map((String value) => value.trim())
          .where((String value) => value.isNotEmpty)
          .toList();
      if (localities.isNotEmpty) {
        final DioApiResponse coverage = await _repository.saveCoverage(
          <String, dynamic>{'localities': localities},
        );
        _ensureOk(coverage);
      }
      await _load();
      setState(() => _step = OnboardingStep.documents);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)?.ls_failed_error('$e') ?? 'Failed: $e')));
      }
    }
  }

  // ---- Step: Documents ----
  Future<void> _uploadDoc() async {
    if (_docKind.text.trim().isEmpty || _docUrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)?.ls_kind_file_url_required ?? 'Kind and file URL required')),
      );
      return;
    }
    try {
      final DioApiResponse response = await _repository.uploadDocument(
        <String, dynamic>{
          'kind': _docKind.text.trim(),
          'fileUrl': _docUrl.text.trim(),
        },
      );
      _ensureOk(response);
      _docKind.clear();
      _docUrl.clear();
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)?.ls_failed_error('$e') ?? 'Failed: $e')));
      }
    }
  }

  // ---- Step: Review / Status ----
  Future<void> _submitReview() async {
    if (_provider == null) return;
    try {
      final DioApiResponse response = await _repository.submitProvider(
        _provider!.id,
      );
      _ensureOk(response);
      await _load();
      setState(() => _step = OnboardingStep.review);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)?.ls_failed_error('$e') ?? 'Failed: $e')));
      }
    }
  }

  // ---- Step: Subscription ----
  Future<void> _toggleSubscription() async {
    setState(() => _hasSubscription = !_hasSubscription);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_provider == null) {
      return _buildRegistrationStep();
    }
    return _buildWizardStep();
  }

  Widget _buildRegistrationStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            AppLocalizations.of(context)?.ls_register_provider ?? 'Register as a service provider',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _businessName,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)?.ls_business_name ?? 'Business name',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _register, child: Text(AppLocalizations.of(context)?.ls_register ?? 'Register')),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _error!,
                style: const TextStyle(fontSize: 12, color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWizardStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Header showing progress
          _buildStepHeader(),
          const SizedBox(height: 24),
          // Step content
          _buildStepContent(),
          const SizedBox(height: 32),
          _buildNavButtons(),
        ],
      ),
    );
  }

  Widget _buildStepHeader() {
    final List<String> labels = <String>[
      AppLocalizations.of(context)?.ls_register ?? 'Register',
      AppLocalizations.of(context)?.ls_provider_type ?? 'Provider Type',
      AppLocalizations.of(context)?.ls_business_details ?? 'Business Details',
      AppLocalizations.of(context)?.ls_documents ?? 'Documents',
      AppLocalizations.of(context)?.ls_review ?? 'Review',
      AppLocalizations.of(context)?.ls_active ?? 'Active',
    ];
    final List<OnboardingStep> steps = <OnboardingStep>[
      OnboardingStep.registration,
      OnboardingStep.providerType,
      OnboardingStep.businessDetails,
      OnboardingStep.documents,
      OnboardingStep.review,
      OnboardingStep.activated,
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: List.generate(
          steps.length,
          (index) => _stepIndexWidget(index, labels[index]),
        ),
      ),
    );
  }

  Widget _stepIndexWidget(int index, String label) {
    final isCurrent = index == _step.index;
    final isComplete = index < _step.index;
    return Expanded(
      child: Container(
        height: 4,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: isCurrent
              ? Theme.of(context).colorScheme.primary
              : (isComplete ? Colors.green : Colors.grey),
          borderRadius: BorderRadius.horizontal(
            left: isCurrent ? Radius.circular(2) : Radius.zero,
            right: isComplete ? Radius.circular(2) : Radius.zero,
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case OnboardingStep.providerType:
        return _buildProviderTypeStep();
      case OnboardingStep.businessDetails:
        return _buildBusinessDetailsStep();
      case OnboardingStep.documents:
        return _buildDocumentsStep();
      case OnboardingStep.review:
        return _buildReviewStep();
      case OnboardingStep.activated:
        return _buildActivatedStep();
      default:
        return Text(AppLocalizations.of(context)?.ls_step_under_construction ?? 'Step under construction');
    }
  }

  Widget _buildProviderTypeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          AppLocalizations.of(context)?.ls_provider_type ?? 'Provider type',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: _providerTypes.map((String type) {
            final bool isSelected = _providerType?['type'] == type;
            return ChoiceChip(
              label: Text(type.replaceAll('_', ' ')),
              selected: isSelected,
              onSelected: (_) => _selectProviderType(type),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _providerType != null
              ? () => setState(() => _step = OnboardingStep.businessDetails)
              : null,
          child: Text(AppLocalizations.of(context)?.ls_next_business_details ?? 'Next: Business Details'),
        ),
      ],
    );
  }

  Widget _buildBusinessDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          AppLocalizations.of(context)?.ls_business_details ?? 'Business details',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _address,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)?.ls_business_address ?? 'Business address',
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _areas,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)?.ls_service_areas ?? 'Service areas (comma-separated)',
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _saveBusinessDetails,
          child: Text(AppLocalizations.of(context)?.ls_next_documents ?? 'Next: Documents'),
        ),
      ],
    );
  }

  Widget _buildDocumentsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          AppLocalizations.of(context)?.ls_documents ?? 'Documents',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(AppLocalizations.of(context)?.ls_upload_verification_documents ?? 'Upload verification documents:'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _documents
              .map(
                (Map<String, dynamic> doc) => Chip(
                  label: Text(doc['kind'] ?? 'unknown'),
                  avatar: const Icon(Icons.description),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _docKind,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)?.ls_document_kind ?? 'Document kind (e.g. license)',
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _docUrl,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)?.ls_file_url ?? 'File URL',
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _uploadDoc,
          child: Text(AppLocalizations.of(context)?.ls_upload_document ?? 'Upload document'),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _submitReview,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          child: Text(AppLocalizations.of(context)?.ls_submit_for_admin_review ?? 'Submit for Admin review'),
        ),
      ],
    );
  }

  Widget _buildReviewStep() {
    final bool canSubmit =
        _provider!.status == 'DRAFT' || _provider!.status == 'REJECTED';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          AppLocalizations.of(context)?.ls_review_subscription ?? 'Review & Subscription',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text('${AppLocalizations.of(context)?.ls_status ?? 'Status'}: ${_provider!.status}'),
        Text('${AppLocalizations.of(context)?.ls_bookable ?? 'Bookable'}: ${_provider!.bookable ? (AppLocalizations.of(context)?.ls_yes ?? 'Yes') : (AppLocalizations.of(context)?.ls_no ?? 'No')}'),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
              child: ElevatedButton(
                onPressed: _toggleSubscription,
                child: Text(
                  _hasSubscription
                      ? (AppLocalizations.of(context)?.ls_remove_subscription ?? 'Remove subscription')
                      : (AppLocalizations.of(context)?.ls_add_subscription ?? 'Add subscription (optional)'),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (canSubmit)
          ElevatedButton(
            onPressed: _submitReview,
            child: Text(AppLocalizations.of(context)?.ls_submit_for_admin_review ?? 'Submit for admin review'),
          )
        else
          Text(AppLocalizations.of(context)?.ls_submitted_review ?? 'Submitted. LocalWala will review your documents.'),
      ],
    );
  }

  Widget _buildActivatedStep() {
    final bool active = _provider!.status == 'ACTIVE' && _provider!.bookable;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          active
              ? (AppLocalizations.of(context)?.ls_active_published ?? 'Active & Published')
              : (AppLocalizations.of(context)?.ls_approved ?? 'Approved'),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text('${AppLocalizations.of(context)?.ls_status ?? 'Status'}: ${_provider!.status}'),
        Text('${AppLocalizations.of(context)?.ls_bookable ?? 'Bookable'}: ${_provider!.bookable ? (AppLocalizations.of(context)?.ls_yes ?? 'Yes') : (AppLocalizations.of(context)?.ls_no ?? 'No')}'),
        Text(
          active
              ? (AppLocalizations.of(context)?.ls_services_live ?? 'Your services are live and bookable by customers.')
              : (AppLocalizations.of(context)?.ls_account_final_checks ?? 'LocalWala will activate your account after final checks.'),
        ),
    const SizedBox(height: 24),
    OutlinedButton.icon(
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (BuildContext context) => const OfferingsScreen(),
        ),
      ),
      icon: const Icon(Icons.storefront_outlined),
      label: Text(
        AppLocalizations.of(context)?.ls_setup_publish ??
            'Set up & publish services',
      ),
    ),
    const SizedBox(height: 8),
    ElevatedButton(onPressed: _load, child: Text(AppLocalizations.of(context)?.ls_refresh_status ?? 'Refresh status')),
      ],
    );
  }

  Widget _buildNavButtons() {
    if (_step.index <= OnboardingStep.providerType.index) {
      return const SizedBox.shrink();
    }
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () =>
            setState(() => _step = OnboardingStep.values[_step.index - 1]),
        child: Text(AppLocalizations.of(context)?.ls_back ?? 'Back'),
      ),
    );
  }
}
