/*
 * Copyright (C) 2022 Savoir-faire Linux Inc.
 * Author: Kateryna Kostiuk <kateryna.kostiuk@savoirfairelinux.com>
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

/*
   This file will be used for by macdeployqt to scan for QML imports.
   Usually src/ is used for this purpose, but src/ contains files that 
   require qtWebEngine.
*/

import Qt.labs.platform
import QtMultimedia
import QtQml
import QtQuick.Window
import Qt.labs.qmlmodels
import QtQuick.Shapes
