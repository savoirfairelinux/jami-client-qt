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

"""Export untranslated strings from .ts files to JSON for translation.

Each output file lists the English source strings that still need a
translation for one language. A translator (human or model) fills the
"translation" fields, then import_translations.py writes them back.

Examples:
    export_untranslated.py --lang fr
    export_untranslated.py --all --out-dir /tmp/i18n
"""

import argparse
import json
import os
import sys

import tslib

REPO_ROOT = os.path.abspath(
    os.path.join(os.path.dirname(__file__), '..', '..', '..'))
TS_DIR = os.path.join(REPO_ROOT, 'translations')
TS_PREFIX = 'jami_client_qt_'
SOURCE_LANG = 'en'


def ts_path(lang):
    return os.path.join(TS_DIR, '{}{}.ts'.format(TS_PREFIX, lang))


def available_languages():
    langs = []
    for name in sorted(os.listdir(TS_DIR)):
        if name.startswith(TS_PREFIX) and name.endswith('.ts'):
            lang = name[len(TS_PREFIX):-len('.ts')]
            if lang != SOURCE_LANG:
                langs.append(lang)
    return langs


def export_language(lang, out_dir):
    path = ts_path(lang)
    if not os.path.isfile(path):
        raise FileNotFoundError(path)
    entries = tslib.parse_untranslated(path)
    payload = {
        'language': lang,
        'file': os.path.relpath(path, REPO_ROOT),
        'entries': [{'id': index,
                     'context': e['context'],
                     'source': e['source'],
                     'translation': ''} for index, e in enumerate(entries)],
    }
    out_path = os.path.join(out_dir, '{}.json'.format(lang))
    with open(out_path, 'w', encoding='utf-8') as handle:
        json.dump(payload, handle, ensure_ascii=False, indent=2)
        handle.write('\n')
    return len(entries), out_path


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--lang', help='single language code, e.g. fr')
    group.add_argument('--all', action='store_true',
                       help='export every language except the source')
    parser.add_argument('--out-dir', default='.',
                        help='directory for JSON output (default: current)')
    args = parser.parse_args(argv)

    os.makedirs(args.out_dir, exist_ok=True)
    langs = available_languages() if args.all else [args.lang]

    total = 0
    for lang in langs:
        try:
            count, out_path = export_language(lang, args.out_dir)
        except FileNotFoundError as err:
            print('skip {}: no such file {}'.format(lang, err), file=sys.stderr)
            continue
        total += count
        print('{}: {} untranslated -> {}'.format(lang, count, out_path))
    print('total untranslated strings: {}'.format(total))


if __name__ == '__main__':
    main()
