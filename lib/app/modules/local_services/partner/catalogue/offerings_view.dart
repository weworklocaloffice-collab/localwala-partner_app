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
import 'package:image_picker/image_picker.dart';
import 'package:partner/app/core/config/api_request_service.dart';
import 'package:partner/app/env.dart';
import 'package:partner/app/modules/local_services/models/provider.dart';
import 'package:partner/app/modules/local_services/repository/provider_repository.dart';
import 'package:partner/gen/l10n/app_localizations.dart';

/// Partner catalogue: one offering per service + variant.
/// Variants and add-ons are admin-owned catalogue data; this screen only
/// reads them and writes the provider's price/duration.
class OfferingsScreen extends StatefulWidget {
  const OfferingsScreen({super.key});

  @override
  State<OfferingsScreen> createState() => _OfferingsScreenState();
}

class _OfferingsScreenState extends State<OfferingsScreen> {
  final LocalServicesProviderRepository _repository =
      LocalServicesProviderRepository();
  final TextEditingController _price = TextEditingController();
  final TextEditingController _duration = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  bool _loading = true;
  bool _saving = false;
  bool _loadingVariants = false;
  bool _uploadingImage = false;
  String? _error;
  String? _serviceId;
  String? _variantId;
  String? _imagePath;
  List<LsCatalogueService> _services = const <LsCatalogueService>[];
  List<LsCatalogueVariant> _variants = const <LsCatalogueVariant>[];
  List<LsOffering> _items = const <LsOffering>[];

