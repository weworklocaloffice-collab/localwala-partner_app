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

import 'package:partner/app/presentation/styles/theme.dart';
import 'package:partner/gen/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:partner/app/modules/stores/stores_partner_repository.dart';
import 'package:partner/app/modules/stores/widgets/stores_ui_states.dart';

class StoresProductFormScreen extends StatefulWidget {
  const StoresProductFormScreen({
    super.key,
    required this.repository,
    this.productId,
  });

  final StoresPartnerRepository repository;
  final String? productId;

  @override
  State<StoresProductFormScreen> createState() => _StoresProductFormScreenState();
}

class _StoresProductFormScreenState extends State<StoresProductFormScreen> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _description = TextEditingController();
  final TextEditingController _images = TextEditingController();
  final TextEditingController _basePrice = TextEditingController();
  final TextEditingController _baseMrp = TextEditingController();
  final TextEditingController _taxPercentage = TextEditingController();
  final TextEditingController _hsn = TextEditingController();
  final TextEditingController _tags = TextEditingController();
  final TextEditingController _brandSearch = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String? _error;

  String? _productId;
  List<Map<String, dynamic>> _categories = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _subcategories = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _brands = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _attributes = <Map<String, dynamic>>[];
  final Map<String, TextEditingController> _attributeControllers = <String, TextEditingController>{};
  Map<String, dynamic>? _initialAttributes;

  String? _categoryId;
  String? _subcategoryId;
  String? _brandId;
  String _tax = 'inclusive';
  String _status = 'active';
  bool _isOrganic = false;
  bool _hasVariants = false;
  int _combinationLimit = 200;

  final Set<String> _selectedAxisIds = <String>{};
  final Map<String, Set<String>> _axisValues = <String, Set<String>>{};

  @override
  void initState() {
    super.initState();
    _productId = widget.productId;
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _images.dispose();
    _basePrice.dispose();
    _baseMrp.dispose();
    _taxPercentage.dispose();
    _hsn.dispose();
    _tags.dispose();
    _brandSearch.dispose();
    for (final TextEditingController controller in _attributeControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final List<Map<String, dynamic>> categories = await widget.repository.categories();
      final List<Map<String, dynamic>> brands = await widget.repository.brands();

      if (!mounted) return;
      _categories = categories;
      _brands = brands;

      if (_productId != null) {
        final Map<String, dynamic> body = await widget.repository.catalogueProduct(_productId!);
        final dynamic raw = body['product'] ?? body;
        if (raw is Map<String, dynamic>) {
          _applyProduct(raw);
        }

        final String? category = _idOf(raw is Map<String, dynamic> ? raw['category'] : null);
        if (category != null) {
          _subcategories = await widget.repository.subcategories(category: category);
          if (!mounted) return;
          await _loadForm(category, _idOf(raw is Map<String, dynamic> ? raw['subcategory'] : null));
          if (!mounted) return;
          if (_selectedAxisIds.isEmpty && _hasVariants) {
            _selectedAxisIds.addAll(_variantTemplates.map(_axisId));
          }
        }
      }

      if (!mounted) return;
      setState(() => _loading = false);
    } on StoresApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    }
  }

  void _applyProduct(Map<String, dynamic> product) {
    _name.text = '${product['name'] ?? ''}';
    _description.text = '${product['description'] ?? ''}';
    _images.text = ((product['images'] as List?) ?? const <dynamic>[]).join(', ');
    _basePrice.text = product['basePrice']?.toString() ?? '';
    _baseMrp.text = product['baseMrp']?.toString() ?? '';
    _taxPercentage.text = product['taxPercentage']?.toString() ?? '';
    _hsn.text = '${product['hsn'] ?? ''}';
    _tags.text = ((product['tags'] as List?) ?? const <dynamic>[]).join(', ');
    _categoryId = _idOf(product['category']);
    _subcategoryId = _idOf(product['subcategory']);
    _brandId = _idOf(product['brand']);
    _tax = '${product['tax'] ?? product['taxType'] ?? 'inclusive'}';
    _status = '${product['status'] ?? 'active'}';
    _isOrganic = product['isOrganic'] == true;
    _hasVariants = product['hasVariants'] == true || product['variantsEnabled'] == true;
    final dynamic rawAttributes = product['attributes'];
    _initialAttributes = rawAttributes is Map
        ? Map<String, dynamic>.from(rawAttributes)
        : null;
    _selectedAxisIds
      ..clear()
      ..addAll(((product['variantAxes'] as List?) ?? const <dynamic>[])
          .map(_idOf)
          .whereType<String>());
    _axisValues.clear();

    final dynamic variants = product['variants'];
    if (variants is List) {
      for (final dynamic variant in variants) {
        final dynamic facetKeys = variant is Map ? variant['facetKeys'] : null;
        if (facetKeys is! List) continue;
        for (final dynamic key in facetKeys) {
          final String raw = '$key';
          final int separator = raw.indexOf(':');
          if (separator <= 0) continue;
          _axisValues
              .putIfAbsent(raw.substring(0, separator), () => <String>{})
              .add(raw.substring(separator + 1));
        }
      }
    }
  }

  Future<void> _loadForm(String category, String? subcategory) async {
    try {
      final Map<String, dynamic> form = await widget.repository.productForm(
        category: category,
        subcategory: subcategory,
      );
      if (!mounted) return;
      setState(() {
        final dynamic attributes = form['attributes'];
        _attributes = attributes is List
            ? attributes.whereType<Map<String, dynamic>>().toList()
            : <Map<String, dynamic>>[];
        final dynamic variants = form['variants'];
        if (variants is Map<String, dynamic>) {
          _combinationLimit = (variants['combinationLimit'] as num?)?.toInt() ?? 200;
        }
      });
      _syncAttributeControllers();
    } on StoresApiException {
      if (!mounted) return;
      setState(() => _attributes = <Map<String, dynamic>>[]);
    }
  }

  void _syncAttributeControllers() {
    final Set<String> slugs = _attributes
        .map((Map<String, dynamic> attr) =>
            '${attr['slug'] ?? attr['name'] ?? ''}')
        .where((String slug) => slug.isNotEmpty)
        .toSet();

    final List<String> toRemove = _attributeControllers.keys
        .where((String key) => !slugs.contains(key))
        .toList();
    for (final String key in toRemove) {
      _attributeControllers[key]?.dispose();
      _attributeControllers.remove(key);
    }

    for (final Map<String, dynamic> attr in _attributes) {
      final String slug = '${attr['slug'] ?? attr['name'] ?? ''}';
      if (slug.isEmpty || _attributeControllers.containsKey(slug)) continue;
      final TextEditingController controller = TextEditingController();
      final dynamic initial = _initialAttributes?[slug];
      if (initial != null) controller.text = '$initial';
      _attributeControllers[slug] = controller;
    }
  }

  Future<void> _onCategoryChanged(String? category) async {
    if (category == null) return;
    setState(() {
      _categoryId = category;
      _subcategoryId = null;
      _subcategories = <Map<String, dynamic>>[];
      _attributes = <Map<String, dynamic>>[];
      _selectedAxisIds.clear();
      _axisValues.clear();
    });

    try {
      final List<Map<String, dynamic>> subcategories =
          await widget.repository.subcategories(category: category);
      if (!mounted) return;
      setState(() => _subcategories = subcategories);
    } on StoresApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }

    await _loadForm(category, null);
  }

  Future<void> _onSubcategoryChanged(String? subcategory) async {
    if (subcategory == null || _categoryId == null) return;
    setState(() {
      _subcategoryId = subcategory;
      _selectedAxisIds.clear();
      _axisValues.clear();
    });
    await _loadForm(_categoryId!, subcategory);
  }

  List<Map<String, dynamic>> get _variantTemplates =>
      _attributes.where((Map<String, dynamic> a) => a['variantAxis'] == true).toList();

  String _axisId(Map<String, dynamic> axis) =>
      axis['_id']?.toString() ?? axis['id']?.toString() ?? '';

  String _axisSlug(Map<String, dynamic> axis) => '${axis['slug'] ?? axis['key'] ?? ''}';

  String _axisName(Map<String, dynamic> axis) => '${axis['name'] ?? axis['slug'] ?? 'Option'}';

  List<Map<String, dynamic>> _axisOptions(Map<String, dynamic> axis) {
    final dynamic options = axis['options'];
    if (options is! List) return <Map<String, dynamic>>[];
    return options.map<Map<String, dynamic>>((dynamic option) {
      if (option is Map<String, dynamic>) return option;
      return <String, dynamic>{'value': '$option', 'label': '$option'};
    }).toList();
  }

  void _toggleAxis(Map<String, dynamic> axis, bool selected) {
    final String id = _axisId(axis);
    final String slug = _axisSlug(axis);
    setState(() {
      if (selected) {
        _selectedAxisIds.add(id);
        _axisValues.putIfAbsent(slug, () => <String>{});
      } else {
        _selectedAxisIds.remove(id);
        _axisValues.remove(slug);
      }
    });
  }

  void _toggleValue(String slug, String value) {
    setState(() {
      final Set<String> values = _axisValues.putIfAbsent(slug, () => <String>{});
      if (!values.remove(value)) values.add(value);
    });
  }

  int? _combinationCount() {
    if (!_hasVariants) return 0;
    final List<Map<String, dynamic>> axes = _variantTemplates
        .where((Map<String, dynamic> axis) => _selectedAxisIds.contains(_axisId(axis)))
        .toList();
    if (axes.isEmpty) return 0;

    int count = 1;
    for (final Map<String, dynamic> axis in axes) {
      final Set<String> values = _axisValues[_axisSlug(axis)] ?? <String>{};
      if (values.isEmpty) return null;
      count *= values.length;
    }
    return count;
  }

  Map<String, dynamic> _selections() {
    return <String, dynamic>{
      for (final MapEntry<String, Set<String>> entry in _axisValues.entries)
        if (entry.value.isNotEmpty) entry.key: entry.value.toList(),
    };
  }

  Future<void> _save() async {
    final String name = _name.text.trim();
    if (name.isEmpty) {
      _snack('Product name is required');
      return;
    }
    if (_categoryId == null) {
      _snack('Choose a category');
      return;
    }

    final num? basePrice = _number(_basePrice.text);
    if (basePrice == null) {
      _snack('Base price is required');
      return;
    }

    final int? combinations = _combinationCount();
    if (_hasVariants && _selectedAxisIds.isEmpty) {
      _snack('Select at least one variant axis, or turn variants off.');
      return;
    }
    if (_hasVariants && (combinations == null || combinations == 0)) {
      _snack('Select at least one option for every variant axis.');
      return;
    }
    if (_hasVariants && combinations != null && combinations > _combinationLimit) {
      _snack('$combinations combinations exceeds the limit of $_combinationLimit');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final Map<String, dynamic> body = <String, dynamic>{
        if (_productId == null) 'category': _categoryId,
        'name': name,
        'description': _description.text.trim(),
        'images': _csv(_images.text),
        'hasVariants': _hasVariants,
        if (_hasVariants)
          'variantAxes': _variantTemplates
              .where((Map<String, dynamic> axis) => _selectedAxisIds.contains(_axisId(axis)))
              .map(_axisId)
              .toList(),
        'basePrice': basePrice,
        if (_number(_baseMrp.text) != null) 'baseMrp': _number(_baseMrp.text),
        'tax': _tax,
        'taxPercentage': _number(_taxPercentage.text) ?? 0,
        'hsn': _hsn.text.trim(),
        'tags': _csv(_tags.text),
        'isOrganic': _isOrganic,
        if (_attributeControllers.isNotEmpty)
          'attributes': <String, dynamic>{
            for (final MapEntry<String, TextEditingController> entry
                in _attributeControllers.entries)
              if (entry.value.text.trim().isNotEmpty)
                entry.key: entry.value.text.trim(),
          },
        if (_subcategoryId != null) 'subcategory': _subcategoryId,
        if (_brandId != null) 'brand': _brandId,
        if (_productId != null) 'status': _status,
      };

      String? savedId = _productId;
      if (savedId == null) {
        final Map<String, dynamic> created = await widget.repository.createProduct(body);
        final dynamic raw = created['product'] ?? created;
        savedId = raw is Map<String, dynamic> ? _idOf(raw) : null;
      } else {
        await widget.repository.updateProduct(savedId, body);
      }

      if (_hasVariants && savedId != null && combinations != null && combinations > 0) {
        await widget.repository.generateVariants(savedId, <String, dynamic>{
          'selections': _selections(),
        });
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on StoresApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openBrandRequestDialog() async {
    final bool? requested = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => _BrandRequestDialog(
        repository: widget.repository,
        category: _categoryId,
        subcategory: _subcategoryId,
      ),
    );

    if (requested == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Brand request submitted. It will be selectable once Admin approves it.',
          ),
        ),
      );
    }
  }

  Future<void> _openBrandRequests() async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) =>
          _BrandRequestsDialog(repository: widget.repository),
    );
  }

  Future<void> _openBrandCertificationDialog() async {
    if (_brandId == null) return;
    final bool? submitted = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => _BrandCertificationDialog(
        repository: widget.repository,
        brandId: _brandId!,
      ),
    );
    if (submitted == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.storesMsgBrandCertSubmitted),
        ),
      );
    }
  }

  List<Map<String, dynamic>> get _visibleBrands {
    final String query = _brandSearch.text.trim().toLowerCase();
    if (query.isEmpty) return _brands;

    return _brands.where((Map<String, dynamic> brand) {
      final String name = '${brand['name'] ?? ''}'.toLowerCase();
      final dynamic rawAliases = brand['aliases'];
      final Iterable<String> aliases = rawAliases is List
          ? rawAliases.map((dynamic alias) => '$alias'.toLowerCase())
          : const <String>[];
      return name.contains(query) || aliases.any((String alias) => alias.contains(query));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final bool editing = _productId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? AppLocalizations.of(context)!.storesTitleEditProduct : AppLocalizations.of(context)!.storesTitleNewProduct),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(12),
        child: FilledButton.icon(
          onPressed: _loading || _saving ? null : _save,
          icon: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_outlined),
          label: Text(_saving ? 'Saving…' : l10n.storesActionSave),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: <Widget>[
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: MaterialBanner(
                      content: Text(_error!),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () => setState(() => _error = null),
                          child: Text(l10n.storesActionCancel),
                        ),
                      ],
                    ),
                  ),
                TextField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Product name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _description,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _images,
                  decoration: const InputDecoration(
                    labelText: 'Image URLs (comma separated)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _tags,
                  decoration: const InputDecoration(
                    labelText: 'Tags (comma separated)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const StoresSectionHeader(title: 'Taxonomy'),
                _DropdownField(
                  label: 'Category',
                  value: _categoryId,
                  rows: _categories,
                  onChanged: _saving ? null : _onCategoryChanged,
                ),
                const SizedBox(height: 12),
                _DropdownField(
                  label: 'Subcategory',
                  value: _subcategoryId,
                  rows: _subcategories,
                  onChanged: _saving || _subcategories.isEmpty ? null : _onSubcategoryChanged,
                ),
                const SizedBox(height: 12),
                if (_attributes.isNotEmpty) ...<Widget>[
                  const StoresSectionHeader(title: 'Attributes'),
                  ..._attributes.map((Map<String, dynamic> attr) {
                    final String slug = '${attr['slug'] ?? attr['name'] ?? ''}';
                    final TextEditingController controller =
                        _attributeControllers[slug] ??
                        TextEditingController();
                    _attributeControllers[slug] = controller;
                    final dynamic options = attr['options'];
                    if (options is List && options.isNotEmpty) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _DropdownField(
                          label: '${attr['name'] ?? slug}',
                          value: controller.text.isEmpty ? null : controller.text,
                          rows: options
                              .whereType<Map<String, dynamic>>()
                              .map((Map<String, dynamic> option) => <String, dynamic>{
                                    '_id': '${option['value'] ?? option['label'] ?? ''}',
                                    'name': '${option['label'] ?? option['value'] ?? ''}',
                                  })
                              .toList(),
                          onChanged: _saving
                              ? null
                              : (String? value) =>
                                  setState(() => controller.text = value ?? ''),
                        ),
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextField(
                        controller: controller,
                        decoration: InputDecoration(
                          labelText: '${attr['name'] ?? slug}',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    );
                  }),
                ],
                TextField(
                  controller: _brandSearch,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Search brands (name or alias)',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                _DropdownField(
                  label: 'Brand (approved brands only)',
                  value: _brandId,
                  rows: _visibleBrands
                      .map(
                        (Map<String, dynamic> brand) => Map<String, dynamic>.from(
                          brand,
                        )..['name'] =
                            '${brand['name'] ?? ''}${brand['isVerified'] == true ? ' (verified)' : ''}',
                      )
                      .toList(),
                  emptyHint: _brandSearch.text.trim().isEmpty
                      ? 'None available'
                      : 'No matching brand',
                  onChanged: _saving
                      ? null
                      : (String? value) => setState(() => _brandId = value),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    children: <Widget>[
                      TextButton.icon(
                        onPressed: _saving ? null : _openBrandRequestDialog,
                        icon: const Icon(Icons.add_business_outlined, size: 18),
                        label: Text(AppLocalizations.of(context)!.storesActionRequestBrand),
                      ),
                      TextButton.icon(
                        onPressed: _openBrandRequests,
                        icon: const Icon(Icons.fact_check_outlined, size: 18),
                        label: Text(AppLocalizations.of(context)!.storesTitleMyBrandRequests),
                      ),
                      TextButton.icon(
                        onPressed: _brandId == null || _saving
                            ? null
                            : _openBrandCertificationDialog,
                        icon: const Icon(Icons.verified_outlined, size: 18),
                        label: Text(AppLocalizations.of(context)!.storesActionCertifyBrand),
                      ),
                    ],
                  ),
                ),
                const StoresSectionHeader(title: 'Pricing and tax'),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: _basePrice,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Base price',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _baseMrp,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'MRP',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _DropdownField(
                  label: 'Tax treatment',
                  value: _tax,
                  rows: const <Map<String, dynamic>>[
                    <String, dynamic>{'_id': 'inclusive', 'name': 'Inclusive'},
                    <String, dynamic>{'_id': 'exclusive', 'name': 'Exclusive'},
                    <String, dynamic>{'_id': 'none', 'name': 'No tax'},
                  ],
                  onChanged: _saving ? null : (String? value) => setState(() => _tax = value ?? _tax),
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: _taxPercentage,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Tax %',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _hsn,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'HSN',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                if (editing)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _DropdownField(
                      label: 'Status',
                      value: _status,
                      rows: const <Map<String, dynamic>>[
                        <String, dynamic>{'_id': 'active', 'name': 'Active'},
                        <String, dynamic>{'_id': 'inactive', 'name': 'Inactive'},
                        <String, dynamic>{'_id': 'archived', 'name': 'Archived'},
                      ],
                      onChanged: _saving
                          ? null
                          : (String? value) => setState(() => _status = value ?? _status),
                    ),
                  ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(AppLocalizations.of(context)!.storesLabelOrganicProduct),
                  value: _isOrganic,
                  onChanged: _saving ? null : (bool value) => setState(() => _isOrganic = value),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(AppLocalizations.of(context)!.storesLabelProductHasVariants),
                  value: _hasVariants,
                  onChanged: _saving
                      ? null
                      : (bool value) {
                          setState(() {
                            _hasVariants = value;
                            if (!value) {
                              _selectedAxisIds.clear();
                              _axisValues.clear();
                            }
                          });
                        },
                ),
                if (_hasVariants) _variantSection(),
              ],
            ),
    );
  }

  Widget _variantSection() {
    final List<Map<String, dynamic>> templates = _variantTemplates;
    final int? combinations = _combinationCount();

    if (templates.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(AppLocalizations.of(context)!.storesMsgChooseCategoryVariants),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const StoresSectionHeader(title: 'Variant axes'),
        ...templates.map((Map<String, dynamic> axis) {
          final String id = _axisId(axis);
          final String slug = _axisSlug(axis);
          final bool selected = _selectedAxisIds.contains(id);
          final List<Map<String, dynamic>> options = _axisOptions(axis);
          final Set<String> values = _axisValues[slug] ?? <String>{};

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_axisName(axis)),
                value: selected,
                onChanged: _saving
                    ? null
                    : (bool? value) => _toggleAxis(axis, value ?? false),
              ),
              if (selected)
                Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: options.map((Map<String, dynamic> option) {
                      final String value = '${option['value'] ?? option['label'] ?? ''}';
                      return FilterChip(
                        label: Text('${option['label'] ?? value}'),
                        selected: values.contains(value),
                        onSelected: _saving ? null : (_) => _toggleValue(slug, value),
                      );
                    }).toList(),
                  ),
                ),
            ],
          );
        }),
        if (combinations != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            child: Text(
              combinations > _combinationLimit
                  ? '$combinations combinations exceeds the limit of $_combinationLimit'
                  : '$combinations combination(s) will be generated',
              style: TextStyle(
                color: combinations > _combinationLimit ? AppColors.expired : null,
              ),
            ),
          ),
      ],
    );
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.rows,
    required this.onChanged,
    this.emptyHint = 'None available',
  });

  final String label;
  final String? value;
  final List<Map<String, dynamic>> rows;
  final ValueChanged<String?>? onChanged;
  final String emptyHint;

  @override
  Widget build(BuildContext context) {
    final bool hasValue = value != null && rows.any((Map<String, dynamic> row) => _id(row) == value);

    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: hasValue ? value : null,
          hint: Text(rows.isEmpty ? emptyHint : 'Select'),
          items: rows.map((Map<String, dynamic> row) {
            return DropdownMenuItem<String>(
              value: _id(row),
              child: Text('${row['name'] ?? row['label'] ?? row['_id']}'),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  static String _id(Map<String, dynamic> row) =>
      row['_id']?.toString() ?? row['id']?.toString() ?? '';
}

String? _idOf(dynamic value) {
  if (value is Map) return value['_id']?.toString() ?? value['id']?.toString();
  return value?.toString();
}

num? _number(String value) {
  final String trimmed = value.trim();
  if (trimmed.isEmpty) return null;
  return num.tryParse(trimmed);
}

List<String> _csv(String value) => value
    .split(',')
    .map((String part) => part.trim())
    .where((String part) => part.isNotEmpty)
    .toList();

class _BrandRequestDialog extends StatefulWidget {
  const _BrandRequestDialog({
    required this.repository,
    this.category,
    this.subcategory,
  });

  final StoresPartnerRepository repository;
  final String? category;
  final String? subcategory;

  @override
  State<_BrandRequestDialog> createState() => _BrandRequestDialogState();
}

class _BrandRequestDialogState extends State<_BrandRequestDialog> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _note = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final String name = _name.text.trim();
    if (name.length < 2) {
      setState(() => _error = 'Enter the brand name.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await widget.repository.requestBrand(
        name: name,
        category: widget.category,
        subcategory: widget.subcategory,
        note: _note.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on StoresApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = error.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.storesActionRequestBrand),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text(
              'Admin reviews the brand once. Approved brands become selectable for every chain.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Brand name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Note for Admin (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            if (_error != null) ...<Widget>[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppColors.expired)),
            ],
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
              child: Text(AppLocalizations.of(context)!.storesActionCancel),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(AppLocalizations.of(context)!.storesActionSubmitRequest),
        ),
      ],
    );
  }
}

