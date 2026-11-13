import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:partner/app/core/config/api_request_service.dart';
import 'package:partner/app/core/repositories/partner_repository.dart';
import 'package:partner/app/modules/dairy/partner/inventory/partner_inventory_view.dart';
import 'package:partner/app/modules/dairy/partner/inventory/partner_product_create_view.dart';
import 'package:partner/gen/l10n/app_localizations.dart';

class _InventoryRepository extends PartnerRepository {
  int inventoryLoads = 0;
  int? lastStockDelta;
  Map<String, dynamic>? createdProduct;
  Map<String, dynamic>? createdSku;
  Map<String, dynamic>? updatedProduct;
  Map<String, dynamic>? updatedSku;
  String? receivedLotNo;
  int? receivedLotQuantity;
  DateTime? receivedLotExpiry;
  int? writtenOffQuantity;
  String? writtenOffBucket;
  String? writtenOffReason;
  String? lastDisposition;
  List<Map<String, dynamic>> seedLots = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> seedSkus = <Map<String, dynamic>>[];

  @override
  Future<DioApiResponse> inventory({int page = 1, int limit = 10}) async {
    inventoryLoads++;
    return DioApiResponse.success(
      jsonEncode(<String, dynamic>{
        'skus': seedSkus.isNotEmpty
            ? seedSkus
            : createdSku == null
            ? <dynamic>[]
            : <Map<String, dynamic>>[createdSku!],
      }),
    );
  }

  @override
  Future<DioApiResponse> dairyCategories() async => DioApiResponse.success(
    jsonEncode(<String, dynamic>{
      'categories': <Map<String, dynamic>>[
        <String, dynamic>{'_id': 'category-1', 'name': 'Milk'},
      ],
    }),
  );

  @override
  Future<DioApiResponse> dairyBrands() async => DioApiResponse.success(
    jsonEncode(<String, dynamic>{'brands': <dynamic>[]}),
  );

  @override
  Future<DioApiResponse> dairySubCategories(String categoryId) async =>
      DioApiResponse.success(jsonEncode(<String, dynamic>{'subCategories': <dynamic>[]}));

  @override
  Future<DioApiResponse> createProduct(Map<String, dynamic> product) async {
    createdProduct = product;
    return DioApiResponse.success(
      jsonEncode(<String, dynamic>{
        'product': <String, dynamic>{'_id': 'product-1'},
      }),
    );
  }

  @override
  Future<DioApiResponse> updateProduct(String productId, Map<String, dynamic> changes) async {
    updatedProduct = changes;
    return DioApiResponse.success(jsonEncode(<String, dynamic>{'product': changes}));
  }

  @override
  Future<DioApiResponse> updateSku(String skuId, Map<String, dynamic> changes) async {
    updatedSku = changes;
    return DioApiResponse.success(jsonEncode(<String, dynamic>{'sku': changes}));
  }

  @override
  Future<DioApiResponse> createSku(Map<String, dynamic> sku) async {
    createdSku = <String, dynamic>{...sku, '_id': 'sku-1'};
    return DioApiResponse.success(jsonEncode(<String, dynamic>{'sku': createdSku}));
  }

  @override
  Future<DioApiResponse> updateStock(String skuId, int delta) async {
    lastStockDelta = delta;
    createdSku = <String, dynamic>{
      ...?createdSku,
      'availableQty': (createdSku?['availableQty'] as int? ?? 0) + delta,
      'inStock': (createdSku?['availableQty'] as int? ?? 0) + delta > 0,
    };
    return const DioApiResponse.success('{}');
  }

  @override
  Future<DioApiResponse> receiveInventoryLot(
    String skuId, {
    required String lotNo,
    required int quantity,
    required DateTime expiry,
    String? notes,
  }) async {
    receivedLotNo = lotNo;
    receivedLotQuantity = quantity;
    receivedLotExpiry = expiry;
    return const DioApiResponse.success('{}');
  }

  @override
  Future<DioApiResponse> inventoryLots(String skuId) async =>
      DioApiResponse.success(jsonEncode(<String, dynamic>{'lots': seedLots}));

  @override
  Future<DioApiResponse> writeOffInventoryLot(String skuId, String lotId, {
    required int quantity,
    required String bucket,
    required String reason,
    String? note,
  }) async {
    writtenOffQuantity = quantity;
    writtenOffBucket = bucket;
    writtenOffReason = reason;
    final Map<String, dynamic> lot = seedLots.firstWhere((Map<String, dynamic> item) => item['_id'] == lotId);
    lot['availableQty'] = (lot['availableQty'] as int? ?? 0) - (bucket == 'available' ? quantity : 0);
    lot['writtenOffQty'] = (lot['writtenOffQty'] as int? ?? 0) + quantity;
    return const DioApiResponse.success('{}');
  }

