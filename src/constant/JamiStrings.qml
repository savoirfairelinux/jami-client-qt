/*
 * Copyright (C) 2020 by Savoir-faire Linux
 * Author: Aline Gondim Santos <aline.gondimsantos@savoirfairelinux.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

// JamiTheme as a singleton is to provide global strings entries.
pragma Singleton

import QtQuick 2.14

Item {
    // Color strings.
    property string version: qsTr("Version")
    property string slogan: qsTr("Together")
    property string declaration: qsTr("Jami is a free software for universal communication which respects the freedom and privacy of its users.")
    property string changelog: qsTr("Changelog")
    property string credits: qsTr("Credits")

}