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
import QtQuick.Effects
import Qt.labs.platform

import net.jami.Constants 1.1
import net.jami.Adapters 1.1

import "../../commoncomponents"

BaseModalDialog {
    id: root

    property string editingId: ""
    property string serviceType: "embedded"
    property string serviceName: ""
    property string serviceDescription: ""
    property string serviceHost: "localhost"
    property string servicePort: ""
    property string serviceDirectory: ""
    property string serviceSchemeSelection: ""
    property string serviceScheme: ""
    property string serviceCustomScheme: ""
    property string servicePolicy: "contacts"
    property string serviceAllowed: ""
    property bool serviceEnabled: true
    Component.onCompleted: {
        // Parse the passed serviceScheme into schemeSelection and customScheme
        if (serviceScheme) {
            setServiceScheme(serviceScheme);
        }
    }
    function isEmbeddedService() {
        return serviceType === "embedded";
    }

    function setServiceScheme(scheme) {
        serviceScheme = scheme || "";
        if (serviceScheme !== "" && serviceScheme !== "http" && serviceScheme !== "https") {
            serviceSchemeSelection = "custom";
            serviceCustomScheme = serviceScheme;
        } else {
            serviceSchemeSelection = serviceScheme;
            serviceCustomScheme = "";
        }
    }

    function effectiveScheme() {
        return serviceCustomScheme.trim();
    }

    function policyComboIndex() {
        if (servicePolicy === "public")
            return 1;
        if (servicePolicy === "specific")
            return 2;
        return 0;
    }

    function hasValidCustomScheme() {
        return serviceSchemeSelection !== "custom" || /^[A-Za-z][A-Za-z0-9+.-]*$/.test(serviceCustomScheme.trim());
    }

    function canSave() {
        if (serviceName.trim().length === 0)
            return false;
        if (isEmbeddedService())
            return serviceDirectory.length > 0;
        return servicePort.length > 0 && hasValidCustomScheme();
    }

    button1.text: JamiStrings.optionDelete
    button1.iconSource: JamiResources.delete_24dp_svg
    button1.color: JamiTheme.buttonTintedRed
    button1.visible: root.editingId !== ""
    button1.onClicked: {
        var dlg = viewCoordinator.presentDialog(appWindow, "../../commoncomponents/ConfirmDialog.qml", {
                                                    "titleText": JamiStrings.confirmAction,
                                                    "textLabel": JamiStrings.confirmDeleteSharedService,
                                                    "confirmLabel": JamiStrings.optionDelete
                                                });
        dlg.accepted.connect(function() {
            ExposedServicesAdapter.removeExposedService(CurrentAccount.id, root.editingId);
            root.close();
        });
    }

    button2.text: JamiStrings.exposedServiceSave
    button2.iconSource: JamiResources.save_file_24dp_svg
    button2.enabled: root.canSave()
    button2.onClicked: {
        var embedded = root.isEmbeddedService();
        var service = {
            "type": root.serviceType,
            "name": root.serviceName.trim(),
            "description": root.serviceDescription,
            "localHost": embedded ? "localhost" : root.serviceHost.trim(),
            "localPort": embedded ? "0" : root.servicePort,
            "scheme": embedded ? "http" : root.effectiveScheme(),
            "directory": embedded ? root.serviceDirectory : "",
            "policy": root.servicePolicy,
            "allowedContacts": root.serviceAllowed,
            "enabled": "true"
        };
        var saved = false;
        if (root.editingId.length > 0) {
            service.id = root.editingId;
            saved = ExposedServicesAdapter.updateExposedService(CurrentAccount.id, service);
        } else {
            saved = ExposedServicesAdapter.addExposedService(CurrentAccount.id, service).length > 0;
        }
        if (!saved)
            return;
        root.close();
    }

    titleText: {
        if (editingId.length > 0) {
            return JamiStrings.edit;
        } else if (serviceType === "embedded") {
            return JamiStrings.exposedServiceAddWebsite
        } else {
            return JamiStrings.exposedServiceCustomService
        }
    }

    popupContent: ColumnLayout {
        spacing: 10
        width: JamiTheme.preferredDialogWidth

        NewMaterialTextField {
            id: nameField

            Layout.fillWidth: true

            leadingIconSource: JamiResources.label_24dp_svg

            placeholderText: JamiStrings.exposedServiceNameLabel
            textFieldContent: root.serviceName

            visible: !root.isEmbeddedService() || (root.isEmbeddedService() && root.serviceDirectory !== "")

            onModifiedTextFieldContentChanged: root.serviceName = modifiedTextFieldContent
        }


        NewMaterialTextField {
            id: descriptionField

            Layout.fillWidth: true

            leadingIconSource: JamiResources.swarm_details_panel_24dp_svg

            placeholderText: JamiStrings.exposedServiceDescriptionLabel
            textFieldContent: root.serviceDescription

            visible: !root.isEmbeddedService()

            onModifiedTextFieldContentChanged: root.serviceDescription = modifiedTextFieldContent
        }

        RowLayout {
            Layout.fillWidth: true

            spacing: 10

            visible: root.isEmbeddedService()

            NewMaterialTextField {
                id: directoryField

                Layout.fillWidth: true

                leadingIconSource: JamiResources.round_folder_24dp_svg
                readOnly: true
                placeholderText: JamiStrings.exposedServiceDirectoryPlaceholder

                textFieldContent: root.serviceDirectory
            }

            NewMaterialButton {
                implicitHeight: JamiTheme.newMaterialButtonHeight

                outlinedButton: true

                text: JamiStrings.exposedServiceChooseDirectory

                onClicked: directoryDialog.open()
            }
        }

        RowLayout {
            Layout.fillWidth: true

            spacing: 10

            visible: !root.isEmbeddedService()

            NewMaterialTextField {
                id: hostField

                Layout.fillWidth: true

                leadingIconSource: JamiResources.host_24dp_svg
                placeholderText: JamiStrings.exposedServiceHostLabel
                textFieldContent: root.serviceHost

                onModifiedTextFieldContentChanged: root.serviceHost = modifiedTextFieldContent
            }

            NewMaterialTextField {
                id: portField

                Layout.preferredWidth: 110

                leadingIconSource: JamiResources.plug_connect_24dp_svg
                placeholderText: JamiStrings.exposedServicePortLabel
                textFieldContent: root.servicePort

                validator: IntValidator {
                    bottom: 1
                    top: 65535
                }

                onModifiedTextFieldContentChanged: root.servicePort = modifiedTextFieldContent
            }
        }

        RowLayout {
            visible: !root.isEmbeddedService()

            NewMaterialTextField {
                id: customSchemeField

                Layout.fillWidth: true

                leadingIconSource: JamiResources.network_reverse_24dp_svg
                placeholderText: JamiStrings.exposedServiceCustomSchemeLabel
                textFieldContent: root.serviceCustomScheme

                onModifiedTextFieldContentChanged: {
                    root.serviceCustomScheme = modifiedTextFieldContent;
                    root.serviceScheme = root.effectiveScheme();
                }
            }

            NewIconButton {
                id: whatsThisButton

                Layout.alignment: Qt.AlignTop

                iconSource: JamiResources.bidirectional_help_outline_24dp_svg
                iconSize: JamiTheme.iconButtonMedium
                // The tool tip of the NewIconButton will interfere with the
                // details popup, so we manually define the accessibility name
                Accessible.name: JamiStrings.exposedServiceWhatsThis

                checked: uriSchemeDetailsPopup.opened

                onClicked: {
                    if (uriSchemeDetailsPopup.opened)
                        uriSchemeDetailsPopup.close()
                    else
                        uriSchemeDetailsPopup.open()
                }

                Popup {
                    id: uriSchemeDetailsPopup

                    parent: parent
                    x: parent.width - width
                    y: - (parent.height + 16)

                    padding: 8

                    closePolicy: Popup.CloseOnEscape
                    visible: false
                    opacity: visible ? 1.0 : 0.0

                    contentItem: Text {
                        text: JamiStrings.exposedServiceUriSchemeDetails
                        color: JamiTheme.textColor
                        lineHeight: JamiTheme.wizardViewTextLineHeight
                        verticalAlignment: Text.AlignVCenter

                        font.kerning: true
                        font.pixelSize: JamiTheme.infoBoxDescFontSize
                    }

                    Behavior on opacity {
                        NumberAnimation {
                            duration: JamiTheme.shortFadeDuration
                        }
                    }

                    background: Rectangle {
                        color: JamiTheme.globalIslandColor
                        radius: 12

                        layer.enabled: true
                        layer.effect: MultiEffect {
                            anchors.fill: uriSchemeDetailsPopup.background
                            shadowEnabled: true
                            shadowBlur: JamiTheme.shadowBlur
                            shadowColor: JamiTheme.shadowColor
                            shadowHorizontalOffset: JamiTheme.shadowHorizontalOffset
                            shadowVerticalOffset: JamiTheme.shadowVerticalOffset
                            shadowOpacity: JamiTheme.shadowOpacity
                        }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true

            spacing: 10

            Text {
                Layout.fillWidth: true

                text: JamiStrings.exposedServicePolicyLabel
                color: JamiTheme.textColor

                font.pointSize: JamiTheme.settingsFontSize
            }

            SettingParaCombobox {
                id: policyBox

                Layout.preferredWidth: 240

                currentIndex: root.policyComboIndex()
                model: ListModel {
                    // We can't bind JamiStrings directly in the properties a ListItem
                    // in a list model, so we fall back to adding them dynamically. This
                    // ensures that the strings in the ListModel are translatable.
                    Component.onCompleted: {
                        append({ "value": "contacts", "label": JamiStrings.exposedServicePolicyContacts });
                        append({ "value": "public", "label": JamiStrings.exposedServicePolicyPublic });
                        append({ "value": "specific", "label": JamiStrings.exposedServicePolicySpecific });
                    }
                }

                textRole: "label"
                valueRole: "value"

                font.pointSize: JamiTheme.buttonFontSize

                onActivated: root.servicePolicy = currentValue
            }
        }

        NewMaterialTextField {
            id: allowedField
            Layout.fillWidth: true

            visible: root.servicePolicy === "specific"
            placeholderText: JamiStrings.exposedServiceAllowedLabel
            textFieldContent: root.serviceAllowed

            onModifiedTextFieldContentChanged: root.serviceAllowed = modifiedTextFieldContent
        }
    }

    FolderDialog {
        id: directoryDialog

        title: JamiStrings.selectFolder
        currentFolder: root.serviceDirectory.length > 0 ? root.serviceDirectory : StandardPaths.writableLocation(StandardPaths.HomeLocation)
        options: FolderDialog.ShowDirsOnly

        onAccepted: {
            root.serviceDirectory = UtilsAdapter.getAbsPath(decodeURIComponent(folder.toString()))
            root.serviceName = UtilsAdapter.dirName(root.serviceDirectory);
        }
    }

}