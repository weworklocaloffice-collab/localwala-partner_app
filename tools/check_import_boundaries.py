"""
check_import_boundaries.py — enforces the Plan §3.2.2 boundary rules.

## Why a script, not a Dart lint

Dart's analyzer does not ship a built-in rule for "no imports from
this path". The third-party `import_lint` package covers that, but
adding a dependency for one rule is more cost than this script.

A boundary that is not machine-checked decays within a month
(plan §3.2.2). This script is the smallest thing that catches a
violation before it lands.

## Rules

  1. `lib/app/core/**`         cannot import from `lib/app/modules/**` or `lib/app/shell/**`.
  2. `lib/app/modules/**`      cannot import from `lib/app/shell/**`.
  3. `lib/app/modules/<a>/**`  cannot import from `lib/app/modules/<b>/**` (another module).
  4. `lib/app/modules/<m>/<feature>/**` cannot import a sibling feature
     (`partner`/`driver` in dairy, `vendor`/`executive` in realestate).
     Shared code lives in the module's `models/` or `repository/`.
  5. `lib/app/shell/**`        is allowed to import from anywhere (it is the dispatcher).
  6. Relative imports are also checked — `core/` cannot reach into `modules/` via
     a chain of `../../` either.

A file's zone is its path segments under `lib/app/`. Anything else (`lib/app/`
without one of those prefixes, e.g. `lib/app/router/`) is treated as
shared infrastructure and is not subject to these rules — yet.

Run:
  python tools/check_import_boundaries.py
"""

import os
import re
import sys
from pathlib import Path

ROOT = Path("C:/localwala/AppSourceCode/Partner_app")
LIB = ROOT / "lib" / "app"
PKG = ROOT / "lib"

# The three zones under `lib/app/`. Anything else (presentation/, router/,
# gen/) is shared infrastructure and has no zone — yet.
ZONES = {"core", "modules", "shell"}

# Feature folders inside a module. Two features in one module never import
# each other — shared screens belong in a `shared/` folder inside the
# module (or in `models/` / `repository/`), not imported sideways.
# Plan section 11.7: enforced with the same check that guards `core/`.
FEATURE_DIRS = {"partner", "driver", "vendor", "executive"}

# (Rules live in `zone_violation` below; zones nest, a flat matrix cannot
# express "same module, different feature".)

# A regex for the two import forms we care about. Relative imports
# with `../` chains and absolute `package:partner/...` imports.
IMPORT_RE = re.compile(
    r"""^\s*import\s+['"](?P<spec>(?:package:partner/|\.\.?/)[^'"]+)['"]""",
    re.MULTILINE,
)


def zone_of(path: Path) -> tuple[str, ...] | None:
    """Zone segments under `lib/app/`, e.g. ("modules", "realestate", "vendor").

    Anything outside `lib/app/` (presentation/, router/, gen/, main.dart
    imports) has no zone and is not subject to these rules — yet.
    """
    try:
        rel = path.relative_to(LIB)
    except ValueError:
        return None
    parts = rel.parts
    if not parts or parts[0] not in ZONES:
        return None
    return tuple(parts)


def zone_violation(importer: tuple[str, ...], target: tuple[str, ...]) -> str | None:
    """Return a human-readable rule name when the import is forbidden."""
    if importer[0] == "core" and target[0] in ("modules", "shell"):
        return f"a core file cannot import from {target[0]}"
    if importer[0] == "modules" and target[0] == "shell":
        return "a modules file cannot import from shell"
    if (
        importer[0] == "modules"
        and target[0] == "modules"
        and len(importer) > 1
        and len(target) > 1
        and importer[1] != target[1]
    ):
        return f"module {importer[1]} cannot import from module {target[1]}"
    if (
        len(importer) > 2
        and len(target) > 2
        and importer[0] == "modules"
        and target[0] == "modules"
        and importer[1] == target[1]
        and importer[2] in FEATURE_DIRS
        and target[2] in FEATURE_DIRS
        and importer[2] != target[2]
    ):
        return (
            f"{importer[1]}/{importer[2]} cannot import from "
            f"{importer[1]}/{target[2]} (shared code lives in models/ or repository/)"
        )
    return None


def resolve_spec(spec: str, importer: Path) -> str | None:
    """Return the on-disk path the import points to, or None if external."""
    if spec.startswith("package:partner/"):
        # `package:partner/` is the package root (`lib/`), not `lib/app/`.
        # Resolving against LIB produced `lib/app/app/...`, which never
        # exists — so every absolute import was silently skipped and only
        # relative `../` chains were ever checked.
        target = PKG / spec[len("package:partner/") :]
    elif spec.startswith("."):
        target = (importer.parent / spec).resolve()
    else:
        return None
    try:
        target.relative_to(LIB)
    except ValueError:
        return None
    return str(target)


# One file in shell/ is importable from modules/: the role-gate bloc,
# which defines `RoleGateState` — the resolved-session contract every
# shell screen takes as a parameter (`XxxShellScreen(gate: state)`).
# Without it no shell could type its input. Everything else under
# shell/ (picker, dispatch, views) stays forbidden to modules/.
GATE_STATE_FILE = "shell/role_gate/bloc/role_gate_bloc.dart"


def check_file(path: Path) -> list[str]:
    """Return a list of human-readable violations for one file."""
    importer = zone_of(path)
    if importer is None:
        return []
    # shell/ is the dispatcher: allowed to know about everyone.
    if importer[0] == "shell":
        return []

    text = path.read_text(encoding="utf-8")
    out = []
    for match in IMPORT_RE.finditer(text):
        spec = match.group("spec")
        target_str = resolve_spec(spec, path)
        if target_str is None:
            continue
        target_path = Path(target_str)
        if target_path.suffix == "":
            # `import 'foo.dart';` is a file import; `import 'foo/';` is a
            # directory import that resolves to `foo/foo.dart`. Resolve
            # to the .dart file the analyzer would pick.
            target_path = target_path / (target_path.name + ".dart")
        if not target_path.exists():
            # Could be a barrel or generated file; skip rather than false-positive.
            continue
        target = zone_of(target_path)
        if target is None:
            continue
        # The role-gate bloc file carries RoleGateState, which shells take
        # as a parameter. Allowed from modules/, forbidden nowhere else new.
        if importer[0] == "modules" and "/".join(target) == GATE_STATE_FILE:
            continue
        reason = zone_violation(importer, target)
        if reason is None:
            continue
        out.append(f"{path.relative_to(ROOT).as_posix()}: {reason} ({spec})")
    return out


def main() -> int:
    if not LIB.exists():
        print(f"ERROR: {LIB} does not exist", file=sys.stderr)
        return 1

    violations: list[str] = []
    scanned = 0
    for dart_file in sorted(LIB.rglob("*.dart")):
        scanned += 1
        violations.extend(check_file(dart_file))

    print("Partner app import-boundary check")
    print("=================================")
    print(f"  Scanned: {scanned} .dart files under lib/app/")
    if violations:
        print(f"  Violations: {len(violations)}")
        for v in violations:
            print(f"    - {v}")
        print("")
        print("Plan §3.2.2: the core/ boundary is enforced by machine, not by code review.")
        return 1
    print("  OK — no boundary violations")
    return 0


if __name__ == "__main__":
    sys.exit(main())
