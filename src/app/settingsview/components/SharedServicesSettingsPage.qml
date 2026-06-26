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


    property var sharedServices: []

    function refresh() {
        sharedServices = SharedServicesAdapter.getSharedServices(CurrentAccount.id);
    }

    title: JamiStrings.sharedServicesSettingsTitle

    Component.onCompleted: refresh()

    Connections {
        target: CurrentAccount
        function onIdChanged() {
            root.refresh();
        }
    }

    Connections {
        target: SharedServicesAdapter

        function onRefreshSharedServices() {
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

            text: JamiStrings.sharedServicesDescription
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

                text: JamiStrings.sharedServicesListTitle
                color: JamiTheme.textColor

                font.pixelSize: JamiTheme.settingsTitlePixelSize
            }

            NewMaterialButton {
                filledButton: true
                iconSource: JamiResources.language_24dp_svg
                text: JamiStrings.sharedServicesAddWebsite

                onClicked: {
                    viewCoordinator.presentDialog(appWindow, "settingsview/components/SharedServiceDialog.qml", {
                                                      "serviceType": "embedded",
                                                  });
                }
            }

            NewMaterialButton {
                implicitHeight: JamiTheme.newMaterialButtonHeight

                filledButton: true
                iconSource: JamiResources.build_circle_24dp_svg
                text: JamiStrings.sharedServicesCustomService

                onClicked: {
                    viewCoordinator.presentDialog(appWindow, "settingsview/components/SharedServiceDialog.qml", {
                                                      "serviceType": "custom",
                                                  });
                }
            }
        }

        Text {
            Layout.fillWidth: true

            text: JamiStrings.sharedServicesNone
            color: JamiTheme.faddedLastInteractionFontColor

            font.italic: true
            font.pixelSize: JamiTheme.settingsDescriptionPixelSize

            visible: root.sharedServices.length === 0
        }

        ListView {
            id: sharedServicesListView

            Layout.fillWidth: true
            Layout.preferredHeight: contentHeight

            model: root.sharedServices
            spacing: 8

            delegate: SharedServiceDelegate {
                Layout.fillWidth: true

                implicitWidth: ListView ? ListView.view.width : implicitWidth
            }
        }
    }
}
