/*
 * Copyright (C) 2019-2026 Savoir-faire Linux Inc.
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

    property string deviceName: ""
    property string deviceId: ""
    property bool isCurrent: false

    property bool editable: false
    property bool isHovered: root.hovered || button.hovered || root.editable

    signal btnRemoveDeviceClicked

    // Note that the implicitWidth and implicitHeight are defined directly in LinkedDevicesBase.qml
    padding: 12
    leftPadding: deviceImage.iconSize / 2
    rightPadding: background.radius - button.height / 2

    spacing: 0

    background: Rectangle {
        color: root.isHovered ? JamiTheme.smartListSelectedColor : JamiTheme.editBackgroundColor
        radius: height / 2

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
        }

        Behavior on color {
            ColorAnimation {
                duration: JamiTheme.shortFadeDuration
            }
        }
    }

    contentItem: RowLayout {
        id: rowLayout

        NewIconButton {
            id: deviceImage

            Layout.alignment: Qt.AlignVCenter

            iconSource: JamiResources.baseline_desktop_windows_24dp_svg
            iconSize: JamiTheme.iconButtonMedium
            icon.color: JamiTheme.tintedBlue

            background: null
        }

        ColumnLayout {
            id: deviceInfoColumnLayout

            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignVCenter

            MaterialLineEdit {
                id: editDeviceName

                Layout.alignment: Qt.AlignVCenter
                Layout.fillWidth: true

                padding: 8
                font.pointSize: JamiTheme.textFontSize

                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter

                wrapMode: Text.NoWrap
                readOnly: !root.editable
                loseFocusWhenEnterPressed: true
                backgroundColor: JamiTheme.transparentColor

                onAccepted: {
                    AvAdapter.setDeviceName(editDeviceName.text);
                    root.editable = !root.editable;
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

                    text: deviceName
                    elide: Text.ElideRight
                    elideWidth: editDeviceName.width - editDeviceName.leftPadding * 2

                    font: editDeviceName.font
                }
            }

            Text {
                id: labelDeviceId

                Layout.alignment: Qt.AlignVCenter
                Layout.fillWidth: true
                Layout.leftMargin: editDeviceName.leftPadding

                text: deviceId === "" ? JamiStrings.deviceId : deviceId
                color: JamiTheme.textColor
                horizontalAlignment: Text.AlignLeft
                elide: Text.ElideMiddle

                font.pointSize: JamiTheme.textFontSize
            }
        }

        NewMaterialButton {
            id: button

            outlinedButton: true
            text: root.isCurrent ? (root.editable ? JamiStrings.saveNewDeviceName : JamiStrings.editDeviceName) : JamiStrings.unlinkDevice

            visible: root.isHovered

            layer.enabled: false

            onClicked: {
                if (root.isCurrent) {
                    if (!root.editable) {
                        root.editable = !root.editable;
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
}
