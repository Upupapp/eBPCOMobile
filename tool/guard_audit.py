#!/usr/bin/env python3
"""Breaks each architecture guard's rule and checks the guard notices.

A guard that has never been seen to fail is a guard nobody has tested. This
mutates lib/ in place, runs the single test that should catch the mutation, and
restores the file — so it is a script, deliberately not a `_test.dart`: it must
never run as part of `flutter test`.

Run from the repo root:  python3 tool/guard_audit.py

Written after U-01 shipped a scanner that inspected only named async methods
and missed 127 anonymous closures, and after an Official Receipt guard passed a
falsification that had not actually violated its rule. Both looked green.

The first run of this found the status-badge guard exempting any Row that
already contained a StatusBadge — so a hand-rolled pill added beside an
existing badge went unflagged, which is the most likely way that defect would
reappear.
"""

import subprocess, pathlib, shutil, sys, json

ROOT = pathlib.Path('/Users/user/eBPCO-Mobile-App')
BACKUP = pathlib.Path('/tmp/audit/backup'); BACKUP.mkdir(parents=True, exist_ok=True)

def backup(paths):
    for p in paths:
        src = ROOT / p
        dst = BACKUP / p.replace('/', '__')
        if src.exists(): shutil.copy2(src, dst)

def restore(paths):
    for p in paths:
        dst = BACKUP / p.replace('/', '__')
        src = ROOT / p
        if dst.exists(): shutil.copy2(dst, src)
        elif src.exists(): src.unlink()      # created file

def run(test):
    r = subprocess.run(['flutter', 'test', test, '--timeout', '120s'],
                       cwd=ROOT, capture_output=True, text=True, timeout=900)
    return r.returncode

results = []

def audit(name, test, paths, mutate):
    backup(paths)
    try:
        mutate()
        code = run(test)
        caught = code != 0
    except Exception as e:
        caught = None
        print(f'  !! {name}: mutation failed: {e}')
    finally:
        restore(paths)
    results.append((name, caught))
    print(f'{"CAUGHT " if caught else "MISSED "} {name}')

def edit(path, old, new, count=1):
    p = ROOT / path
    s = p.read_text()
    assert s.count(old) >= count, f'anchor not found in {path}'
    p.write_text(s.replace(old, new, count))

# 1 ── status badge
audit('status_badge_usage', 'test/architecture/status_badge_usage_test.dart',
  ['lib/features/applications/presentation/widgets/application_list_tile.dart'],
  lambda: edit('lib/features/applications/presentation/widgets/application_list_tile.dart',
    "                  const SizedBox(width: AppSpacing.sm),\n                  Flexible(\n                    child: StatusBadge(",
    """                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        AppConstants.borderRadiusPill,
                      ),
                    ),
                    child: const Text('hand-rolled'),
                  ),
                  Flexible(
                    child: StatusBadge("""))

# 2 ── fixed-height grid
audit('fixed_height_grid', 'test/architecture/fixed_height_grid_test.dart',
  ['lib/features/applications/presentation/applications_screen.dart'],
  lambda: edit('lib/features/applications/presentation/applications_screen.dart',
    '        ResponsiveCardGrid(\n          crossAxisCount: 2,',
    '        // childAspectRatio: 1.4,\n        ResponsiveCardGrid(\n          crossAxisCount: 2,'))

# 3 ── a 17th confirmation screen that copies rather than reuses
def new_submitted():
    p = ROOT / 'lib/features/applications/presentation/fencing_permit/zz_new_submitted_screen.dart'
    p.write_text("import 'package:flutter/material.dart';\n\n"
                 "class ZzNewSubmittedScreen extends StatelessWidget {\n"
                 "  const ZzNewSubmittedScreen({super.key});\n"
                 "  @override\n"
                 "  Widget build(BuildContext context) => const Scaffold();\n}\n")
audit('submitted_screen_usage', 'test/architecture/submitted_screen_usage_test.dart',
  ['lib/features/applications/presentation/fencing_permit/zz_new_submitted_screen.dart'],
  new_submitted)

# 4 ── a provider outside app.dart
audit('provider_scope', 'test/architecture/provider_scope_test.dart',
  ['lib/features/applications/presentation/applications_screen.dart'],
  lambda: edit('lib/features/applications/presentation/applications_screen.dart',
    'import ', '// ChangeNotifierProvider<X>(\nimport ', 1))

# 5 ── a wizard that files nothing
audit('wizard_records_submission', 'test/architecture/wizard_records_submission_test.dart',
  ['lib/features/applications/presentation/fencing_permit/fencing_permit_wizard_screen.dart'],
  lambda: edit('lib/features/applications/presentation/fencing_permit/fencing_permit_wizard_screen.dart',
    'submitPermitApplication(', 'noSubmitAtAll('))

# 6 ── a wizard filing a literal permit type
audit('canonical_permit_type', 'test/architecture/canonical_permit_type_test.dart',
  ['lib/features/applications/presentation/fencing_permit/fencing_permit_wizard_screen.dart'],
  lambda: edit('lib/features/applications/presentation/fencing_permit/fencing_permit_wizard_screen.dart',
    'permitTypeLabel: CanonicalPermitType.fencingPermit.wire,',
    "permitTypeLabel: 'Fencing Permit',"))

# 7 ── vocabulary drift
audit('admin_vocabulary', 'test/contract/admin_vocabulary_test.dart',
  ['lib/core/contract/admin_vocabulary.dart'],
  lambda: edit('lib/core/contract/admin_vocabulary.dart',
    "CanonicalPermitType.fencingPermit => 'Fencing Permit',",
    "CanonicalPermitType.fencingPermit => 'Fencing permit',"))

# 8 ── catalog drift
audit('requirements_catalog', 'test/contract/requirements_catalog_test.dart',
  ['lib/core/contract/requirements_catalog.dart'],
  lambda: edit('lib/core/contract/requirements_catalog.dart',
    '    validityMonths: 6,', '    validityMonths: 9,', 1))

# 9 ── an upload slot silently removed
audit('upload_slot_census', 'test/features/applications/upload_slot_census_test.dart',
  ['lib/features/applications/presentation/certificate_of_occupancy/steps/step4_required_documents.dart'],
  lambda: edit('lib/features/applications/presentation/certificate_of_occupancy/steps/step4_required_documents.dart',
    "            _uploadTile(\n              label: 'Barangay Clearance',", "            if (false) _uploadTile(\n              label: 'Barangay Clearance',"))

# 10 ── clipping: shrink the nav bar so a label no longer fits
audit('clipping (nav bar)', 'test/features/shell/main_shell_test.dart',
  ['lib/features/shell/presentation/main_shell.dart'],
  lambda: edit('lib/features/shell/presentation/main_shell.dart',
    'height:\n              88 *\n              MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, 2.0),',
    'height: 88,'))

print()
print('=' * 52)
missed = [n for n, c in results if not c]
for n, c in results:
    print(f'  {"ok    " if c else "MISSED"}  {n}')
print(f'\n{len(results) - len(missed)}/{len(results)} guards caught their violation')
if missed: print('BLIND:', ', '.join(missed))
