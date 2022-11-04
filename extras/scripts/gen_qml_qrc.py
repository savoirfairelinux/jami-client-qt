#!/usr/bin/env python3
# -*- coding: utf-8 -*-

# Copyright (C) 2022 Savoir-faire Linux Inc.
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
Generate qrc file for qml files recursively within the source directory.
"""

import os

# These paths should be relative to the working directory of the
# script as set in the project CMakeLists, which should in turn be
# where the resources.qrc will be located (currently 'src/app').
app_src_dir = os.path.join('..', '..', 'src', 'app')
resfile = os.path.join('qml.qrc')

print("Generating qml.qrc file ...")


# Generate the the resources.qrc file containing all qml and js files.
with open(resfile, 'w', encoding='utf-8') as qrc:
    qrc.write('<RCC>\n')
    for root, _, files in os.walk(app_src_dir):
        if len(files):
            prefix = root.rsplit(os.sep, 1)[-1]
            # add a prefix to the resource file
            qrc.write(f'\t<qresource prefix="/{prefix}">\n')
            for f in files:
                # only add qml and js files
                if f.endswith('.qml') or f.endswith('.js'):
                    # use posix separators in the resource path
                    filepath = os.path.join(
                        root, f).replace(os.sep, '/')
                    qrc.write(
                        f'\t\t<file alias="{f}">{filepath}</file>\n')
            qrc.write('\t</qresource>\n')
    qrc.write('</RCC>')
