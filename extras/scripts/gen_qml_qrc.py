#!/usr/bin/env python3
# -*- coding: utf-8 -*-

# Copyright (C) 2022-2024 Savoir-faire Linux Inc.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301
# USA.

"""
Generate qrc file for qml and related code files recursively within the source
directory.
"""

import os

# These paths should be relative to the working directory of the
# script as set in the project CMakeLists, which should in turn be
# where the resources.qrc will be located (currently 'src/app').
app_src_dir = os.path.join('..', '..', 'src', 'app')
resfile = os.path.join('qml.qrc')


def path_contains_dir(filepath, dir_str):
    """ Return True if the given filepath contains the given directory. """
    # Split the filepath into its components
    path_components = os.path.normpath(filepath).split(os.sep)
    # Return True if the given directory is in the path
    return dir_str in path_components


def posix_path(path):
    """
    Force the use of POSIX path separators for the resource prefixes
    and paths (useful only if versioning the qml.qrc file).
    """
    return path.replace(os.sep, '/')


def gen_qml_qrc(with_webengine):
    """ Generate the qml.qrc file. """
    print("Generating qml.qrc file ...")
    with open(resfile, 'w', encoding='utf-8') as qrc:
        qrc.write('<RCC>\n')
        for root, _, files in os.walk(app_src_dir):
            # Skip the nowebengine directory if we can use webengine
            if with_webengine and path_contains_dir(root, 'nowebengine'):
                continue
            # Skip the webengine directory if we can't use webengine
            if not with_webengine and path_contains_dir(root, 'webengine'):
                continue
            filtered = [k for k in files if k.endswith('.qml') or
                        k.endswith('.js') or k.endswith('.html') or
                        k.endswith('.css') or k.endswith('.conf') or
                        k == 'qmldir']
            # if there are no files of interest in this directory, skip it
            if not filtered:
                continue
            # For now, get the relative resource prefix for this directory,
            # remove the leading slash, and add it as a comment to the line.
            # Ideally, we should use the actual resource prefix instead of /,
            # but this will require some refactoring of the QML code.
            prefix = root.split(app_src_dir)[-1][1:]
            qrc.write(
                f'\t<qresource prefix="/"> <!--{posix_path(prefix)}-->\n')
            for file in filtered:
                relpath = os.path.relpath(
                    os.path.join(root, file), app_src_dir)
                qrc.write(f'\t\t<file>{posix_path(relpath)}</file>\n')
            qrc.write('\t</qresource>\n')
        qrc.write('</RCC>')


if __name__ == '__main__':
    # We can't use webengine if we're building for macOS app store
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument('--with-webengine', action='store_true',
                        default=False, help='Include webengine resources')
    args = parser.parse_args()
    gen_qml_qrc(args.with_webengine)
