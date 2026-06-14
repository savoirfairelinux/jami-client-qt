#!/usr/bin/env python3

##
##  Copyright (C) 2016-2026 Savoir-faire Linux Inc.
##
##  This program is free software; you can redistribute it and/or modify
##  it under the terms of the GNU General Public License as published by
##  the Free Software Foundation; either version 3 of the License, or
##  (at your option) any later version.
##
##  This program is distributed in the hope that it will be useful,
##  but WITHOUT ANY WARRANTY; without even the implied warranty of
##  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##  GNU General Public License for more details.
##
##  You should have received a copy of the GNU General Public License
##  along with this program; if not, write to the Free Software
##  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301 USA.
##

"""Refresh translations/*.ts from the source tree with lupdate.

Jami no longer uses Transifex. Source strings are extracted here, and the
translations themselves are produced in-house with the helpers in
extras/scripts/i18n (export untranslated strings, translate, import back).
See extras/scripts/i18n/README.md for the full workflow.
"""

import glob
import os
import subprocess
import sys

REPO_ROOT = os.path.abspath(
    os.path.join(os.path.dirname(__file__), '..', '..'))
SRC_DIR = os.path.join(REPO_ROOT, 'src')
TS_GLOB = os.path.join(REPO_ROOT, 'translations', '*.ts')

# lupdate tool candidates, in order of preference.
LUPDATE_TOOLS = ('lupdate', 'lupdate-qt6', 'lupdate6')


def run_lupdate():
    ts_files = sorted(glob.glob(TS_GLOB))
    if not ts_files:
        raise RuntimeError('no .ts files found under translations/')

    base_args = ['-extensions', 'cpp,h,qml', SRC_DIR,
                 '-ts'] + ts_files + ['-no-obsolete']
    for tool in LUPDATE_TOOLS:
        try:
            subprocess.check_call([tool] + base_args)
            return
        except FileNotFoundError:
            continue
    raise RuntimeError(
        'No suitable lupdate tool found (tried: {}). Install Qt Linguist '
        'tools or add lupdate to PATH.'.format(', '.join(LUPDATE_TOOLS)))


def main():
    print('== Updating translations/*.ts from sources')
    run_lupdate()
    print('== Done. Translate new strings with extras/scripts/i18n '
          '(see its README), then rebuild to regenerate the .qm files.')


if __name__ == '__main__':
    sys.exit(main())