  @override
  Future<DioApiResponse> setInventoryLotDisposition(String skuId, String lotId, {
    required String action,
    required String reason,
  }) async {
    lastDisposition = action;
    return const DioApiResponse.success('{}');
  }

  @override
  Future<DioApiResponse> inventoryReport() async => DioApiResponse.success(jsonEncode(<String, dynamic>{
    'report': <String, dynamic>{
      'summary': <String, dynamic>{
        'skuAvailableQty': 8,
        'lotAvailableQty': 8,
        'heldQty': 1,
        'expiredQty': 2,
        'writtenOffQty': 1,
        'discrepancyCount': 1,
        'expiringLotCount': 1,
      },
      'rows': <Map<String, dynamic>>[
        <String, dynamic>{
          'name': 'Farm Milk',
          'skuAvailableQty': 8,
          'lotAvailableQty': 7,
          'ledgerAvailableQty': 8,
          'discrepancy': 1,
          'ledgerDiscrepancy': 0,
        },
      ],
      'expiring': <Map<String, dynamic>>[
        <String, dynamic>{'skuName': 'Farm Milk', 'lotNo': 'BATCH-2', 'availableQty': 2, 'expiry': '2026-11-10'},
      ],
      'movementTotals': <Map<String, dynamic>>[
        <String, dynamic>{'eventType': 'received', 'events': 1, 'quantity': 5},
      ],
    },
  }));
}

Widget _testApp(_InventoryRepository repository) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: PartnerInventoryScreen(partnerRepository: repository),
);

