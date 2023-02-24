#!/usr/bin/env python3
# -*- coding: utf-8 -*-

# Copyright (C) 2021-2024 Savoir-faire Linux Inc.
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
Generate qrc file for generic resource files (images, text documents, etc.)
recursively within the resource directory. A QML file is also generated that
contains a property for each resource file, which can be accessed from QML via
a QML singleton.
"""

import os
import re

# These paths should be relative to the working directory of the
# script as set in the project CMakeLists, which should in turn be
# where the resources.qrc will be located (currently 'src/app').
resdir = os.path.join('..', '..', 'resources')
qmlfile = os.path.join('net/jami/Constants', 'JamiResources.qml')
resfile = os.path.join('resources.qrc')

print("Generating resource.qrc file ...")


def format_qml_prop(prop):
    """
    Replace characters that aren't valid within QML property names.
    - replace all spaces, periods, and hyphens with underscores
    - change all characters to lowercase
    """
    return "".join([{".": "_", "-": "_", " ": "_"}
                    .get(c, c) for c in prop]
                   ).lower()


def path_contains_dir(filepath, dir_str):
    """ Return True if the given filepath contains the given directory. """
    # Split the filepath into its components
    path_components = os.path.normpath(filepath).split(os.sep)
    # Return True if the given directory is in the path
    return dir_str in path_components


def gen_resources_qrc(with_webengine):
    """ Generate the resources.qrc file. """
    with open(resfile, 'w', encoding='utf-8') as qrc, \
            open(qmlfile, 'w', encoding='utf-8') as qml:
        qrc.write('<RCC>\n')
        qml.write('pragma Singleton\nimport QtQuick\nQtObject {\n')
        for root, _, files in os.walk(resdir):
            # Skip the webengine directory if we can't use webengine
            if not with_webengine and path_contains_dir(root, 'webengine'):
                continue
            prefix = root.rsplit(os.sep, 1)[-1]
            # add a prefix to the resource file
            qrc.write(f'\t<qresource prefix="/{prefix}">\n')
            for filename in files:
                # use posix separators in the resource path
                filepath = os.path.join(
                    root, filename).replace(os.sep, '/')
                qrc.write(
                    f'\t\t<file alias="{filename}">{filepath}</file>\n')
                # only record images/icons as properties
                if re.match("icons|images", prefix):
                    resource = f'qrc:/{prefix}/{filename}'
                    qml.write(
                        "    readonly property string"
                        f' {format_qml_prop(filename)}:'
                        f' "{resource}"\n'
                    )
            qrc.write('\t</qresource>\n')
        qml.write('}')
        qrc.write('</RCC>')


if __name__ == '__main__':
    # We can't use webengine if we're building for macOS app store
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument('--with-webengine', action='store_true',
                        default=False, help='Include webengine resources')
    args = parser.parse_args()
    gen_resources_qrc(args.with_webengine)
