/*
 * Copyright (C) 2026 Savoir-faire Linux Inc.
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
import Qt.labs.platform
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"

SettingsPageBase {
    id: root

    title: JamiStrings.exposedServicesSettingsTitle

    property var exposedServices: []

    function refresh() {
        exposedServices = ExposedServicesAdapter.getExposedServices(CurrentAccount.id);
    }

    Component.onCompleted: refresh()

    Connections {
        target: CurrentAccount
        function onIdChanged() {
            root.refresh();
        }
    }

    Connections {
        target: ExposedServicesAdapter

        function onRefreshExposedServices() {
            root.refresh();
        }
    }

    flickableContent: ColumnLayout {
        id: pageLayout

        width: contentFlickableWidth
        spacing: JamiTheme.settingsBlockSpacing
        anchors.left: parent.left
        anchors.leftMargin: JamiTheme.preferredSettingsMarginSize

        Text {
            Layout.fillWidth: true

            text: JamiStrings.exposedServicesDescription
            color: JamiTheme.textColor
            wrapMode: Text.WordWrap
            font.pixelSize: JamiTheme.settingsDescriptionPixelSize
            lineHeight: JamiTheme.wizardViewTextLineHeight
        }

        RowLayout {
            Layout.fillWidth: true

            spacing: 10

            Text {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignLeft

                text: JamiStrings.exposedServicesListTitle
                color: JamiTheme.textColor

                font.pixelSize: JamiTheme.settingsTitlePixelSize
            }

            NewMaterialButton {
                implicitHeight: JamiTheme.newMaterialButtonHeight

                filledButton: true

                text: JamiStrings.exposedServicesAdd
                iconSource: JamiResources.round_add_24dp_svg

                onClicked: {
                    viewCoordinator.presentDialog(appWindow, "settingsview/components/ExposedServiceDialog.qml", {
                                                      "editingId": "",
                                                      "serviceType": "embedded",
                                                      "serviceName": "",
                                                      "serviceDescription": "",
                                                      "serviceHost": "localhost",
                                                      "servicePort": "",
                                                      "serviceDirectory": "",
                                                      "servicePolicy": "contacts",
                                                      "serviceAllowed": "",
                                                      "serviceEnabled": true
                                                  });
                }
            }
        }

        Text {
            Layout.fillWidth: true

            text: JamiStrings.exposedServicesNone
            color: JamiTheme.faddedLastInteractionFontColor

            font.italic: true
            font.pixelSize: JamiTheme.settingsDescriptionPixelSize

            visible: root.exposedServices.length === 0
        }

        ListView {
            id: exposedServicesListView

            Layout.fillWidth: true
            //implicitHeight: contentHeight
            Layout.preferredHeight: contentHeight

            model: root.exposedServices
            spacing: 8

            delegate: ExposedServiceDelegate {
                Layout.fillWidth: true

                implicitWidth: ListView ? ListView.view.width : implicitWidth
            }
        }
    }
}
