/*
 * Copyright (C) 2022 Savoir-faire Linux Inc.
 * Author: Fadi Shehadeh <fadi.shehadeh@savoirfairelinux.com>
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

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

import net.jami.Constants 1.1
import net.jami.Adapters 1.1


EditableLineEdit {
    id: root

    Image {
        id: img1
        opacity: editable && !root.readOnly

        Layout.alignment: Qt.AlignVCenter

        layer {
            enabled: true
            effect: ColorOverlay {
                color: root.editIconColor
            }
        }

        source: JamiResources.round_edit_24dp_svg

        Behavior on opacity {
            NumberAnimation {
                from: 0
                duration: JamiTheme.longFadeDuration
            }
        }
    }

    PushButton {
        id: img2

        Layout.alignment: Qt.AlignVCenter
        anchors.right: root.right

        enabled: editable && !root.readOnly
        //preferredSize: lineEdit.height * 2 / 3
        opacity: enabled ? 0.8 : 0
        imageColor: root.cancelIconColor
        normalColor: "transparent"
        hoveredColor: JamiTheme.hoveredButtonColor

        source: JamiResources.round_close_24dp_svg

        onClicked: {
            root.editingFinished()
            root.editable = !root.editable
            lineEdit.forceActiveFocus()
        }

        Behavior on opacity {
            NumberAnimation {
                from: 0
                duration: JamiTheme.longFadeDuration
            }
        }
    }



}
