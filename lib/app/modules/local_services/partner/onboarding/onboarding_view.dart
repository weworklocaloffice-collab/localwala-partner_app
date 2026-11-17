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

import 'package:file_picker/file_picker.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:partner/app/core/config/api_request_service.dart';
import 'package:partner/app/core/models/user_session_model.dart';
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
  const OnboardingScreen({super.key, this.session});

  final UserSessionModel? session;

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
  final ImagePicker _imagePicker = ImagePicker();
  OnboardingStep _step = OnboardingStep.registration;
  final TextEditingController _businessName = TextEditingController();
  final TextEditingController _address = TextEditingController();
  final TextEditingController _areas = TextEditingController();
  final TextEditingController _contactName = TextEditingController();
  final TextEditingController _contactPhone = TextEditingController();
  final TextEditingController _gstin = TextEditingController();
  final TextEditingController _stateCode = TextEditingController();
  static const List<String> _docKinds = <String>[
    'id_proof',
    'address_proof',
    'license',
    'insurance',
    'certification',
    'other',
  ];
  String _docKind = 'id_proof';
  String? _docPath;
  String? _docName;
  bool _uploading = false;
  double _uploadProgress = 0.0;
  String? _uploadError;

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
    _contactName.dispose();
    _contactPhone.dispose();
    _gstin.dispose();
    _stateCode.dispose();
    super.dispose();
  }

  String _humanize(String value) {
    return value
        .split('_')
        .where((String part) => part.isNotEmpty)
        .map((String part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
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
      if (provider != null) {
        if (_contactName.text.isEmpty) {
          _contactName.text = provider.contactName.isNotEmpty
              ? provider.contactName
              : '${widget.session?.firstName ?? ''} ${widget.session?.lastName ?? ''}'
                    .trim();
        }
        if (_contactPhone.text.isEmpty) {
          _contactPhone.text = provider.contactPhone.isNotEmpty
              ? provider.contactPhone
              : (widget.session?.mobile ?? '');
        }
        if (_gstin.text.isEmpty) _gstin.text = provider.gstin;
        if (_stateCode.text.isEmpty) _stateCode.text = provider.stateCode;
      }
      await _loadProviderTypes();
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

  Future<void> _loadProviderTypes() async {
    try {
      final DioApiResponse response = await _repository.providerTypes();
      final List<dynamic> list =
          (decodeBody(response)['results'] ?? []) as List<dynamic>;
      final List<Map<String, dynamic>> types =
          list.whereType<Map<String, dynamic>>().toList();
      if (types.isEmpty) return;
      setState(() {
        _providerTypes = types
            .map((Map<String, dynamic> type) => '${type['key'] ?? ''}')
            .where((String key) => key.isNotEmpty)
            .toList();
        _providerTypeLabels = <String, String>{
          for (final Map<String, dynamic> type in types)
            '${type['key']}': '${type['label'] ?? type['key']}',
        };
      });
    } catch (_) {}
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
  List<String> _providerTypes = <String>[
    'independent',
    'business',
    'salon',
    'hotel',
    'rental',
    'trainer',
    'multi_location',
  ];
  Map<String, String> _providerTypeLabels = <String, String>{};

  void _selectProviderType(String type) {
    setState(() => _providerType = <String, String>{'type': type});
  }

  // ---- Step: Business Details ----
  Future<void> _fetchLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location services are disabled.')),
          );
        }
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied.')),
          );
        }
        return;
      }
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      String addressText = '${position.latitude}, ${position.longitude}';
      String? locality;
      try {
        final List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final Placemark p = placemarks.first;
          final List<String> parts = <String>[
            if (p.street != null && p.street!.isNotEmpty) p.street!,
            if (p.subLocality != null && p.subLocality!.isNotEmpty) p.subLocality!,
            if (p.locality != null && p.locality!.isNotEmpty) p.locality!,
            if (p.administrativeArea != null && p.administrativeArea!.isNotEmpty) p.administrativeArea!,
            if (p.postalCode != null && p.postalCode!.isNotEmpty) p.postalCode!,
          ];
          if (parts.isNotEmpty) addressText = parts.join(', ');
          locality = p.locality ?? p.subLocality;
        }
      } catch (_) {
        // geocoding best-effort
      }
      if (!mounted) return;
      setState(() {
        _address.text = addressText;
        if (locality != null && locality.isNotEmpty && _areas.text.trim().isEmpty) {
          _areas.text = locality;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not fetch location: $e')),
        );
      }
    }
  }

  Future<void> _saveBusinessDetails() async {
    if (_provider == null || _providerType == null) return;
    try {
      final DioApiResponse update = await _repository
          .saveBusinessDetails(_provider!.id, <String, dynamic>{
            'providerType': _providerType!['type'],
            'businessAddress': _address.text.trim(),
            'contactName': _contactName.text.trim(),
            'contactPhone': _contactPhone.text.trim(),
            'gstin': _gstin.text.trim(),
            'stateCode': _stateCode.text.trim(),
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
  Future<void> _pickDocPhoto(ImageSource source) async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: source,
        maxWidth: 2000,
        imageQuality: 85,
      );
      if (photo == null || !mounted) return;
      // Compress to keep uploads under the 10 MB server cap.
      String finalPath = photo.path;
      String finalName = photo.name;
      try {
        final Directory tmp = await getTemporaryDirectory();
        final String target = '${tmp.path}/doc_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final XFile? compressed = await FlutterImageCompress.compressAndGetFile(
          photo.path,
          target,
          quality: 80,
          minWidth: 1600,
        );
        if (compressed != null) {
          finalPath = compressed.path;
          finalName = compressed.name;
        }
      } catch (_) {
        // compression best-effort; fall back to original
      }
      if (!mounted) return;
      setState(() {
        _docPath = finalPath;
        _docName = finalName;
      });
    } on Exception {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)?.ls_could_not_open_photos ??
                'Could not open photos. Check app permissions and try again.',
          ),
        ),
      );
    }
  }

  Future<void> _uploadDoc() async {
    final String kind = _docKind;
    if (kind.isEmpty || _docPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)?.ls_document_file_required ??
                'Document kind and file are required',
          ),
        ),
      );
      return;
    }
    // Client-side 10 MB guard
    try {
      final File f = File(_docPath!);
      final int size = await f.length();
      if (size > 10 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'File is larger than 10 MB. Please compress or pick a smaller file.',
              ),
            ),
          );
        }
        return;
      }
    } catch (_) {
      // size check best-effort; continue
    }
    setState(() {
      _uploading = true;
      _uploadProgress = 0.0;
      _uploadError = null;
    });
    try {
      final DioApiResponse uploaded = await _repository.uploadDocumentFile(
        filePath: _docPath!,
        filename: _docName ?? 'document',
        onSendProgress: (int sent, int total) {
          if (!mounted || total <= 0) return;
          setState(() => _uploadProgress = sent / total);
        },
      );
      _ensureOk(uploaded);
      final Map<String, dynamic> body = decodeBody(uploaded);
      final String path = '${body['path'] ?? body['fileUrl'] ?? ''}';
      if (path.isEmpty) {
        throw Exception('Upload did not return a file path');
      }
      final DioApiResponse response = await _repository.uploadDocument(
        <String, dynamic>{'kind': kind, 'fileUrl': path},
      );
      _ensureOk(response);
      setState(() {
        _docPath = null;
        _docName = null;
      });
      await _load();
    } catch (e) {
      if (mounted) {
        setState(() => _uploadError = '$e');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)?.ls_failed_error('$e') ?? 'Failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            labels[_step.index],
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Step ${_step.index + 1} of ${steps.length}',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(
              steps.length,
              (index) => _stepIndexWidget(index, labels[index]),
            ),
          ),
        ],
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
              label: Text(_providerTypeLabels[type] ?? type.replaceAll('_', ' ')),
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
          controller: _contactName,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)?.ls_contact_name ?? 'Contact name',
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _contactPhone,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)?.ls_contact_phone ?? 'Contact phone',
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _gstin,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)?.ls_gstin_optional ?? 'GSTIN (optional)',
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _stateCode,
          keyboardType: TextInputType.number,
          maxLength: 2,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)?.ls_gst_state_code_optional ?? 'GST state code (optional, e.g. 27)',
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _address,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)?.ls_business_address ?? 'Business address',
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _fetchLocation,
          icon: const Icon(Icons.my_location),
          label: const Text('Use current location'),
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
        DropdownButtonFormField<String>(
          initialValue: _docKind,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)?.ls_document_kind ?? 'Document kind',
            border: const OutlineInputBorder(),
          ),
          items: _docKinds
              .map(
                (String value) => DropdownMenuItem<String>(
                  value: value,
                  child: Text(_humanize(value)),
                ),
              )
              .toList(),
          onChanged: (String? value) {
            if (value != null) setState(() => _docKind = value);
          },
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: <Widget>[
            TextButton.icon(
              onPressed: () async {
                final FilePickerResult? result = await FilePicker.platform
                    .pickFiles(
                      type: FileType.custom,
                      allowedExtensions: <String>[
                        'pdf',
                        'jpg',
                        'jpeg',
                        'png',
                        'webp',
                      ],
                    );
                if (!mounted) return;
                if (result != null && result.files.single.path != null) {
                  setState(() {
                    _docPath = result.files.single.path;
                    _docName = result.files.single.name;
                  });
                }
              },
              icon: const Icon(Icons.attach_file),
              label: Text(AppLocalizations.of(context)?.ls_choose_file ?? 'Choose file'),
            ),
            TextButton.icon(
              onPressed: () => _pickDocPhoto(ImageSource.gallery),
              icon: const Icon(Icons.photo_library_outlined),
              label: Text(AppLocalizations.of(context)?.ls_choose_from_gallery ?? 'Gallery'),
            ),
            TextButton.icon(
              onPressed: () => _pickDocPhoto(ImageSource.camera),
              icon: const Icon(Icons.camera_alt_outlined),
              label: Text(AppLocalizations.of(context)?.ls_take_a_photo ?? 'Camera'),
            ),
          ],
        ),
        if (_docName != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _docName!,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        const SizedBox(height: 24),
        if (_uploading)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: LinearProgressIndicator(value: _uploadProgress > 0 ? _uploadProgress : null),
          ),
        if (_uploadError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              _uploadError!,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ElevatedButton(
          onPressed: _uploading ? null : _uploadDoc,
          child: Text(AppLocalizations.of(context)?.ls_upload_document ?? 'Upload document'),
        ),
        if (_uploadError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextButton(
              onPressed: _uploading ? null : _uploadDoc,
              child: Text(AppLocalizations.of(context)?.ls_retry ?? 'Retry'),
            ),
          ),
        const SizedBox(height: 12),
        if (_documents.isNotEmpty)
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
               : 'Your application is approved. LocalWala admin will activate your account shortly. Tap Refresh to check status.',
         ),
     const SizedBox(height: 24),
     if (active)
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
     if (!active) const SizedBox(height: 8),
     ElevatedButton.icon(
       onPressed: _load,
       icon: const Icon(Icons.refresh),
       label: Text(AppLocalizations.of(context)?.ls_refresh_status ?? 'Refresh status'),
     ),
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
