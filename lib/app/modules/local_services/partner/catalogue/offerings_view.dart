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

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:partner/app/core/config/api_request_service.dart';
import 'package:partner/app/env.dart';
import 'package:partner/app/modules/local_services/models/provider.dart';
import 'package:partner/app/modules/local_services/partner/shared/ls_ui.dart';
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
  double _imageProgress = 0.0;
  String? _error;
  String? _categoryId;
  String? _subcategoryId;
  String? _serviceId;
  String? _variantId;
  String? _imagePath;
  List<LsCatalogueService> _services = const <LsCatalogueService>[];
  List<LsCatalogueCategory> _categories = const <LsCatalogueCategory>[];
  List<LsCatalogueCategory> _subcategories = const <LsCatalogueCategory>[];
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
      final DioApiResponse offeringsRes = await _repository.offerings();
      _ensureOk(offeringsRes);
      final List<dynamic> offeringRows =
          (decodeBody(offeringsRes)['results'] ?? <dynamic>[]) as List<dynamic>;

      // Fetch the full service catalogue (paginated) so it is not truncated at
      // the first page.
      final List<dynamic> serviceRows = <dynamic>[];
      int page = 1;
      bool hasMore = true;
      while (hasMore) {
        final DioApiResponse svcRes =
            await _repository.publicServices(page: page, limit: 100);
        _ensureOk(svcRes);
        final Map<String, dynamic> body = decodeBody(svcRes);
        final List<dynamic> rows =
            (body['results'] ?? <dynamic>[]) as List<dynamic>;
        serviceRows.addAll(rows);
        hasMore = body['hasMore'] == true;
        page++;
        if (rows.isEmpty) break;
      }
      final List<LsCatalogueService> services = serviceRows
          .whereType<Map<String, dynamic>>()
          .map(LsCatalogueService.fromJson)
          .toList()
        ..sort((LsCatalogueService a, LsCatalogueService b) {
          final int c = a.categoryKey.compareTo(b.categoryKey);
          if (c != 0) return c;
          return a.name.compareTo(b.name);
        });
      // Taxonomy is optional: if the categories endpoint is unavailable the
      // catalogue still works as a flat service list.
      List<LsCatalogueCategory> parentCategories =
          const <LsCatalogueCategory>[];
      List<LsCatalogueCategory> childCategories =
          const <LsCatalogueCategory>[];
      try {
        final DioApiResponse categoriesRes =
            await _repository.publicCategories();
        if ((categoriesRes.statusCode ?? 0) < 400) {
          final List<dynamic> categoryRows =
              (decodeBody(categoriesRes)['results'] ?? <dynamic>[])
                  as List<dynamic>;
          final List<LsCatalogueCategory> categories = categoryRows
              .whereType<Map<String, dynamic>>()
              .map(LsCatalogueCategory.fromJson)
              .toList();
          parentCategories = categories
              .where((LsCatalogueCategory c) => c.parent.isEmpty)
              .toList()
            ..sort(
              (LsCatalogueCategory a, LsCatalogueCategory b) =>
                  a.name.compareTo(b.name),
            );
          childCategories = categories
              .where((LsCatalogueCategory c) => c.parent.isNotEmpty)
              .toList()
            ..sort(
              (LsCatalogueCategory a, LsCatalogueCategory b) =>
                  a.name.compareTo(b.name),
            );
        }
      } catch (_) {
        // Keep the flat catalogue when taxonomy cannot be loaded.
      }
      final bool selectedExists = services.any(
        (LsCatalogueService s) => s.id == _serviceId,
      );
      setState(() {
        _items = offeringRows
            .whereType<Map<String, dynamic>>()
            .map(LsOffering.fromJson)
            .toList();
        _services = services;
        _categories = parentCategories;
        _subcategories = childCategories;
        if (!_categories.any(
          (LsCatalogueCategory c) => c.id == _categoryId,
        )) {
          _categoryId = null;
          _subcategoryId = null;
        }
        if (!_subcategories.any(
          (LsCatalogueCategory c) => c.id == _subcategoryId,
        )) {
          _subcategoryId = null;
        }
        if (!selectedExists) {
          _serviceId = null;
          _variantId = null;
          _variants = const <LsCatalogueVariant>[];
        } else if (!_filteredServices.any(
          (LsCatalogueService s) => s.id == _serviceId,
        )) {
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

  void _selectCategory(String? id) {
    setState(() {
      _categoryId = id;
      _subcategoryId = null;
      _serviceId = null;
      _variantId = null;
      _variants = const <LsCatalogueVariant>[];
    });
  }

  void _selectSubcategory(String? id) {
    setState(() {
      _subcategoryId = id;
      _serviceId = null;
      _variantId = null;
      _variants = const <LsCatalogueVariant>[];
    });
  }

  List<LsCatalogueCategory> get _childCategories {
    final String? categoryId = _categoryId;
    if (categoryId == null) return const <LsCatalogueCategory>[];
    return _subcategories
        .where((LsCatalogueCategory c) => c.parent == categoryId)
        .toList();
  }

  void _collectDescendants(String parentId, Set<String> out) {
    for (final LsCatalogueCategory category in _subcategories) {
      if (category.parent == parentId && out.add(category.id)) {
        _collectDescendants(category.id, out);
      }
    }
  }

  List<LsCatalogueService> get _filteredServices {
    final String? categoryId = _subcategoryId ?? _categoryId;
    if (categoryId == null || categoryId.isEmpty) {
      return _services;
    }
    final Set<String> allowed = <String>{categoryId};
    _collectDescendants(categoryId, allowed);
    return _services
        .where((LsCatalogueService s) => allowed.contains(s.category))
        .toList();
  }

  String _categoryLabel(String categoryId) {
    for (final LsCatalogueCategory category in _categories) {
      if (category.id == categoryId) return category.name;
    }
    for (final LsCatalogueCategory category in _subcategories) {
      if (category.id == categoryId) return category.name;
    }
    return '';
  }

  String _serviceLabel(LsCatalogueService service) {
    final String resolved = _categoryLabel(service.category);
    final String category =
        resolved.isNotEmpty ? resolved : service.categoryKey;
    return category.isEmpty
        ? '${service.name} · ${service.pricingMode}'
        : '${service.name} · $category · ${service.pricingMode}';
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

  Future<String?> _uploadOfferingPhoto(XFile photo, {void Function(int sent, int total)? onSendProgress}) async {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    try {
      final DioApiResponse response = await _repository.uploadOfferingImage(
        filePath: photo.path,
        filename: photo.name,
        onSendProgress: onSendProgress,
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
    // Compress to keep uploads under the 10 MB server cap.
    XFile uploadPhoto = photo;
    try {
      final Directory tmp = await getTemporaryDirectory();
      final String target = '${tmp.path}/offering_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final XFile? compressed = await FlutterImageCompress.compressAndGetFile(
        photo.path,
        target,
        quality: 80,
        minWidth: 1600,
      );
      if (compressed != null) uploadPhoto = compressed;
    } catch (_) {
      // fall back to original
    }
    if (!mounted) return;
    setState(() {
      _uploadingImage = true;
      _imageProgress = 0.0;
    });
    final String? path = await _uploadOfferingPhoto(
      uploadPhoto,
      onSendProgress: (int sent, int total) {
        if (!mounted || total <= 0) return;
        setState(() => _imageProgress = sent / total);
      },
    );
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
    if (_categories.isNotEmpty && _categoryId == null) {
      _show('Choose a category first');
      return;
    }
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
                if (_categories.isNotEmpty) ...<Widget>[
                  InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _categoryId,
                        isExpanded: true,
                        hint: const Text('Choose a category'),
                        items: _categories
                            .map(
                              (LsCatalogueCategory category) =>
                                  DropdownMenuItem<String>(
                                    value: category.id,
                                    child: Text(
                                      category.name,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                            )
                            .toList(),
                        onChanged: _selectCategory,
                      ),
                    ),
                  ),
                  if (_categoryId != null && _childCategories.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 12),
                    InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Subcategory (optional)',
                        border: OutlineInputBorder(),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _subcategoryId,
                          isExpanded: true,
                          hint: const Text('All subcategories'),
                          items: _childCategories
                              .map(
                                (LsCatalogueCategory category) =>
                                    DropdownMenuItem<String>(
                                      value: category.id,
                                      child: Text(
                                        category.name,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                              )
                              .toList(),
                          onChanged: _selectSubcategory,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                ],
                InputDecorator(
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)?.ls_service ?? 'Service',
                    border: const OutlineInputBorder(),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _serviceId,
                      isExpanded: true,
                      hint: Text(
                        _categories.isNotEmpty && _categoryId == null
                            ? 'Choose a category first'
                            : AppLocalizations.of(context)?.ls_choose_service ?? 'Choose a service',
                      ),
                      items: _filteredServices
                          .map(
                            (LsCatalogueService service) =>
                                DropdownMenuItem<String>(
                                  value: service.id,
                                  child: Text(
                                    _serviceLabel(service),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                          )
                          .toList(),
                      onChanged: (_categories.isNotEmpty && _categoryId == null)
                          ? null
                          : _selectService,
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
                   LinearProgressIndicator(value: _imageProgress > 0 ? _imageProgress : null),
                 ],
              ],
            ),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
               : _error != null
               ? LsErrorState(message: _error!, onRetry: _load)
               : _items.isEmpty
               ? LsEmptyState(
                   icon: Icons.storefront_outlined,
                   title: AppLocalizations.of(context)?.ls_no_offerings ?? 'No offerings yet',
                   subtitle: 'Publish your first offering above.',
                 )
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
                       return Card(
                         margin: const EdgeInsets.only(bottom: 8),
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                         child: Padding(
                           padding: const EdgeInsets.all(12),
                           child: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: <Widget>[
                               Row(
                                 children: <Widget>[
                                   o.image.isEmpty
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
                                   const SizedBox(width: 12),
                                   Expanded(
                                     child: Column(
                                       crossAxisAlignment: CrossAxisAlignment.start,
                                       children: <Widget>[
                                         Text('$serviceName$variantName', style: const TextStyle(fontWeight: FontWeight.w600)),
                                         const SizedBox(height: 2),
                                         Text('₹${o.price} · ${o.durationMinutes} min', style: const TextStyle(fontSize: 12)),
                                       ],
                                     ),
                                   ),
                                   LsStatusBadge(status: o.status),
                                 ],
                               ),
                               const SizedBox(height: 8),
                               Row(
                                 mainAxisAlignment: MainAxisAlignment.end,
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
                             ],
                           ),
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
