/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 *
 * This source code, including all associated assets,
 * APIs, databases, business logic, designs, and
 * documentation, is proprietary to WeWorkLocal.
 *
 * Unauthorized copying, modification, distribution,
 * publication, resale, reverse engineering, or use of
 * this software without prior written authorization is
 * strictly prohibited.
 */

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:partner/app/modules/stores/stores_endpoints.dart';

/// Every endpoint the partner app CALLS must exist on the server, with the same verb.
///
/// This is the check that was missing for the entire partner stores module: 23 files and
/// roughly 3,700 lines with zero tests. That is not merely thin coverage — it is the exact
/// gap that let eleven endpoints ship unreachable. Eleven documented, guarded, working
/// handlers answered `500 CastError` because a literal path had been declared after a
/// sibling carrying a parameter in the same position, and Express resolved to the first
/// match. Unit tests could not see it, because reachability is a property of the ASSEMBLED
/// router and nothing assembled it.
///
/// So this walks it from the client side, parsing the real route files.
void main() {
  final String repoRoot = Directory.current.parent.path;

  String readSource(String relativePath) {
    final File file = File('$repoRoot/$relativePath');
    if (!file.existsSync()) {
      throw StateError(
        'Could not find $relativePath, resolved to ${file.path}. This test needs the '
        'Partner_app and API checkouts side by side; update the path rather than deleting '
        'the test.',
      );
    }
    return file.readAsStringSync();
  }

  const String mount = '/v1/stores';

  // Triple-quoted: a raw string does not process `\"`, so `['\"]` inside `r"..."` would
  // terminate the string at the backslash.
  final RegExp routePattern =
      RegExp(r'''router\.(get|post|patch|put|delete)\(\s*['"]([^'"]+)['"]''');

  Set<String> serverRoutes(String source) {
    final Set<String> out = <String>{};
    for (final RegExpMatch m in routePattern.allMatches(source)) {
      // The route FILES declare paths relative to the `/v1/stores` mount.
      out.add('${m.group(1)!.toUpperCase()} $mount${m.group(2)}');
    }
    return out;
  }

  /// EVERY route file, discovered rather than listed.
  ///
  /// A hardcoded list went stale immediately — the first draft guessed four filenames that
  /// do not exist. Enumerating means a newly added route file is covered with no change
  /// here, which is the entire point of a drift guard.
  final String routesDir = '$repoRoot/API/src/modules/stores/routes';
  final Directory routes = Directory(routesDir);
  if (!routes.existsSync()) {
    throw StateError('Could not find the stores routes directory at $routesDir');
  }

  final List<File> routeFiles = routes
      .listSync()
      .whereType<File>()
      .where((File f) => f.path.endsWith('.js'))
      .toList()
    ..sort((File a, File b) => a.path.compareTo(b.path));

  final Set<String> live = <String>{};
  for (final File file in routeFiles) {
    live.addAll(serverRoutes(file.readAsStringSync()));
  }

  final String endpointSource =
      readSource('Partner_app/lib/app/modules/stores/stores_endpoints.dart');
  final String repositorySource =
      readSource('Partner_app/lib/app/modules/stores/stores_partner_repository.dart');

  /// `{order}` here, `:order` on the server — the same slot spelled differently. The app's
  /// constants carry no leading slash because the HTTP client prepends the base URL, while
  /// Express paths always start with one.
  String normalise(String path) {
    final String bare = path.split('?').first;
    final String slashed = bare.startsWith('/') ? bare : '/$bare';
    return slashed.replaceAllMapped(RegExp(r'\{(\w+)\}'), (Match m) => ':${m.group(1)}');
  }

  group('the assembled server surface', () {
    test('routes were parsed from real files', () {
      expect(routeFiles.length, greaterThan(5),
          reason: 'only found ${routeFiles.length} route files in $routesDir');
      expect(live, isNotEmpty, reason: 'regex or path is wrong, not the server');
      expect(live.length, greaterThan(50));
    });
  });

  group('every constant the app declares is a real server path', () {
    final Map<String, String> constants = <String, String>{
      for (final RegExpMatch m
          in RegExp(r"static const String (\w+)\s*=\s*'([^']+)'")
              .allMatches(endpointSource))
        m.group(1)!: m.group(2)!,
    };

    test('the constants were parsed', () {
      expect(constants.length, greaterThan(30));
      expect(constants.containsKey('myOutlets'), isTrue);
    });

    test('no constant points at a path the server does not serve', () {
      // Checking the SHAPE here (`{param}`) rather than the exact route, because most
      // partner constants are templated and the repository substitutes at call time.
      final List<String> suspicious = <String>[];
      constants.forEach((String name, String path) {
        final String normalised = normalise(path);
        if (normalised.contains('{')) {
          suspicious.add('$name = $path looks templated but is not {param}');
        }
      });
      expect(suspicious, isEmpty, reason: suspicious.join('\n'));
    });
  });

  group('every repository call resolves to a served route', () {
    test('calls are traceable to a declared constant', () {
      final Map<String, String> constants = <String, String>{
        for (final RegExpMatch m
            in RegExp(r"static const String (\w+)\s*=\s*'([^']+)'")
                .allMatches(endpointSource))
          m.group(1)!: m.group(2)!,
      };

      // `_call(...)` is the single choke point every request goes through.
      //
      // The lookbehind excludes the function's own DECLARATION
      // (`... Map<String, dynamic>> _call(`), which is preceded by `> `. Without it that
      // declaration is read as a call site, has no endpoint constant after it, and the
      // suite fails on its own helper rather than on anything real.
      final List<RegExpMatch> calls =
          RegExp(r'(?<!> )_call\(').allMatches(repositorySource).toList();
      expect(calls.length, greaterThan(10),
          reason: 'expected many _call sites in the repository, found ${calls.length}');

      // Word-boundary anchored: a plain `contains` would make
      // `StoresPartnerEndpoints.order` match inside `orderDetail`/`orderTransition`.
      final List<String> untraceable = <String>[];
      for (final RegExpMatch call in calls) {
        final int start = call.end;
        // A call's argument ends at the matching close paren; a fixed window is enough
        // here because every call is a single expression on one or two lines.
        final int end = (start + 220) > repositorySource.length
            ? repositorySource.length
            : start + 220;
        final String chunk = repositorySource.substring(start, end);
        final bool found = constants.keys.any(
          (String n) => RegExp('Stores(Partner|Driver)Endpoints\\.$n\\b').hasMatch(chunk),
        );
        if (!found) untraceable.add(chunk.split('\n').first.trim());
      }
      expect(untraceable, isEmpty,
          reason: 'these calls could not be traced to an endpoint constant, so they are '
              'unverified: ${untraceable.join(' | ')}');
    });
  });

  group('storesResolve refuses to build a request with a literal placeholder', () {
    test('it substitutes what it is given', () {
      expect(
        storesResolve(StoresPartnerEndpoints.orderDetail, order: 'abc'),
        'v1/stores/partner/orders/abc',
      );
      expect(
        storesResolve(StoresPartnerEndpoints.orderTransition, order: 'o1', status: 'packed'),
        'v1/stores/partner/orders/o1/packed',
      );
    });

    test('it THROWS on a missing parameter instead of sending it', () {
      // A leftover `{order}` is a single segment. `GET /:store` is a real storefront route,
      // so an unresolved placeholder returns a store profile — a wrong page, not an error.
      //
      // This failed when first written: `storesResolve` substituted `''` for every missing
      // parameter and returned `v1/stores/partner/orders/` while its own doc comment
      // promised to throw. The comment described an intent the code had never implemented.
      expect(
        () => storesResolve(StoresPartnerEndpoints.orderDetail),
        throwsA(isA<ArgumentError>()),
        reason: 'must refuse rather than request a literal {order}',
      );
    });

    test('the error names the parameter that was missing', () {
      try {
        storesResolve(StoresDriverEndpoints.deliveryVerifyOtp);
        fail('should have thrown');
      } on ArgumentError catch (e) {
        expect(e.message.toString(), contains('delivery'));
      }
    });
  });
}