void main() {
  testWidgets('partner adds a product using Admin taxonomy and saves opening stock', (
    WidgetTester tester,
  ) async {
    final _InventoryRepository repository = _InventoryRepository();
    await tester.pumpWidget(_testApp(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add product'));
    await tester.pumpAndSettle();
    expect(find.text('Add product photos'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey<String>('dairy-product-name')), 'Farm Milk');
    await tester.tap(find.byType(DropdownButtonFormField<String>).at(0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Milk').last);
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView).last, const Offset(0, -240));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>).at(3));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ml').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const ValueKey<String>('dairy-pack-size')), '500');
    await tester.enterText(find.byKey(const ValueKey<String>('dairy-product-price')), '32');
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey<String>('dairy-starting-stock')),
      300,
      scrollable: find
          .descendant(
            of: find.byType(PartnerProductCreateScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.enterText(find.byKey(const ValueKey<String>('dairy-starting-stock')), '12');
    await tester.ensureVisible(find.text('Save product and stock'));
    await tester.tap(find.text('Save product and stock'));
    await tester.pumpAndSettle();

    expect(repository.createdProduct?['category'], 'category-1');
    expect(repository.createdProduct?.containsKey('business'), isFalse);
    expect(repository.createdProduct?['images'], isEmpty);
    expect(repository.createdSku?['product'], 'product-1');
    expect(repository.createdSku?['availableQty'], 12);
    expect(repository.createdSku?['packSize']['value'], '500');
    expect(repository.inventoryLoads, 2);
    expect(find.textContaining('Farm Milk - 500 ml'), findsOneWidget);
  });

  testWidgets('legacy stock removal uses a selected batch and reason', (
    WidgetTester tester,
  ) async {
    final _InventoryRepository repository = _InventoryRepository()
      ..seedSkus = <Map<String, dynamic>>[
        <String, dynamic>{
          '_id': 'sku-lot',
          'name': 'Farm Milk - 500 ml',
          'availableQty': 5,
          'inStock': true,
          'packSize': <String, dynamic>{'value': '500', 'unit': 'ml'},
        },
      ]
      ..seedLots = <Map<String, dynamic>>[
        <String, dynamic>{
          '_id': 'lot-1',
          'lotNo': 'BATCH-1',
          'status': 'active',
          'availableQty': 5,
          'heldQty': 0,
          'expiredQty': 0,
          'writtenOffQty': 0,
          'expiry': '2026-12-01T23:59:59.999Z',
        },
      ];
    await tester.pumpWidget(_testApp(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Adjust stock for Farm Milk - 500 ml'));
    await tester.pumpAndSettle();
    await tester.enterText(find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextField)), '2');
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Batch actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Write off available stock'));
    await tester.pumpAndSettle();
    expect(find.textContaining('cannot be sold or restored'), findsOneWidget);
    await tester.enterText(
      find.descendant(of: find.byType(AlertDialog).last, matching: find.byType(TextField)).at(1),
      'Damaged packaging',
    );
    await tester.tap(find.text('Record write-off'));
    await tester.pumpAndSettle();

    expect(repository.writtenOffQuantity, 2);
    expect(repository.writtenOffBucket, 'available');
    expect(repository.writtenOffReason, 'Damaged packaging');
  });

  testWidgets('inventory report shows reconciliation and expiry information', (
    WidgetTester tester,
  ) async {
    final _InventoryRepository repository = _InventoryRepository()
      ..seedSkus = <Map<String, dynamic>>[
        <String, dynamic>{
          '_id': 'sku-1',
          'name': 'Farm Milk - 500 ml',
          'availableQty': 8,
          'inStock': true,
          'packSize': <String, dynamic>{'value': '500', 'unit': 'ml'},
        },
      ];
    await tester.pumpWidget(_testApp(repository));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Inventory report'));
    await tester.pumpAndSettle();

    expect(find.text('Inventory reconciliation'), findsOneWidget);
    expect(find.text('Stock mismatches'), findsOneWidget);
    expect(find.text('Reconciliation differences'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('BATCH-2'),
      180,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.textContaining('BATCH-2'), findsOneWidget);
  });

  testWidgets('receiving stock requires batch number, pack count, and expiry', (
    WidgetTester tester,
  ) async {
    final _InventoryRepository repository = _InventoryRepository()
      ..createdSku = <String, dynamic>{
        '_id': 'sku-1',
        'name': 'Farm Milk - 500 ml',
        'availableQty': 12,
        'inStock': true,
        'packSize': <String, dynamic>{'value': '500', 'unit': 'ml'},
      };
    await tester.pumpWidget(_testApp(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Adjust stock for Farm Milk - 500 ml'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Receive batch'));
    await tester.pumpAndSettle();
    final Finder dialogFields = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(dialogFields.at(0), 'SUP-LOT-44');
    await tester.enterText(dialogFields.at(1), '18');
    await tester.tap(find.text('Expiry date'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Receive stock'));
    await tester.pumpAndSettle();

    expect(repository.receivedLotNo, 'SUP-LOT-44');
    expect(repository.receivedLotQuantity, 18);
    expect(repository.receivedLotExpiry, isNotNull);
    expect(repository.lastStockDelta, isNull);
  });

  testWidgets('inventory search and stock filter narrow the product list', (
    WidgetTester tester,
  ) async {
    final _InventoryRepository repository = _InventoryRepository()
      ..seedSkus = <Map<String, dynamic>>[
        <String, dynamic>{
          '_id': 'sku-available',
          'name': 'Farm Milk 500 ml',
          'availableQty': 12,
          'inStock': true,
        },
        <String, dynamic>{
          '_id': 'sku-empty',
          'name': 'Curd 1 kg',
          'availableQty': 0,
          'inStock': false,
        },
      ];
    await tester.pumpWidget(_testApp(repository));
    await tester.pumpAndSettle();

    final Finder search = find.byKey(const ValueKey<String>('dairy-inventory-search'));
    await tester.enterText(search, 'curd');
    await tester.pumpAndSettle();
    expect(find.text('Curd 1 kg'), findsOneWidget);
    expect(find.text('Farm Milk 500 ml'), findsNothing);

    await tester.enterText(search, '');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Out of stock · 1'));
    await tester.pumpAndSettle();
    expect(find.text('Curd 1 kg'), findsOneWidget);
    expect(find.text('Farm Milk 500 ml'), findsNothing);
  });

  testWidgets('partner can edit pack price, stock alert threshold, and availability', (WidgetTester tester) async {
    final _InventoryRepository repository = _InventoryRepository()
      ..seedSkus = <Map<String, dynamic>>[
        <String, dynamic>{
          '_id': 'sku-edit',
          'name': 'Farm Milk - 500 ml',
          'price': 32,
          'mrp': 35,
          'availableQty': 8,
          'stockAlertThreshold': 5,
          'inStock': true,
          'status': true,
          'packSize': <String, dynamic>{'value': '500', 'unit': 'ml'},
          'product': <String, dynamic>{'_id': 'product-1', 'name': 'Farm Milk', 'images': <String>[]},
        },
      ];
    await tester.pumpWidget(_testApp(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Edit Farm Milk - 500 ml'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit price and availability'));
    await tester.pumpAndSettle();
    await tester.enterText(find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextField)).first, '40');
    await tester.enterText(find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextField)).at(2), '3');
    await tester.tap(find.ancestor(of: find.text('Active in catalogue'), matching: find.byType(SwitchListTile)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save').last);
    await tester.pumpAndSettle();

    expect(repository.updatedSku?['price'], 40);
    expect(repository.updatedSku?['stockAlertThreshold'], 3);
    expect(repository.updatedSku?['status'], isFalse);
  });
}
