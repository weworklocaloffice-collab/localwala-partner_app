import 'dart:convert';

import 'package:image_picker/image_picker.dart';
import 'package:partner/app/core/config/api_request_service.dart';
import 'package:partner/app/env.dart';
import 'package:partner/app/core/repositories/partner_repository.dart';
import 'package:flutter/material.dart';

/// Adds an outlet-owned product and its first inventory-bearing pack (SKU).
/// Categories, sub-categories and brands are read from the Admin-managed dairy
/// taxonomy; this screen only lets the partner choose among them.
class PartnerProductCreateScreen extends StatefulWidget {
  const PartnerProductCreateScreen({
    super.key,
    required this.repository,
  });

  final PartnerRepository repository;

  @override
  State<PartnerProductCreateScreen> createState() =>
      _PartnerProductCreateScreenState();
}

class _PartnerProductCreateScreenState
    extends State<PartnerProductCreateScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _packController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _mrpController = TextEditingController();
  final TextEditingController _stockController = TextEditingController(
    text: '0',
  );
  final ImagePicker _imagePicker = ImagePicker();

  bool _loadingTaxonomy = true;
  bool _loadingSubCategories = false;
  bool _saving = false;
  bool _uploadingImages = false;
  String? _error;
  String? _savedProductId;
  String? _selectedCategory;
  String? _selectedSubCategory;
  String? _selectedBrand;
  String _unit = 'litre';
  List<Map<String, dynamic>> _categories = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _subCategories = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _brands = <Map<String, dynamic>>[];
  final List<String> _imageUrls = <String>[];

  @override
  void initState() {
    super.initState();
    _loadTaxonomy();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _packController.dispose();
    _priceController.dispose();
    _mrpController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _readRows(
    DioApiResponse response,
    String key,
  ) {
    final dynamic rows = decodeBody(response)[key];
    if (rows is! List) return <Map<String, dynamic>>[];
    return rows
        .whereType<Map>()
        .map((Map row) => Map<String, dynamic>.from(row))
        .toList();
  }

  String? _id(Map<String, dynamic> row) =>
      (row['_id'] ?? row['id'])?.toString();

  Future<void> _loadTaxonomy() async {
    setState(() {
      _loadingTaxonomy = true;
      _error = null;
    });
    final List<DioApiResponse> responses = await Future.wait(<Future<DioApiResponse>>[
      widget.repository.dairyCategories(),
      widget.repository.dairyBrands(),
    ]);
    if (!mounted) return;
    if (responses.any((DioApiResponse response) => response.errorType != NetErrorType.none)) {
      setState(() {
        _loadingTaxonomy = false;
        _error = 'Could not load Admin product categories. Check your connection and retry.';
      });
      return;
    }
    setState(() {
      _categories = _readRows(responses[0], 'categories');
      _brands = _readRows(responses[1], 'brands');
      _loadingTaxonomy = false;
    });
  }

  Future<void> _loadSubCategories(String categoryId) async {
    setState(() {
      _loadingSubCategories = true;
      _subCategories = <Map<String, dynamic>>[];
      _selectedSubCategory = null;
    });
    final DioApiResponse response = await widget.repository.dairySubCategories(categoryId);
    if (!mounted) return;
    setState(() {
      _loadingSubCategories = false;
      if (response.errorType == NetErrorType.none) {
        _subCategories = _readRows(response, 'subCategories');
      }
    });
  }

  Future<void> _pickProductImages() async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (BuildContext context) => SafeArea(
        child: Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    final int remaining = 5 - _imageUrls.length;
    if (remaining <= 0) return;
    List<XFile> photos;
    try {
      if (source == ImageSource.gallery) {
        photos = await _imagePicker.pickMultiImage(
          maxWidth: 1600,
          imageQuality: 80,
        );
      } else {
        final XFile? photo = await _imagePicker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1600,
          imageQuality: 80,
        );
        photos = photo == null ? <XFile>[] : <XFile>[photo];
      }
    } on Exception {
      if (mounted) _showError('Could not open photos. Check app permissions and try again.');
      return;
    }
    if (!mounted || photos.isEmpty) return;

    setState(() => _uploadingImages = true);
    int uploaded = 0;
    bool failed = false;
    for (final XFile photo in photos.take(remaining)) {
      DioApiResponse response;
      try {
        response = await widget.repository.uploadProductImage(
          filePath: photo.path,
          filename: photo.name,
        );
      } on Exception {
        if (!mounted) return;
        failed = true;
        continue;
      }
      if (!mounted) return;
      if (response.errorType != NetErrorType.none) {
        failed = true;
        continue;
      }
      String? path;
      try {
        final Map<String, dynamic> upload = decodeBody(response);
        path = (upload['path'] ?? upload['fileUrl'])?.toString();
      } on FormatException {
        failed = true;
        continue;
      }
      if (path == null || path.isEmpty) {
        failed = true;
        continue;
      }
      final String uploadedPath = path;
      setState(() => _imageUrls.add(uploadedPath));
      uploaded++;
    }
    if (!mounted) return;
    setState(() => _uploadingImages = false);
    if (failed) {
      _showError(
        uploaded == 0
            ? 'The selected photo could not be uploaded. Check your connection and try again.'
            : 'Some photos could not be uploaded. You can retry adding them.',
      );
    }
  }

  String _resolveImageUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    final String base = Environments.apiBaseURL.endsWith('/')
        ? Environments.apiBaseURL.substring(0, Environments.apiBaseURL.length - 1)
        : Environments.apiBaseURL;
    final String key = url.startsWith('/') ? url.substring(1) : url;
    return '$base/storage/$key';
  }

  String _responseMessage(DioApiResponse response) {
    final dynamic data = response.response?.data;
    if (data is String) {
      try {
        final dynamic decoded = jsonDecode(data);
        if (decoded is Map && decoded['message'] != null) {
          return decoded['message'].toString();
        }
      } on FormatException {
        // Fall through to the status-based message.
      }
    } else if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    return 'Request failed${response.statusCode == null ? '' : ' (${response.statusCode})'}.';
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    String? productId = _savedProductId;
    if (productId == null) {
      final DioApiResponse productResponse = await widget.repository.createProduct(
        <String, dynamic>{
          'name': _nameController.text.trim(),
          'category': _selectedCategory,
          'images': List<String>.from(_imageUrls),
          if (_selectedSubCategory != null) 'subCategory': _selectedSubCategory,
          if (_selectedBrand != null) 'brand': _selectedBrand,
        },
      );
      if (productResponse.errorType != NetErrorType.none) {
        if (mounted) {
          setState(() => _saving = false);
          _showError('Could not save product: ${_responseMessage(productResponse)}');
        }
        return;
      }
      final Map<String, dynamic> product =
          (decodeBody(productResponse)['product'] as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{};
      productId = (product['_id'] ?? product['id'])?.toString();
      if (productId == null || productId.isEmpty) {
        if (mounted) {
          setState(() => _saving = false);
          _showError('Product was saved, but the server did not return its ID. Refresh and check your product list.');
        }
        return;
      }
      _savedProductId = productId;
    }

    final double packQuantity = double.parse(_packController.text.trim());
    final int startingStock = int.parse(_stockController.text.trim());
    final String productName = _nameController.text.trim();
    final String packValue = _packController.text.trim();
    final DioApiResponse skuResponse = await widget.repository.createSku(
      <String, dynamic>{
        'product': productId,
        'name': '$productName - $packValue $_unit',
        'packSize': <String, dynamic>{
          'value': packValue,
          'unit': _unit,
          'quantity': packQuantity,
        },
        'price': double.parse(_priceController.text.trim()),
        if (_mrpController.text.trim().isNotEmpty)
          'mrp': double.parse(_mrpController.text.trim()),
        'availableQty': startingStock,
        'inStock': startingStock > 0,
      },
    );

    if (!mounted) return;
    setState(() => _saving = false);
    if (skuResponse.errorType != NetErrorType.none) {
      _showError('Product saved, but its pack and starting stock were not: ${_responseMessage(skuResponse)}. Retry to save the pack.');
      return;
    }
    Navigator.of(context).pop(true);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String? _requiredText(String? value) =>
      value == null || value.trim().isEmpty ? 'Required' : null;

  String? _positiveNumber(String? value) {
    final double? number = double.tryParse(value?.trim() ?? '');
    if (number == null || number <= 0) return 'Enter a number greater than zero';
    return null;
  }

  String? _nonNegativeNumber(String? value) {
    final double? number = double.tryParse(value?.trim() ?? '');
    if (number == null || number < 0) return 'Enter zero or a positive number';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add product to inventory')),
      body: _loadingTaxonomy
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    OutlinedButton(onPressed: _loadTaxonomy, child: const Text('Retry')),
                  ],
                ),
              ),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: <Widget>[
                  if (_savedProductId != null)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Text('Product saved. Complete the pack and stock details below.'),
                      ),
                    ),
                  Text('Product details', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  _productImagesSection(context),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const ValueKey<String>('dairy-product-name'),
                    controller: _nameController,
                    enabled: _savedProductId == null,
                    decoration: const InputDecoration(labelText: 'Product name'),
                    validator: _requiredText,
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(labelText: 'Admin category'),
                    items: _categories.map((Map<String, dynamic> category) {
                      final String? id = _id(category);
                      return DropdownMenuItem<String>(
                        value: id,
                        child: Text(category['name']?.toString() ?? 'Category'),
                      );
                    }).toList(),
                    onChanged: _savedProductId != null || _categories.isEmpty
                        ? null
                        : (String? value) {
                            if (value == null) return;
                            setState(() => _selectedCategory = value);
                            _loadSubCategories(value);
                          },
                    validator: (String? value) => value == null ? 'Choose a category' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedSubCategory,
                    decoration: InputDecoration(
                      labelText: _loadingSubCategories ? 'Loading sub-categories…' : 'Sub-category (optional)',
                    ),
                    items: _subCategories.map((Map<String, dynamic> subCategory) {
                      final String? id = _id(subCategory);
                      return DropdownMenuItem<String>(
                        value: id,
                        child: Text(subCategory['name']?.toString() ?? 'Sub-category'),
                      );
                    }).toList(),
                    onChanged: _savedProductId != null || _loadingSubCategories
                        ? null
                        : (String? value) => setState(() => _selectedSubCategory = value),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedBrand,
                    decoration: const InputDecoration(labelText: 'Brand (optional)'),
                    items: <DropdownMenuItem<String>>[
                      const DropdownMenuItem<String>(value: null, child: Text('No brand')),
                      ..._brands.map((Map<String, dynamic> brand) {
                        final String? id = _id(brand);
                        return DropdownMenuItem<String>(
                          value: id,
                          child: Text(brand['name']?.toString() ?? 'Brand'),
                        );
                      }),
                    ],
                    onChanged: _savedProductId != null
                        ? null
                        : (String? value) => setState(() => _selectedBrand = value),
                  ),
                  const SizedBox(height: 24),
                  Text('Pack and inventory', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: TextFormField(
                          key: const ValueKey<String>('dairy-pack-size'),
                          controller: _packController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Pack size'),
                          validator: _positiveNumber,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _unit,
                          decoration: const InputDecoration(labelText: 'Unit'),
                          items: const <DropdownMenuItem<String>>[
                            DropdownMenuItem(value: 'litre', child: Text('litre')),
                            DropdownMenuItem(value: 'ml', child: Text('ml')),
                            DropdownMenuItem(value: 'g', child: Text('g')),
                            DropdownMenuItem(value: 'kg', child: Text('kg')),
                            DropdownMenuItem(value: 'piece', child: Text('piece')),
                          ],
                          onChanged: (String? value) {
                            if (value != null) setState(() => _unit = value);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const ValueKey<String>('dairy-product-price'),
                    controller: _priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Selling price (₹)'),
                    validator: _nonNegativeNumber,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const ValueKey<String>('dairy-product-mrp'),
                    controller: _mrpController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'MRP (optional, ₹)'),
                    validator: (String? value) =>
                        value == null || value.trim().isEmpty ? null : _nonNegativeNumber(value),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const ValueKey<String>('dairy-starting-stock'),
                    controller: _stockController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Starting stock (packs)'),
                    validator: (String? value) {
                      final int? number = int.tryParse(value?.trim() ?? '');
                      return number == null || number < 0
                          ? 'Enter zero or a positive whole number'
                          : null;
                    },
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _saving || _uploadingImages || _categories.isEmpty
                        ? null
                        : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(_savedProductId == null ? 'Save product and stock' : 'Retry saving pack'),
                  ),
                  if (_categories.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Text('No active dairy categories are available. Ask Admin to add or enable categories.'),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _productImagesSection(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Product photos', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              'Add up to 5 clear photos so customers can recognize the product.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            if (_imageUrls.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _imageUrls.asMap().entries.map((MapEntry<int, String> entry) {
                  return Stack(
                    children: <Widget>[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          _resolveImageUrl(entry.value),
                          width: 84,
                          height: 84,
                          fit: BoxFit.cover,
                          errorBuilder: (BuildContext context, Object error, StackTrace? stack) =>
                              Container(
                                width: 84,
                                height: 84,
                                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                child: const Icon(Icons.broken_image_outlined),
                              ),
                        ),
                      ),
                      if (_savedProductId == null)
                        Positioned(
                          top: 2,
                          right: 2,
                          child: IconButton.filledTonal(
                            visualDensity: VisualDensity.compact,
                            onPressed: () => setState(() => _imageUrls.removeAt(entry.key)),
                            icon: const Icon(Icons.close, size: 16),
                          ),
                        ),
                    ],
                  );
                }).toList(),
              ),
            if (_uploadingImages) ...<Widget>[
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
            ],
            if (_savedProductId == null && _imageUrls.length < 5)
              OutlinedButton.icon(
                onPressed: _uploadingImages ? null : _pickProductImages,
                icon: const Icon(Icons.add_a_photo_outlined),
                label: Text(_imageUrls.isEmpty ? 'Add product photos' : 'Add another photo'),
              ),
          ],
        ),
      ),
    );
  }
}