class _BrandRequestsDialog extends StatelessWidget {
  const _BrandRequestsDialog({required this.repository});

  final StoresPartnerRepository repository;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.storesTitleMyBrandRequests),
      content: SizedBox(
        width: 420,
        height: 360,
        child: FutureBuilder<Map<String, dynamic>>(
          future: repository.brandRequests(),
          builder: (
            BuildContext context,
            AsyncSnapshot<Map<String, dynamic>> snapshot,
          ) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(AppLocalizations.of(context)!.storesMsgCouldNotLoadRequests(snapshot.error.toString())),
              );
            }

            final dynamic raw = snapshot.data?['requests'];
            final List<Map<String, dynamic>> rows = raw is List
                ? raw.whereType<Map<String, dynamic>>().toList()
                : <Map<String, dynamic>>[];

            if (rows.isEmpty) {
              return Center(child: Text(AppLocalizations.of(context)!.storesNoBrandRequests));
            }

            return ListView.separated(
              itemCount: rows.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (BuildContext context, int index) {
                final Map<String, dynamic> row = rows[index];
                final String status = '${row['status'] ?? 'pending'}';
                final dynamic decision = row['decision'];

                return ListTile(
                  title: Text('${row['name'] ?? AppLocalizations.of(context)!.storesFallbackBrand}'),
                  subtitle: Text(
                    decision is Map && decision['note'] != null
                        ? '$status - ${decision['note']}'
                        : status,
                  ),
                  trailing: Chip(label: Text(status)),
                );
              },
            );
          },
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppLocalizations.of(context)!.storesActionClose),
        ),
      ],
    );
  }
}