  @override
  void dispose() {
    _price.dispose();
    _duration.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final List<DioApiResponse> responses = await Future.wait(
        <Future<DioApiResponse>>[
          _repository.offerings(),
          _repository.publicServices(),
        ],
      );
      _ensureOk(responses[0]);
      _ensureOk(responses[1]);
      final List<dynamic> offeringRows =
          (decodeBody(responses[0])['results'] ?? <dynamic>[]) as List<dynamic>;
      final List<dynamic> serviceRows =
          (decodeBody(responses[1])['results'] ?? <dynamic>[]) as List<dynamic>;
      final List<LsCatalogueService> services = serviceRows
          .whereType<Map<String, dynamic>>()
          .map(LsCatalogueService.fromJson)
          .toList();
      final bool selectedExists = services.any(
        (LsCatalogueService s) => s.id == _serviceId,
      );
      setState(() {
        _items = offeringRows
            .whereType<Map<String, dynamic>>()
            .map(LsOffering.fromJson)
            .toList();
        _services = services;
        if (!selectedExists) {
          _serviceId = null;
          _variantId = null;
          _variants = const <LsCatalogueVariant>[];
        }
        _loading = false;
      });
      if (_serviceId != null) await _loadVariants(_serviceId!);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Future<void> _loadVariants(String serviceId) async {
    setState(() {
      _loadingVariants = true;
      _variantId = null;
      _variants = const <LsCatalogueVariant>[];
    });
    try {
      final DioApiResponse response = await _repository.publicServiceDetail(
        serviceId,
      );
      _ensureOk(response);
      final List<dynamic> raw =
          (decodeBody(response)['variants'] ?? <dynamic>[]) as List<dynamic>;
      if (!mounted) return;
      setState(() {
        _variants = raw
            .whereType<Map<String, dynamic>>()
            .map(LsCatalogueVariant.fromJson)
            .toList();
        _loadingVariants = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingVariants = false;
        _error = '$e';
      });
    }
  }

  void _selectService(String? id) {
    setState(() {
      _serviceId = id;
      _variantId = null;
      _variants = const <LsCatalogueVariant>[];
    });
    final LsCatalogueService? service = _serviceById(id);
    if (service != null) _duration.text = '${service.baseDurationMinutes}';
    if (id != null) _loadVariants(id);
  }

  void _selectVariant(String? id) {
    setState(() => _variantId = id);
    for (final LsCatalogueVariant variant in _variants) {
      if (variant.id == id) {
        _duration.text = '${variant.durationMinutes}';
        break;
      }
    }
  }

  Future<XFile?> _pickOfferingPhoto() async {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (BuildContext context) => SafeArea(
        child: Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
               title: Text(AppLocalizations.of(context)?.ls_choose_from_gallery ?? 'Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
               title: Text(AppLocalizations.of(context)?.ls_take_a_photo ?? 'Take a photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return null;
    try {
      return await _imagePicker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 80,
      );
    } on Exception {
      _show(l10n?.ls_could_not_open_photos ?? 'Could not open photos. Check app permissions and try again.');
      return null;
    }
  }

  Future<String?> _uploadOfferingPhoto(XFile photo) async {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    try {
      final DioApiResponse response = await _repository.uploadOfferingImage(
        filePath: photo.path,
        filename: photo.name,
      );
      _ensureOk(response);
      final Map<String, dynamic> upload = decodeBody(response);
      final String? path = (upload['path'] ?? upload['fileUrl'])?.toString();
      if (path == null || path.isEmpty) {
        throw Exception('Upload returned no path');
      }
      return path;
    } catch (e) {
      _show('${l10n?.ls_image_upload_failed ?? 'Image upload failed'}: $e');
      return null;
    }
  }

  Future<void> _addImage() async {
    final XFile? photo = await _pickOfferingPhoto();
    if (photo == null || !mounted) return;
    setState(() => _uploadingImage = true);
    final String? path = await _uploadOfferingPhoto(photo);
    if (!mounted) return;
    setState(() {
      if (path != null) _imagePath = path;
      _uploadingImage = false;
    });
  }

  String _resolveImageUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    final String base = Environments.apiBaseURL.endsWith('/')
        ? Environments.apiBaseURL.substring(0, Environments.apiBaseURL.length - 1)
        : Environments.apiBaseURL;
    final String key = url.startsWith('/') ? url.substring(1) : url;
    return '$base/storage/$key';
  }

  Future<void> _create() async {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    final LsCatalogueService? service = _serviceById(_serviceId);
    final double? price = double.tryParse(_price.text.trim());
    if (service == null || price == null) {
      _show(l10n?.ls_choose_service_numeric_price ?? 'Choose a service and enter a numeric price');
      return;
    }
    if (service.pricingMode == 'VARIANT' && _variantId == null) {
      _show(l10n?.ls_choose_variant_service ?? 'Choose a variant for this service');
      return;
    }
    final int duration = int.tryParse(_duration.text.trim()) ?? 0;
    setState(() => _saving = true);
    try {
      final DioApiResponse response = await _repository
          .createOffering(<String, dynamic>{
            'service': service.id,
            if (_variantId != null) 'variant': _variantId,
            if (_imagePath != null) 'image': _imagePath,
            'price': price,
            if (duration > 0) 'durationMinutes': duration,
          });
      _ensureOk(response);
      _price.clear();
      setState(() => _imagePath = null);
      await _load();
    } catch (e) {
      _show(l10n?.ls_failed_error('$e') ?? 'Failed: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _submit(LsOffering offering) async {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    try {
      final DioApiResponse response = await _repository.submitOffering(
        offering.id,
      );
      _ensureOk(response);
      await _load();
    } catch (e) {
      _show(l10n?.ls_failed_error('$e') ?? 'Failed: $e');
    }
  }

  Future<void> _edit(LsOffering offering) async {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    final TextEditingController price = TextEditingController(
      text: '${offering.price}',
    );
    final TextEditingController duration = TextEditingController(
      text: '${offering.durationMinutes}',
    );
    String imagePath = offering.image;
    bool uploading = false;
    final bool? save = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder:
            (BuildContext dialogContext, StateSetter setDialogState) =>
                AlertDialog(
                   title: Text(AppLocalizations.of(context)?.ls_edit_offering ?? 'Edit offering'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        TextField(
                          controller: price,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)?.ls_price ?? 'Price',
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: duration,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)?.ls_duration_minutes ?? 'Duration (min)',
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (imagePath.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              _resolveImageUrl(imagePath),
                              width: 96,
                              height: 96,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (
                                    BuildContext context,
                                    Object error,
                                    StackTrace? stack,
                                  ) => Container(
                                    width: 96,
                                    height: 96,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerHighest,
                                    child: const Icon(
                                      Icons.broken_image_outlined,
                                    ),
                                  ),
                            ),
                          ),
                        if (uploading) const LinearProgressIndicator(),
                        Wrap(
                          spacing: 4,
                          children: <Widget>[
                            TextButton.icon(
                              onPressed: uploading
                                  ? null
                                  : () async {
                                      final XFile? photo =
                                          await _pickOfferingPhoto();
                                      if (photo == null) return;
                                      setDialogState(() => uploading = true);
                                      final String? path =
                                          await _uploadOfferingPhoto(photo);
                                      if (!dialogContext.mounted) return;
                                      setDialogState(() {
                                        if (path != null) imagePath = path;
                                        uploading = false;
                                      });
                                    },
                              icon: const Icon(Icons.photo_camera_outlined),
                              label: Text(
                                imagePath.isEmpty
                                    ? (AppLocalizations.of(context)?.ls_add_photo ?? 'Add photo')
                                    : (AppLocalizations.of(context)?.ls_change_photo ?? 'Change photo'),
                              ),
                            ),
                            if (imagePath.isNotEmpty)
                              TextButton(
                                onPressed: uploading
                                    ? null
                                    : () =>
                                          setDialogState(() => imagePath = ''),
                                 child: Text(AppLocalizations.of(context)?.ls_remove_photo ?? 'Remove photo'),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppLocalizations.of(context)?.ls_saving_returns_draft ?? 'Saving changes returns this offering to draft for review.',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                       child: Text(AppLocalizations.of(context)?.ls_cancel ?? 'Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(dialogContext, true),
                       child: Text(AppLocalizations.of(context)?.ls_save ?? 'Save'),
                    ),
                  ],
                ),
      ),
    );
    final double? parsedPrice = double.tryParse(price.text.trim());
    final int? parsedDuration = int.tryParse(duration.text.trim());
    price.dispose();
    duration.dispose();
    if (save != true) return;
    if (parsedPrice == null || parsedDuration == null || parsedDuration <= 0) {
      _show(l10n?.ls_numeric_price_duration ?? 'Enter a numeric price and a duration above zero');
      return;
    }
    try {
      final DioApiResponse response = await _repository.updateOffering(
        offering.id,
        <String, dynamic>{
          'image': imagePath,
          'price': parsedPrice,
          'durationMinutes': parsedDuration,
        },
      );
      _ensureOk(response);
      await _load();
    } catch (e) {
      _show(l10n?.ls_failed_error('$e') ?? 'Failed: $e');
    }
  }

  LsCatalogueService? _serviceById(String? id) {
    for (final LsCatalogueService service in _services) {
      if (service.id == id) return service;
    }
    return null;
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

  void _show(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Card(
          margin: const EdgeInsets.all(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  AppLocalizations.of(context)?.ls_publish_offering ?? 'Publish an offering',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                InputDecorator(
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)?.ls_service ?? 'Service',
                    border: const OutlineInputBorder(),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _serviceId,
                      isExpanded: true,
                       hint: Text(AppLocalizations.of(context)?.ls_choose_service ?? 'Choose a service'),
                      items: _services
                          .map(
                            (LsCatalogueService service) =>
                                DropdownMenuItem<String>(
                                  value: service.id,
                                  child: Text(
                                    '${service.name} · ${service.pricingMode}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                          )
                          .toList(),
                      onChanged: _selectService,
                    ),
                  ),
                ),
                if (_loadingVariants)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: LinearProgressIndicator(),
                  ),
                if (_variants.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 12),
                  InputDecorator(
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)?.ls_variant ?? 'Variant',
                      border: const OutlineInputBorder(),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _variantId,
                        isExpanded: true,
                        hint: Text(AppLocalizations.of(context)?.ls_choose_variant ?? 'Choose a variant'),
                        items: _variants
                            .map(
                              (
                                LsCatalogueVariant variant,
                              ) => DropdownMenuItem<String>(
                                value: variant.id,
                                child: Text(
                                  '${variant.name} · ${variant.durationMinutes} min',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: _selectVariant,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: _price,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)?.ls_your_price ?? 'Your price',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _duration,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)?.ls_duration_minutes ?? 'Duration (min)',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _saving ? null : _create,
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(AppLocalizations.of(context)?.ls_add ?? 'Add'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_imagePath == null)
                  OutlinedButton.icon(
                    onPressed: _uploadingImage ? null : _addImage,
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: Text(AppLocalizations.of(context)?.ls_add_photo ?? 'Add photo'),
                  )
                else
                  Stack(
                    children: <Widget>[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          _resolveImageUrl(_imagePath!),
                          width: 84,
                          height: 84,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (
                                BuildContext context,
                                Object error,
                                StackTrace? stack,
                              ) => Container(
                                width: 84,
                                height: 84,
                                color: Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                                child: const Icon(Icons.broken_image_outlined),
                              ),
                        ),
                      ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: IconButton.filledTonal(
                          visualDensity: VisualDensity.compact,
                          onPressed: _uploadingImage
                              ? null
                              : () => setState(() => _imagePath = null),
                          icon: const Icon(Icons.close, size: 16),
                        ),
                      ),
                    ],
                  ),
                if (_uploadingImage) ...<Widget>[
                  const SizedBox(height: 8),
                  const LinearProgressIndicator(),
                ],
              ],
            ),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(_error!, textAlign: TextAlign.center),
                      TextButton(onPressed: _load, child: Text(AppLocalizations.of(context)?.ls_retry ?? 'Retry')),
                    ],
                  ),
                )
              : _items.isEmpty
              ? Center(child: Text(AppLocalizations.of(context)?.ls_no_offerings ?? 'No offerings yet'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    itemCount: _items.length,
                    itemBuilder: (BuildContext context, int i) {
                      final LsOffering o = _items[i];
                      final String serviceName = o.serviceName.isEmpty
                          ? o.serviceId
                          : o.serviceName;
                      final String variantName = o.variantName.isEmpty
                          ? ''
                          : ' · ${o.variantName}';
                      return ListTile(
                        leading: o.image.isEmpty
                            ? const Icon(Icons.miscellaneous_services_outlined)
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  _resolveImageUrl(o.image),
                                  width: 44,
                                  height: 44,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (
                                        BuildContext context,
                                        Object error,
                                        StackTrace? stack,
                                      ) => const Icon(
                                        Icons.broken_image_outlined,
                                      ),
                                ),
                              ),
                        title: Text('$serviceName$variantName'),
                        subtitle: Text(
                          '₹${o.price} · ${o.durationMinutes} min · ${o.status}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            IconButton(
                              onPressed: () => _edit(o),
                              icon: const Icon(Icons.edit_outlined),
                              tooltip: AppLocalizations.of(context)?.ls_edit_price ?? 'Edit price',
                            ),
                            if (o.status == 'draft')
                              TextButton(
                                onPressed: () => _submit(o),
                                child: Text(AppLocalizations.of(context)?.ls_submit ?? 'SUBMIT'),
                              ),
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
