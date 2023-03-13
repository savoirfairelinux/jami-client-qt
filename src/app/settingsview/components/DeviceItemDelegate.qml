/*
 * Copyright (C) 2019-2023 Savoir-faire Linux Inc.
 * Author: Yang Wang   <yang.wang@savoirfairelinux.com>
 * 
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
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1

import "../../commoncomponents"

ItemDelegate {
    id: root

    property string deviceName : ""
    property string deviceId : ""
    property bool isCurrent : false

    property bool editable : false

    signal btnRemoveDeviceClicked


    background: Rectangle {
        color: JamiTheme.editBackgroundColor
        height: root.height
        radius: 5
    }

    RowLayout {
        id: rowLayout
        anchors.fill: root

        ResponsiveImage {
            id: deviceImage

            color: JamiTheme.tintedBlue

            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 24
            Layout.preferredHeight: 24
            Layout.leftMargin: JamiTheme.preferredMarginSize

            source: JamiResources.baseline_desktop_windows_24dp_svg
        }

        ColumnLayout {
            id: deviceInfoColumnLayout

            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.leftMargin: JamiTheme.preferredMarginSize / 2
            Layout.alignment: Qt.AlignVCenter

            MaterialLineEdit {
                id: editDeviceName

                Layout.alignment: Qt.AlignLeft
                Layout.fillWidth: true
                Layout.preferredHeight: 30

                padding: 8
                font.pointSize: JamiTheme.textFontSize

                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter

                wrapMode: Text.NoWrap
                readOnly: !editable
                loseFocusWhenEnterPressed: true
                backgroundColor: JamiTheme.transparentColor

                onAccepted: {
                    AvAdapter.setDeviceName(editDeviceName.text)
                    editable = !editable
                }
                onReadOnlyChanged: {
                    if (readOnly)
                        editDeviceName.text = Qt.binding(function() {
                            return elidedTextDeviceName.elidedText
                        })
                    else
                        editDeviceName.text = deviceName
                }

                TextMetrics {
                    id: elidedTextDeviceName

                    font: editDeviceName.font
                    elide: Text.ElideRight
                    elideWidth: editDeviceName.width - editDeviceName.leftPadding * 2
                    text: deviceName
                }
            }

            Text {
                id: labelDeviceId

                Layout.alignment: Qt.AlignLeft
                Layout.fillWidth: true
                Layout.leftMargin: editDeviceName.leftPadding
                Layout.bottomMargin: 10

                elide: Text.ElideRight
                font.pointSize: JamiTheme.textFontSize
                color: JamiTheme.textColor
                text: deviceId === "" ? JamiStrings.deviceId : deviceId
                
            }
        }

        PushButton {
            id: btnEditDevice

            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            Layout.rightMargin: 13
            Layout.preferredWidth: JamiTheme.preferredFieldHeight
            Layout.preferredHeight: JamiTheme.preferredFieldHeight

            imageColor: JamiTheme.tintedBlue
            normalColor: highlighted ?
                             JamiTheme.selectedColor :
                             JamiTheme.editBackgroundColor

            source: isCurrent ?
                        (editable ?
                             JamiResources.round_save_alt_24dp_svg :
                             JamiResources.round_edit_24dp_svg) :
                        JamiResources.delete_24dp_svg

            toolTipText: isCurrent ?
                             (editable ?
                                  JamiStrings.saveNewDeviceName :
                                  JamiStrings.editDeviceName) :
                             JamiStrings.unlinkDevice

            onClicked: {
                if (isCurrent) {
                    if (!editable)
                        editable = !editable
                    else
                        editDeviceName.focus = false
                } else {
                    btnRemoveDeviceClicked()
                }
            }
        }
    }
}