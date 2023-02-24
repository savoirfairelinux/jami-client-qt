#!/usr/bin/env python3
# -*- coding: utf-8 -*-

# Copyright (C) 2021-2023 Savoir-faire Linux Inc.
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


# Generate the the resources.qrc file and the JamiResources.qml file
# that will be used to access the resources.
with open(resfile, 'w', encoding='utf-8') as qrc, \
        open(qmlfile, 'w', encoding='utf-8') as qml:
    qrc.write('<RCC>\n')
    qml.write('pragma Singleton\nimport QtQuick\nQtObject {\n')
    for root, _, files in os.walk(resdir):
        if len(files):
            prefix = root.rsplit(os.sep, 1)[-1]
            # add a prefix to the resource file
            qrc.write(f'\t<qresource prefix="/{prefix}">\n')
            for filename in files:
                # use posix separators in the resource path
                filepath = os.path.join(root, filename).replace(os.sep, '/')
                qrc.write(f'\t\t<file alias="{filename}">{filepath}</file>\n')
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
