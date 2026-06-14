#!/usr/bin/env python3
#
#  Copyright (C) 2016-2026 Savoir-faire Linux Inc.
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301 USA.
#

"""Write translated strings from JSON back into .ts files.

Consumes the JSON produced by export_untranslated.py once its "translation"
fields are filled. Only non-empty translations are applied; empty ones stay
untranslated and can be exported again later.

Examples:
    import_translations.py /tmp/i18n/fr.json
    import_translations.py /tmp/i18n/*.json
"""

import argparse
import json
import os
import sys

import tslib

REPO_ROOT = os.path.abspath(
    os.path.join(os.path.dirname(__file__), '..', '..', '..'))
TRANSLATIONS_DIR = os.path.join(REPO_ROOT, 'translations')


def _resolve_ts_path(rel_path):
    """Resolve payload['file'] under translations/, rejecting traversal.

    The path comes from translator-controlled JSON, so an absolute path,
    ``../`` traversal, or a symlink must not be allowed to escape the
    translations directory. Symlinks are resolved with realpath before the
    containment check, and the target must be a .ts file.
    """
    ts_path = os.path.realpath(os.path.join(REPO_ROOT, rel_path))
    translations_dir = os.path.realpath(TRANSLATIONS_DIR)
    if os.path.commonpath([translations_dir, ts_path]) != translations_dir:
        raise ValueError(
            '{}: translation file must be under translations/'.format(rel_path))
    if not ts_path.endswith('.ts'):
        raise ValueError(
            '{}: translation file must be a .ts file'.format(rel_path))
    return ts_path


def import_file(json_path):
    with open(json_path, 'r', encoding='utf-8') as handle:
        payload = json.load(handle)

    ts_path = _resolve_ts_path(payload['file'])
    entries = payload['entries']

    if not any(entry.get('translation') for entry in entries):
        return 0, ts_path

    applied = tslib.apply_ordered(ts_path, entries)
    return applied, ts_path


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('json_files', nargs='+',
                        help='translation JSON files to apply')
    args = parser.parse_args(argv)

    total = 0
    for json_path in args.json_files:
        try:
            applied, ts_path = import_file(json_path)
        except (OSError, ValueError, KeyError) as err:
            print('error on {}: {}'.format(json_path, err), file=sys.stderr)
            return 1
        total += applied
        print('{}: applied {} -> {}'.format(
            os.path.basename(json_path), applied,
            os.path.relpath(ts_path, REPO_ROOT)))
    print('total applied: {}'.format(total))
    return 0


if __name__ == '__main__':
    sys.exit(main())
