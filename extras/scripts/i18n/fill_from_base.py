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

"""Fill a language's empty strings from another language of the same tongue.

Regional variants (es_ES, de_DE, pt_PT, ...) often share text with their base
language (es, de, pt). This copies the base's finished translations into the
target's still-empty messages. Existing target translations are never
overwritten.

Examples:
    fill_from_base.py --base es --target es_ES
    fill_from_base.py --base ko --target ko_KR
"""

import argparse
import os
import sys

import tslib

REPO_ROOT = os.path.abspath(
    os.path.join(os.path.dirname(__file__), '..', '..', '..'))
TS_DIR = os.path.join(REPO_ROOT, 'translations')
TS_PREFIX = 'jami_client_qt_'


def ts_path(lang):
    return os.path.join(TS_DIR, '{}{}.ts'.format(TS_PREFIX, lang))


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--base', required=True, help='source language code')
    parser.add_argument('--target', required=True, help='target language code')
    args = parser.parse_args(argv)

    tslib.validate_lang(args.base)
    tslib.validate_lang(args.target)
    base_path = ts_path(args.base)
    target_path = ts_path(args.target)
    for path in (base_path, target_path):
        if not os.path.isfile(path):
            print('no such file: {}'.format(path), file=sys.stderr)
            return 1

    base = tslib.parse_translated(base_path)
    applied = tslib.apply_translations(target_path, base)
    remaining = len(tslib.parse_untranslated(target_path))
    print('{} -> {}: applied {}, {} still empty'.format(
        args.base, args.target, applied, remaining))
    return 0


if __name__ == '__main__':
    sys.exit(main())