class _BrandCertificationDialog extends StatefulWidget {
  const _BrandCertificationDialog({
    required this.repository,
    required this.brandId,
  });

  final StoresPartnerRepository repository;
  final String brandId;

  @override
  State<_BrandCertificationDialog> createState() =>
      _BrandCertificationDialogState();
}

class _BrandCertificationDialogState extends State<_BrandCertificationDialog> {
  final TextEditingController _type = TextEditingController();
  final TextEditingController _number = TextEditingController();
  final TextEditingController _validFrom = TextEditingController();
  final TextEditingController _validTo = TextEditingController();
  final TextEditingController _document = TextEditingController();

  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _type.dispose();
    _number.dispose();
    _validFrom.dispose();
    _validTo.dispose();
    _document.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_type.text.trim().isEmpty) {
      setState(() => _error = 'Certification type is required');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.repository.submitBrandCertification(
        widget.brandId,
        <String, dynamic>{
          'type': _type.text.trim(),
          if (_number.text.trim().isNotEmpty) 'number': _number.text.trim(),
          if (_validFrom.text.trim().isNotEmpty)
            'validFrom': _validFrom.text.trim(),
          if (_validTo.text.trim().isNotEmpty) 'validTo': _validTo.text.trim(),
          if (_document.text.trim().isNotEmpty)
            'document': _document.text.trim(),
        },
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on StoresApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.storesActionCertifyBrand),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(_error!, style: const TextStyle(color: AppColors.expired)),
              ),
            TextField(
              controller: _type,
              decoration: const InputDecoration(
                labelText: 'Type (authorization_letter, dealership, ...)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _number,
              decoration: const InputDecoration(
                labelText: 'Certificate number',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _validFrom,
              decoration: const InputDecoration(
                labelText: 'Valid from (YYYY-MM-DD)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _validTo,
              decoration: const InputDecoration(
                labelText: 'Valid to (YYYY-MM-DD)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _document,
              decoration: const InputDecoration(
                labelText: 'Document URL',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
              child: Text(AppLocalizations.of(context)!.storesActionCancel),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: Text(_saving ? 'Submitting...' : 'Submit'),
        ),
      ],
    );
  }
}

