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

import 'package:file_picker/file_picker.dart';
import 'package:partner/gen/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:partner/app/modules/stores/partner/catalogue/stores_product_form_screen.dart';
import 'package:partner/app/modules/stores/stores_partner_repository.dart';
import 'package:partner/app/modules/stores/widgets/stores_ui_states.dart';

/// Chain catalogue for the stores vertical.
///
/// BR-36 is the shape this screen is built around: products belong to the CHAIN, and an
/// outlet differs only in price, availability and stock. So a product listed here is the
/// chain's, and the outlet's rows are what decide whether it is sellable here.
///
/// BR-11 is why there is no per-category form in this file. The product form is fetched from
/// `GET /catalog/product-form`, which returns attribute templates for the chosen
/// subcategory. Adding a twenty-first category is seed data plus zero client code — that is
/// the whole test of BR-26.
class StoresCatalogueScreen extends StatefulWidget {
  const StoresCatalogueScreen({super.key});

  @override
  State<StoresCatalogueScreen> createState() => _StoresCatalogueScreenState();
}

class _StoresCatalogueScreenState extends State<StoresCatalogueScreen> {
  StoresPartnerRepository? _repo;
  final TextEditingController _search = TextEditingController();
  String? _query;
  bool _importing = false;

  @override
  void initState() {
    super.initState();
    _repo = StoresPartnerRepository();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() => _repo = StoresPartnerRepository());
  }

  Future<void> _openProductForm(BuildContext context, {String? productId}) async {
    final StoresPartnerRepository repo = _repo ?? StoresPartnerRepository();
    final bool? saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (BuildContext context) => StoresProductFormScreen(
          repository: repo,
          productId: productId,
        ),
      ),
    );
    if (saved == true) _reload();
  }

  Future<void> _importProducts() async {
    final FilePickerResult? picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: <String>['csv', 'xlsx'],
      withData: false,
    );
    final PlatformFile? file = picked?.files.single;
    final String? path = file?.path;
    if (file == null || path == null) return;

    final StoresPartnerRepository repo = _repo ?? StoresPartnerRepository();
    setState(() => _importing = true);

    try {
      final Map<String, dynamic> result = await repo.importProducts(
        filePath: path,
        filename: file.name,
      );
      if (!mounted) return;
      final int created = (result['created'] as num?)?.toInt() ?? 0;
      final int updated = (result['updated'] as num?)?.toInt() ?? 0;
      final int total = (result['total'] as num?)?.toInt() ?? created + updated;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Import complete: $created created, $updated updated ($total rows).',
          ),
        ),
      );
      _reload();
    } on StoresApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    final StoresPartnerRepository repo = _repo ?? StoresPartnerRepository();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.storesTitleCatalogue),
        actions: <Widget>[
          if (_importing)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              tooltip: 'Import products (CSV/XLSX)',
              onPressed: _importProducts,
              icon: const Icon(Icons.upload_file),
            ),
          IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openProductForm(context),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _search,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l10n.storesFieldSearchProducts,
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (String value) {
                setState(() => _query = value.trim());
                _reload();
              },
            ),
          ),
          Expanded(
            child: StoresAsyncView<Map<String, dynamic>>(
              future: repo.catalogueProducts(search: _query, status: 'all'),
              builder: (BuildContext context, Map<String, dynamic> data) {
                final dynamic raw = data['items'] ?? data['products'] ?? data['results'] ?? data;
                final List<Map<String, dynamic>> rows = raw is List
                    ? raw.whereType<Map<String, dynamic>>().toList()
                    : <Map<String, dynamic>>[];

                if (rows.isEmpty) {
                  return const StoresEmptyView(
                    message: 'No products yet. Add one with the + button.',
                    icon: Icons.category_outlined,
                  );
                }

                return ListView.separated(
                  itemCount: rows.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (BuildContext context, int index) {
                    final Map<String, dynamic> row = rows[index];
                    return ListTile(
                      leading: const Icon(Icons.inventory_2_outlined),
                      title: Text('${row['name'] ?? AppLocalizations.of(context)!.storesFallbackProduct}'),
                      subtitle: Text(
                        '${row['status'] ?? ''}${row['hasVariants'] == true ? ' · variants' : ''}',
                      ),
                      trailing: row['status'] == 'archived'
                          ? const Icon(Icons.archive_outlined, size: 18)
                          : const Icon(Icons.chevron_right),
                      onTap: () => _openProductForm(context, productId: _idOf(row)),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
String _idOf(dynamic value) {
  if (value is Map) return value['_id']?.toString() ?? value['id']?.toString() ?? '';
  return value?.toString() ?? '';
}
