# Copyright (C) 2021-2022 Savoir-faire Linux Inc.
#
# Author: Andreas Traczyk <andreas.traczyk@savoirfairelinux.com>
# Author: Amin Bandali <amin.bandali@savoirfairelinux.com>
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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301 USA.

import os
import sys
import re

# These paths should be relative to the working directory of the
# script as set in the project CMakeLists, which should in turn be
# where the resources.qrc will be located (currently 'src/app').
resdir = os.path.join('..', '..', 'resources')
qmlfile = os.path.join('constant', 'JamiResources.qml')
resfile = os.path.join('resources.qrc')
sep = '_'

print("Generating resource files ...")

# replace characters that aren't valid within QML property names
formatProp = lambda str: (
    "".join([{".": sep, "-": sep, " ": sep}
        .get(c, c) for c in str]
    ).lower())

with open(resfile, 'w') as qrc, open(qmlfile, 'w') as qml:
    qrc.write('<RCC>\n')
    qml.write('pragma Singleton\nimport QtQuick 2.14\nQtObject {\n')
    for root, _, files in os.walk(resdir):
        if len(files):
            prefix = root.rsplit(os.sep, 1)[-1]
            qrc.write('\t<qresource prefix="/%s">\n' % prefix)
            for filename in files:
                # use posix separators in the resource path
                filepath = os.path.join(root, filename).replace(os.sep, '/')
                qrc.write('\t\t<file alias="%s">%s</file>\n'
                    % (filename, filepath))
                # only record images/icons as properties
                if (re.match("icons|images", prefix)):
                    qml.write('    readonly property string %s: "qrc:/%s"\n'
                        % (formatProp(filename), filepath.split('/', 3)[-1]))
            qrc.write('\t</qresource>\n')
    qml.write('}')
    qrc.write('</RCC>')
