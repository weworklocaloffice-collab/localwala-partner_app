/*
 * WeWorkLocal
 * Hyperlocal Commerce & Service Platform
 *
 * Website: https://localwala.tech
 * Email: weworklocal1@gmail.com
 *
 * Proprietary and Confidential.
 *
 * Unauthorized copying, redistribution, resale, publication,
 * modification, or use of this source code in any public or
 * commercial repository is strictly prohibited.
 */

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:partner/app/modules/stores/nav_config.dart';

/// The stores role wires must be the SERVER's strings, and the fallback must be understood.
///
/// This file's own comment names the exact failure it exists to prevent:
///
///   "Shortening them here is how a driver session falls through to the partner shell and a
///    rider ends up holding partner authority."
///
/// So the wire values are read straight out of `API/src/config/roles.js` and compared. A
/// rename on the server, or a typo here, fails this test instead of failing silently at
/// runtime — where the symptom is not an error, it is a rider looking at an outlet owner's
/// screens.
void main() {
  final String repoRoot = Directory.current.parent.path;

  final File rolesFile = File('$repoRoot/API/src/config/roles.js');
  test('the server role catalogue is readable', () {
    expect(rolesFile.existsSync(), isTrue,
        reason: 'needs the Partner_app and API checkouts side by side; got ${rolesFile.path}');
  });
  final String rolesSource = rolesFile.readAsStringSync();

  /// Top-level role keys are indented two spaces and open an array.
  final Set<String> serverRoles = RegExp(r'^  ([A-Za-z]\w*):\s*\[', multiLine: true)
      .allMatches(rolesSource)
      .map((RegExpMatch m) => m.group(1)!)
      .toSet();

  group('wire values are the server\'s, not shortened forms', () {
    test('the role catalogue was parsed', () {
      expect(serverRoles.length, greaterThan(5));
    });

    test('every stores wire value exists on the server', () {
      for (final StoresAppRole role in StoresAppRole.values) {
        expect(
          serverRoles,
          contains(role.wire),
          reason: 'StoresAppRole.${role.name} uses wire "${role.wire}", which is not a role '
              'in API/src/config/roles.js. The app will never match this session and will '
              'silently fall back to the default shell.',
        );
      }
    });

    test('both stores roles are distinct', () {
      // A duplicate would make `fromWire` return whichever is declared first, so a driver
      // session could resolve to the partner role.
      final Set<String> wires =
          StoresAppRole.values.map((StoresAppRole r) => r.wire).toSet();
      expect(wires.length, StoresAppRole.values.length);
    });

    test('a driver is not the LocalWala platform fleet', () {
      // BR-05. The app role is the STORE's driver, never a platform courier.
      expect(StoresAppRole.driver.wire, 'storeDriver');
      expect(StoresAppRole.driver.wire, isNot(contains('dairy')));
      expect(StoresAppRole.driver.wire, isNot(contains('jhatka')));
    });
  });

  group('fromWire resolves what the server sends', () {
    test('storePartner resolves to partner', () {
      expect(StoresAppRole.fromWire('storePartner'), StoresAppRole.partner);
    });

    test('storeDriver resolves to driver', () {
      expect(StoresAppRole.fromWire('storeDriver'), StoresAppRole.driver);
    });

    test('null, empty and unknown values resolve to null', () {
      // Null rather than a default: a caller cannot tell "no role" from "the partner role"
      // if this silently falls back, and those demand different handling.
      expect(StoresAppRole.fromWire(null), isNull);
      expect(StoresAppRole.fromWire(''), isNull);
      expect(StoresAppRole.fromWire('storeOwner'), isNull);
      expect(StoresAppRole.fromWire('storepartner'), isNull,
          reason: 'role matching is case-sensitive on purpose; the server is the source');
    });
  });

  group('shell lookup', () {
    test('each role finds its own shell', () {
      for (final StoresAppRole role in StoresAppRole.values) {
        expect(findStoresShell(role.wire), isNotNull,
            reason: 'no shell registered for ${role.wire}');
      }
    });

    test('an unknown role finds no shell', () {
      expect(findStoresShell('somethingElse'), isNull);
      expect(findStoresShell(''), isNull);
    });

    test('every registered shell role is a real StoresAppRole', () {
      // Catches a hand-written `role:` string that no enum member backs.
      for (final StoresShell shell in storesShells) {
        expect(StoresAppRole.fromWire(shell.role), isNotNull,
            reason: 'shell "${shell.label}" claims role "${shell.role}", which no '
                'StoresAppRole defines');
      }
    });

    test('there is exactly one shell per role', () {
      final Set<String> roles = storesShells.map((StoresShell s) => s.role).toSet();
      expect(roles.length, storesShells.length,
          reason: 'a duplicate role means the first registration wins silently');
    });
  });

  group('the fallback shell is a real decision, not an accident', () {
    test('an unrecognised session lands on the partner shell', () {
      expect(defaultStoresShell.role, StoresAppRole.partner.wire);
    });

    test('the fallback is the MORE privileged role, not the lesser one', () {
      // The comment beside `defaultStoresShell` claims partner is "the lower-privilege of
      // the two". Reading the server's own catalogue says the opposite: `storePartner`
      // carries catalogue, inventory and money rights, while `storeDriver` has delivery and
      // earnings rights only. A driver session whose wire value ever fails to match lands
      // on the outlet owner's shell.
      //
      // The server still refuses every call (`storeAuth` against a driver token answers
      // 403), so this is not a privilege escalation — it is a broken, misleading UI. The
      // real defence is the wire-value test above, which stops the drift happening at all.
      final int partnerRights = RegExp(r'^  storePartner:\s*\[(.*?)^\s*\]', multiLine: true, dotAll: true)
              .firstMatch(rolesSource)
              ?.group(1)
              ?.split('\n')
              .length ??
          0;
      final int driverRights = RegExp(r'^  storeDriver:\s*\[(.*?)^\s*\]', multiLine: true, dotAll: true)
              .firstMatch(rolesSource)
              ?.group(1)
              ?.split('\n')
              .length ??
          0;

      expect(partnerRights, greaterThan(driverRights),
          reason: 'if this ever inverts, the fallback is no longer the safer shell and the '
              'comment above defaultStoresShell needs re-reading');
    });
  });
}