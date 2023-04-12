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
    property string deviceId: ""
    property string deviceName: ""
    property bool editable: false
    property bool isCurrent: false

    signal btnRemoveDeviceClicked

    RowLayout {
        id: rowLayout
        anchors.fill: root

        ResponsiveImage {
            id: deviceImage
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: JamiTheme.preferredMarginSize
            Layout.preferredHeight: 24
            Layout.preferredWidth: 24
            color: JamiTheme.tintedBlue
            source: JamiResources.baseline_desktop_windows_24dp_svg
        }
        ColumnLayout {
            id: deviceInfoColumnLayout
            Layout.alignment: Qt.AlignVCenter
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.leftMargin: JamiTheme.preferredMarginSize / 2

            MaterialLineEdit {
                id: editDeviceName
                Layout.alignment: Qt.AlignLeft
                Layout.fillWidth: true
                Layout.preferredHeight: 30
                backgroundColor: JamiTheme.transparentColor
                font.pointSize: JamiTheme.textFontSize
                horizontalAlignment: Text.AlignLeft
                loseFocusWhenEnterPressed: true
                padding: 8
                readOnly: !editable
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.NoWrap

                onAccepted: {
                    AvAdapter.setDeviceName(editDeviceName.text);
                    editable = !editable;
                }
                onReadOnlyChanged: {
                    if (readOnly)
                        editDeviceName.text = Qt.binding(function () {
                                return elidedTextDeviceName.elidedText;
                            });
                    else
                        editDeviceName.text = deviceName;
                }

                TextMetrics {
                    id: elidedTextDeviceName
                    elide: Text.ElideRight
                    elideWidth: editDeviceName.width - editDeviceName.leftPadding * 2
                    font: editDeviceName.font
                    text: deviceName
                }
            }
            Text {
                id: labelDeviceId
                Layout.alignment: Qt.AlignLeft
                Layout.bottomMargin: 10
                Layout.fillWidth: true
                Layout.leftMargin: editDeviceName.leftPadding
                color: JamiTheme.textColor
                elide: Text.ElideRight
                font.pointSize: JamiTheme.textFontSize
                text: deviceId === "" ? JamiStrings.deviceId : deviceId
            }
        }
        PushButton {
            id: btnEditDevice
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            Layout.preferredHeight: JamiTheme.preferredFieldHeight
            Layout.preferredWidth: JamiTheme.preferredFieldHeight
            Layout.rightMargin: 13
            imageColor: JamiTheme.tintedBlue
            normalColor: highlighted ? JamiTheme.selectedColor : JamiTheme.editBackgroundColor
            source: isCurrent ? (editable ? JamiResources.round_save_alt_24dp_svg : JamiResources.round_edit_24dp_svg) : JamiResources.delete_24dp_svg
            toolTipText: isCurrent ? (editable ? JamiStrings.saveNewDeviceName : JamiStrings.editDeviceName) : JamiStrings.unlinkDevice

            onClicked: {
                if (isCurrent) {
                    if (!editable) {
                        editable = !editable;
                        editDeviceName.forceActiveFocus();
                    } else {
                        editDeviceName.focus = false;
                        editDeviceName.accepted();
                    }
                } else {
                    btnRemoveDeviceClicked();
                }
            }
        }
    }

    background: Rectangle {
        color: JamiTheme.editBackgroundColor
        height: root.height
        radius: 5
    }
}
