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
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"

SettingsPageBase {
    id: root

    title: JamiStrings.exposedServicesSettingsTitle

    // Cached list of {id,name,description,localHost,localPort,policy,allowedContacts,enabled}.
    property var services: []

    function refresh() {
        services = ExposedServicesAdapter.getExposedServices(CurrentAccount.id);
    }

    function policyTag(p) {
        if (p === "public")
            return JamiStrings.exposedServicePolicyTagPublic;
        if (p === "specific")
            return JamiStrings.exposedServicePolicyTagSpecific;
        return JamiStrings.exposedServicePolicyTagContacts;
    }

    Component.onCompleted: refresh()

    Connections {
        target: CurrentAccount
        function onIdChanged() {
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
                Layout.alignment: Qt.AlignLeft
                Layout.fillWidth: true
                text: JamiStrings.exposedServicesListTitle
                color: JamiTheme.textColor
                font.pixelSize: JamiTheme.settingsTitlePixelSize
            }

            NewMaterialButton {
                implicitHeight: JamiTheme.newMaterialButtonHeight
                filledButton: true
                text: JamiStrings.exposedServicesAdd
                onClicked: {
                    serviceEditorDialog.editingId = "";
                    serviceEditorDialog.serviceName = "";
                    serviceEditorDialog.serviceDescription = "";
                    serviceEditorDialog.serviceHost = "127.0.0.1";
                    serviceEditorDialog.servicePort = "";
                    serviceEditorDialog.servicePolicy = "contacts";
                    serviceEditorDialog.serviceAllowed = "";
                    serviceEditorDialog.serviceEnabled = true;
                    serviceEditorDialog.open();
                }
            }
        }

        Text {
            visible: root.services.length === 0
            Layout.fillWidth: true
            text: JamiStrings.exposedServicesNone
            color: JamiTheme.faddedLastInteractionFontColor
            font.italic: true
            font.pixelSize: JamiTheme.settingsDescriptionPixelSize
        }

        Repeater {
            model: root.services
            delegate: Rectangle {
                id: rowRect
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: rowLayout.implicitHeight + 16
                radius: 6
                color: JamiTheme.editBackgroundColor
                border.color: JamiTheme.tabbarBorderColor
                border.width: 1

                RowLayout {
                    id: rowLayout
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 10

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        RowLayout {
                            spacing: 8
                            Text {
                                text: rowRect.modelData.name
                                color: JamiTheme.textColor
                                font.weight: Font.DemiBold
                                font.pixelSize: JamiTheme.settingsDescriptionPixelSize
                            }
                            Rectangle {
                                radius: 3
                                color: JamiTheme.tintedBlue
                                implicitWidth: tagText.implicitWidth + 10
                                implicitHeight: tagText.implicitHeight + 4
                                Text {
                                    id: tagText
                                    anchors.centerIn: parent
                                    text: root.policyTag(rowRect.modelData.policy)
                                    font.pixelSize: JamiTheme.settingsDescriptionPixelSize - 3
                                    color: "white"
                                }
                            }
                            Text {
                                visible: rowRect.modelData.enabled !== "true"
                                text: "(disabled)"
                                color: JamiTheme.faddedLastInteractionFontColor
                                font.italic: true
                                font.pixelSize: JamiTheme.settingsDescriptionPixelSize - 2
                            }
                        }

                        Text {
                            visible: text.length > 0
                            text: rowRect.modelData.description
                            color: JamiTheme.textColor
                            font.pixelSize: JamiTheme.settingsDescriptionPixelSize - 1
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }

                        Text {
                            text: JamiStrings.exposedServiceLocalEndpoint.arg(rowRect.modelData.localHost + ":" + rowRect.modelData.localPort)
                            color: JamiTheme.faddedLastInteractionFontColor
                            font.pixelSize: JamiTheme.settingsDescriptionPixelSize - 2
                            font.family: JamiTheme.ubuntuMonoFontFamily
                        }
                    }

                    NewMaterialButton {
                        implicitHeight: JamiTheme.newMaterialButtonHeight
                        outlinedButton: true
                        text: JamiStrings.edit
                        onClicked: {
                            serviceEditorDialog.editingId = rowRect.modelData.id;
                            serviceEditorDialog.serviceName = rowRect.modelData.name;
                            serviceEditorDialog.serviceDescription = rowRect.modelData.description;
                            serviceEditorDialog.serviceHost = rowRect.modelData.localHost;
                            serviceEditorDialog.servicePort = rowRect.modelData.localPort;
                            serviceEditorDialog.servicePolicy = rowRect.modelData.policy;
                            serviceEditorDialog.serviceAllowed = rowRect.modelData.allowedContacts;
                            serviceEditorDialog.serviceEnabled = rowRect.modelData.enabled === "true";
                            serviceEditorDialog.open();
                        }
                    }

                    NewMaterialButton {
                        implicitHeight: JamiTheme.newMaterialButtonHeight
                        outlinedButton: true
                        color: JamiTheme.buttonTintedRed
                        text: JamiStrings.optionDelete
                        onClicked: {
                            ExposedServicesAdapter.removeExposedService(CurrentAccount.id, rowRect.modelData.id);
                            root.refresh();
                        }
                    }
                }
            }
        }
    }

    BaseModalDialog {
        id: serviceEditorDialog

        property string editingId: ""
        property string serviceName: ""
        property string serviceDescription: ""
        property string serviceHost: "127.0.0.1"
        property string servicePort: ""
        property string servicePolicy: "contacts"
        property string serviceAllowed: ""
        property bool serviceEnabled: true

        titleText: editingId.length > 0 ? JamiStrings.edit : JamiStrings.exposedServicesAdd

        popupContent: ColumnLayout {
            spacing: 10
            Layout.preferredWidth: 420

            Label {
                text: JamiStrings.exposedServiceNameLabel
                color: JamiTheme.textColor
            }
            TextField {
                Layout.fillWidth: true
                text: serviceEditorDialog.serviceName
                placeholderText: JamiStrings.exposedServiceNamePlaceholder
                onTextChanged: serviceEditorDialog.serviceName = text
            }

            Label {
                text: JamiStrings.exposedServiceDescriptionLabel
                color: JamiTheme.textColor
            }
            TextField {
                Layout.fillWidth: true
                text: serviceEditorDialog.serviceDescription
                onTextChanged: serviceEditorDialog.serviceDescription = text
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                ColumnLayout {
                    Layout.fillWidth: true
                    Label {
                        text: JamiStrings.exposedServiceHostLabel
                        color: JamiTheme.textColor
                    }
                    TextField {
                        Layout.fillWidth: true
                        text: serviceEditorDialog.serviceHost
                        onTextChanged: serviceEditorDialog.serviceHost = text
                    }
                }
                ColumnLayout {
                    Layout.preferredWidth: 110
                    Label {
                        text: JamiStrings.exposedServicePortLabel
                        color: JamiTheme.textColor
                    }
                    TextField {
                        Layout.fillWidth: true
                        text: serviceEditorDialog.servicePort
                        validator: IntValidator {
                            bottom: 1
                            top: 65535
                        }
                        inputMethodHints: Qt.ImhDigitsOnly
                        onTextChanged: serviceEditorDialog.servicePort = text
                    }
                }
            }

            Label {
                text: JamiStrings.exposedServicePolicyLabel
                color: JamiTheme.textColor
            }
            ComboBox {
                id: policyBox
                Layout.fillWidth: true
                textRole: "label"
                valueRole: "value"
                model: [
                    {
                        value: "contacts",
                        label: JamiStrings.exposedServicePolicyContacts
                    },
                    {
                        value: "public",
                        label: JamiStrings.exposedServicePolicyPublic
                    },
                    {
                        value: "specific",
                        label: JamiStrings.exposedServicePolicySpecific
                    },
                ]
                Component.onCompleted: {
                    var idx = 0;
                    if (serviceEditorDialog.servicePolicy === "public")
                        idx = 1;
                    else if (serviceEditorDialog.servicePolicy === "specific")
                        idx = 2;
                    currentIndex = idx;
                }
                onActivated: serviceEditorDialog.servicePolicy = currentValue
            }

            Label {
                visible: serviceEditorDialog.servicePolicy === "specific"
                text: JamiStrings.exposedServiceAllowedLabel
                color: JamiTheme.textColor
            }
            TextField {
                visible: serviceEditorDialog.servicePolicy === "specific"
                Layout.fillWidth: true
                text: serviceEditorDialog.serviceAllowed
                onTextChanged: serviceEditorDialog.serviceAllowed = text
            }

            CheckBox {
                text: JamiStrings.exposedServiceEnabled
                checked: serviceEditorDialog.serviceEnabled
                onToggled: serviceEditorDialog.serviceEnabled = checked
            }
        }

        button1.text: JamiStrings.exposedServiceSave
        button1.enabled: serviceEditorDialog.serviceName.length > 0 && serviceEditorDialog.servicePort.length > 0
        button1.onClicked: {
            var s = {
                "name": serviceEditorDialog.serviceName,
                "description": serviceEditorDialog.serviceDescription,
                "localHost": serviceEditorDialog.serviceHost,
                "localPort": serviceEditorDialog.servicePort,
                "policy": serviceEditorDialog.servicePolicy,
                "allowedContacts": serviceEditorDialog.serviceAllowed,
                "enabled": serviceEditorDialog.serviceEnabled ? "true" : "false"
            };
            if (serviceEditorDialog.editingId.length > 0) {
                s.id = serviceEditorDialog.editingId;
                ExposedServicesAdapter.updateExposedService(CurrentAccount.id, s);
            } else {
                ExposedServicesAdapter.addExposedService(CurrentAccount.id, s);
            }
            serviceEditorDialog.close();
            root.refresh();
        }

        button2.text: JamiStrings.exposedServiceCancel
        button2.onClicked: serviceEditorDialog.close()
    }
}
