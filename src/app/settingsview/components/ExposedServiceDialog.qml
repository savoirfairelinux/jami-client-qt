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

    readonly property list<string> adjectives: [
        "Wireless", "Fast", "Smart", "Portable", "Secure", "Encrypted", "Compact", "Alert", "Robust", "Sensitive",
        "Bright", "Cozy", "Snappy", "Gentle", "Sunny", "Happy", "Smooth", "Quick", "Handy", "Friendly"
    ]
    readonly property list<string> nouns: ["Pickle", "Noodle", "Nubble", "Doodle", "Pebble", "Giggle", "Muffin", "Jelly", "Puppy", "Pancake",
        "Mitten", "Donut", "Tater", "Bumble", "Cookie", "Poodle", "Nugget", "Waffle", "Dimple", "Sprout"
    ]

    function generateRandomName() {
        const adjectiveIndex = Math.floor(Math.random() * adjectives.length);
        const nounindex = Math.floor(Math.random() * nouns.length);
        return adjectives[adjectiveIndex] + " " + nouns[nounindex];
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
        return serviceSchemeSelection === "custom" ? serviceCustomScheme.trim() : serviceSchemeSelection;
    }

    function typeComboIndex() {
        return serviceType === "embedded" ? 0 : 1;
    }

    function schemeComboIndex() {
        if (serviceSchemeSelection === "http")
            return 1;
        if (serviceSchemeSelection === "https")
            return 2;
        if (serviceSchemeSelection === "custom")
            return 3;
        return 0;
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

    button1.text: JamiStrings.exposedServiceSave
    button1.iconSource: JamiResources.save_file_24dp_svg
    button1.enabled: root.canSave()
    button1.onClicked: {
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
            "enabled": root.serviceEnabled ? "true" : "false"
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

    button2.text: JamiStrings.exposedServiceCancel
    button2.iconSource: JamiResources.cancel_24dp_svg
    button2.onClicked: root.close()

    titleText: editingId.length > 0 ? JamiStrings.edit : JamiStrings.exposedServicesAdd

    popupContent: ColumnLayout {
        spacing: 10
        width: JamiTheme.preferredDialogWidth

        RowLayout {
            Layout.fillWidth: true

            spacing: 10

            Text {
                Layout.fillWidth: true

                text: JamiStrings.exposedServiceTypeLabel
                color: JamiTheme.textColor

                font.pointSize: JamiTheme.settingsFontSize
            }

            SettingParaCombobox {
                id: typeBox

                Layout.preferredWidth: 240

                currentIndex: root.typeComboIndex()
                model: ListModel {
                    ListElement {
                        value: "embedded"
                        label: "Web server (embedded)"
                    }
                    ListElement {
                        value: "custom"
                        label: "Custom"
                    }
                }

                textRole: "label"
                valueRole: "value"

                font.pointSize: JamiTheme.buttonFontSize

                onActivated: {
                    root.serviceType = currentValue;
                    if (currentValue === "embedded") {
                        root.serviceHost = "localhost";
                        root.setServiceScheme("http");
                    } else if (root.serviceHost.length === 0) {
                        root.serviceHost = "localhost";
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true

            NewMaterialTextField {
                id: nameField

                Layout.fillWidth: true

                leadingIconSource: JamiResources.label_24dp_svg

                placeholderText: JamiStrings.exposedServiceNameLabel
                textFieldContent: root.serviceName

                onModifiedTextFieldContentChanged: root.serviceName = modifiedTextFieldContent
            }

            NewIconButton {
                id: randomNameButton

                iconSource: JamiResources.casino_24dp_svg
                iconSize: JamiTheme.iconButtonMedium
                toolTipText: "Random name"

                RotationAnimator {
                    id: spinAnimation
                    target: randomNameButton
                    from: 0
                    to: 360
                    duration: JamiTheme.longFadeDuration * 2
                    running: false
                    easing.type: Easing.InOutCirc
                }

                onClicked: {
                    spinAnimation.start();
                    nameField.modifiedTextFieldContent = generateRandomName();
                }
            }
        }

        NewMaterialTextField {
            id: descriptionField

            Layout.fillWidth: true

            leadingIconSource: JamiResources.swarm_details_panel_24dp_svg

            placeholderText: JamiStrings.exposedServiceDescriptionLabel
            textFieldContent: root.serviceDescription

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

                leadingIconSource: JamiResources.network_reverse_24dp_svg
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
            Layout.fillWidth: true

            spacing: 10

            visible: !root.isEmbeddedService()

            Text {
                Layout.fillWidth: true

                text: JamiStrings.exposedServiceSchemeLabel
                color: JamiTheme.textColor

                font.pointSize: JamiTheme.settingsFontSize
            }

            SettingParaCombobox {
                id: schemeBox

                Layout.preferredWidth: 240

                currentIndex: root.schemeComboIndex()
                model: ListModel {
                    ListElement {
                        value: ""
                        label: "Raw TCP"
                    }
                    ListElement {
                        value: "http"
                        label: "HTTP"
                    }
                    ListElement {
                        value: "https"
                        label: "HTTPS"
                    }
                    ListElement {
                        value: "custom"
                        label: "Custom"
                    }
                }

                textRole: "label"
                valueRole: "value"

                font.pointSize: JamiTheme.buttonFontSize

                onActivated: {
                    root.serviceSchemeSelection = currentValue;
                    root.serviceScheme = root.effectiveScheme();
                }
            }
        }

        NewMaterialTextField {
            id: customSchemeField

            Layout.fillWidth: true

            placeholderText: JamiStrings.exposedServiceCustomSchemeLabel
            textFieldContent: root.serviceCustomScheme

            visible: !root.isEmbeddedService() && root.serviceSchemeSelection === "custom"

            onModifiedTextFieldContentChanged: {
                root.serviceCustomScheme = modifiedTextFieldContent;
                root.serviceScheme = root.effectiveScheme();
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
                    ListElement {
                        value: "contacts"
                        label: "Confirmed contacts"
                    }
                    ListElement {
                        value: "public"
                        label: "Anyone (public)"
                    }
                    ListElement {
                        value: "specific"
                        label: "Specific contacts only"
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

        RowLayout {
            Layout.fillWidth: true

            spacing: 10

            Text {
                Layout.fillWidth: true

                text: JamiStrings.exposedServiceEnabled
                color: JamiTheme.textColor

                font.pointSize: JamiTheme.settingsFontSize
            }
            JamiSwitch {
                checked: root.serviceEnabled
                onToggled: root.serviceEnabled = checked
            }
        }

        NewMaterialButton {
            Layout.fillWidth: true

            outlinedButton: true
            color: JamiTheme.buttonTintedRed
            iconSource: JamiResources.delete_24dp_svg
            text: JamiStrings.optionDelete

            visible: editingId !== ""

            onClicked: {
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
        }

    }

    FolderDialog {
        id: directoryDialog

        title: JamiStrings.selectFolder
        currentFolder: root.serviceDirectory.length > 0 ? root.serviceDirectory : StandardPaths.writableLocation(StandardPaths.HomeLocation)
        options: FolderDialog.ShowDirsOnly

        onAccepted: root.serviceDirectory = UtilsAdapter.getAbsPath(folder.toString())
    }

}