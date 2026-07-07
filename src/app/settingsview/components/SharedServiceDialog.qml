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
import QtQuick.Controls.impl

import net.jami.Constants 1.1
import net.jami.Adapters 1.1
import net.jami.Models 1.1
import "../../commoncomponents"

BaseModalDialog {
    id: root

    property string editingId: ""
    property string serviceType: "embedded"
    property string serviceName: ""
    property string serviceDescription: ""
    property string serviceHost: "localhost"
    property string servicePort: ""
    property string servicePreferredPort: ""
    property string serviceDirectory: ""
    property string serviceSchemeSelection: ""
    property string serviceScheme: ""
    property string serviceCustomScheme: ""
    property string servicePolicy: "contacts"
    property string serviceAllowed: ""
    property bool serviceEnabled: true
    property list<string> selectedContacts: []

    Component.onCompleted: {
        // Parse the passed serviceScheme into schemeSelection and customScheme
        if (serviceScheme) {
            setServiceScheme(serviceScheme);
        }
        // Populate selectedContacts from the comma-separated serviceAllowed string
        if (serviceAllowed.length > 0) {
            selectedContacts = serviceAllowed.split(",").filter(function(s) { return s.length > 0; });
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

    function hasValidPreferredPort() {
        if (servicePreferredPort.length === 0)
            return true;
        if (!/^[0-9]+$/.test(servicePreferredPort))
            return false;
        var port = parseInt(servicePreferredPort, 10);
        return port >= 1024 && port <= 65535;
    }

    function canSave() {
        if (serviceName.trim().length === 0)
            return false;
        if (!hasValidPreferredPort())
            return false;
        if (isEmbeddedService())
            return serviceDirectory.length > 0;
        return servicePort.length > 0 && hasValidCustomScheme();
    }

    function convertSelectedContactsToAllowed() {
        return root.selectedContacts.join(",");
    }

    button1.text: JamiStrings.optionDelete
    button1.iconSource: JamiResources.delete_24dp_svg
    button1.color: JamiTheme.buttonTintedRed
    button1.visible: root.editingId !== ""
    button1.onClicked: {
        var dlg = viewCoordinator.presentDialog(appWindow, "../../commoncomponents/ConfirmDialog.qml", {
                                                    "titleText": JamiStrings.confirmAction,
                                                    "textLabel": JamiStrings.sharedServicesConfirmDelete,
                                                    "confirmLabel": JamiStrings.optionDelete
                                                });
        dlg.accepted.connect(function() {
            SharedServicesAdapter.removeSharedService(CurrentAccount.id, root.editingId);
            root.close();
        });
    }

    button2.text: JamiStrings.sharedServicesSave
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
            "preferredPort": root.servicePreferredPort.length > 0 ? root.servicePreferredPort : "0",
            "scheme": embedded ? "http" : root.effectiveScheme(),
            "directory": embedded ? root.serviceDirectory : "",
            "policy": root.servicePolicy,
            "allowedContacts": root.convertSelectedContactsToAllowed(),
            "enabled": "true"
        };
        var saved = false;
        if (root.editingId.length > 0) {
            service.id = root.editingId;
            saved = SharedServicesAdapter.updateSharedService(CurrentAccount.id, service);
        } else {
            saved = SharedServicesAdapter.addSharedService(CurrentAccount.id, service).length > 0;
        }
        if (!saved)
            return;
        root.close();
    }

    titleText: {
        if (editingId.length > 0) {
            return JamiStrings.edit;
        } else if (serviceType === "embedded") {
            return JamiStrings.sharedServicesAddWebsite
        } else {
            return JamiStrings.sharedServicesCustomService
        }
    }

    popupContent: ColumnLayout {
        spacing: 10
        width: JamiTheme.preferredDialogWidth

        NewMaterialTextField {
            id: nameField

            Layout.fillWidth: true

            leadingIconSource: JamiResources.label_24dp_svg

            placeholderText: JamiStrings.sharedServicesNameLabel
            textFieldContent: root.serviceName

            visible: !root.isEmbeddedService() || (root.isEmbeddedService() && root.serviceDirectory !== "")

            onModifiedTextFieldContentChanged: root.serviceName = modifiedTextFieldContent
        }


        NewMaterialTextField {
            id: descriptionField

            Layout.fillWidth: true

            leadingIconSource: JamiResources.swarm_details_panel_24dp_svg

            placeholderText: JamiStrings.sharedServicesDescriptionLabel
            textFieldContent: root.serviceDescription

            visible: !root.isEmbeddedService()

            onModifiedTextFieldContentChanged: root.serviceDescription = modifiedTextFieldContent
        }

        NewMaterialButton {
            Layout.fillWidth: true

            implicitHeight: JamiTheme.newMaterialButtonHeight

            outlinedButton: true
            iconSource: JamiResources.round_folder_24dp_svg
            text: root.serviceDirectory === "" ? JamiStrings.sharedServicesChooseDirectory : root.serviceDirectory

            visible: root.isEmbeddedService()

            onClicked: directoryDialog.open()
        }

        RowLayout {
            Layout.fillWidth: true

            spacing: 10

            visible: !root.isEmbeddedService()

            NewMaterialTextField {
                id: hostField

                Layout.fillWidth: true

                leadingIconSource: JamiResources.host_24dp_svg
                placeholderText: JamiStrings.sharedServicesHostLabel
                textFieldContent: root.serviceHost

                onModifiedTextFieldContentChanged: root.serviceHost = modifiedTextFieldContent
            }

            NewMaterialTextField {
                id: portField

                Layout.preferredWidth: 110

                leadingIconSource: JamiResources.plug_connect_24dp_svg
                placeholderText: JamiStrings.sharedServicesPortLabel
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
            Layout.bottomMargin: preferredPortField.inputIsValid ? 0 : 8

            visible: !root.isEmbeddedService()

            NewMaterialTextField {
                id: preferredPortField

                Layout.fillWidth: true

                leadingIconSource: JamiResources.plug_connect_24dp_svg
                placeholderText: JamiStrings.sharedServicesPreferredPortLabel
                textFieldContent: root.servicePreferredPort
                inputIsValid: root.hasValidPreferredPort()
                supportingText: !inputIsValid ? JamiStrings.sharedServicesPreferredPortRangeError : ""
                supportingTextColor: "#CC0022"
                borderColor: !inputIsValid ? "#CC0022" : JamiTheme.tintedBlue

                validator: RegularExpressionValidator {
                    regularExpression: /^[0-9]*$/
                }

                onModifiedTextFieldContentChanged: root.servicePreferredPort = modifiedTextFieldContent
            }

            NewIconButton {
                id: preferredPortWhatsThisButton

                Layout.alignment: Qt.AlignTop

                iconSource: JamiResources.bidirectional_help_outline_24dp_svg
                iconSize: JamiTheme.iconButtonMedium
                Accessible.name: JamiStrings.sharedServicesWhatsThis

                checked: preferredPortDetailsPopup.opened

                onClicked: {
                    if (preferredPortDetailsPopup.opened)
                        preferredPortDetailsPopup.close()
                    else
                        preferredPortDetailsPopup.open()
                }

                Popup {
                    id: preferredPortDetailsPopup

                    parent: parent
                    x: parent.width - width
                    y: - (parent.height + 16)

                    padding: 8

                    closePolicy: Popup.CloseOnEscape
                    visible: false
                    opacity: visible ? 1.0 : 0.0

                    contentItem: Text {
                        text: JamiStrings.sharedServicesPreferredPortDetails
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
                            anchors.fill: preferredPortDetailsPopup.background
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
            visible: !root.isEmbeddedService()

            NewMaterialTextField {
                id: customSchemeField

                Layout.fillWidth: true

                leadingIconSource: JamiResources.network_reverse_24dp_svg
                placeholderText: JamiStrings.sharedServicesCustomSchemeLabel
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
                Accessible.name: JamiStrings.sharedServicesWhatsThis

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
                        text: JamiStrings.sharedServicesUriSchemeDetails
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

                text: JamiStrings.sharedServicesPolicyLabel
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
                        append({ "value": "contacts", "label": JamiStrings.sharedServicesPolicyContacts });
                        append({ "value": "public", "label": JamiStrings.sharedServicesPolicyPublic });
                        append({ "value": "specific", "label": JamiStrings.sharedServicesPolicySpecific });
                    }
                }

                textRole: "label"
                valueRole: "value"

                font.pointSize: JamiTheme.buttonFontSize

                onActivated: root.servicePolicy = currentValue
            }
        }

        Flow {
            Layout.fillWidth: true

            spacing: 4

            visible: policyBox.currentValue === "specific"

            Repeater {
                model: root.selectedContacts

                delegate: JamiChip {
                    filledChip: true

                    text: UtilsAdapter.getBestNameForUri(CurrentAccount.id, modelData)
                    iconSource: JamiResources.close_black_24dp_svg
                    iconButtonToolTipText: JamiStrings.removeContact

                    onIconClicked: {
                        const idx = root.selectedContacts.indexOf(modelData)
                        if (idx !== -1)
                            root.selectedContacts.splice(idx, 1)
                    }
                }
            }

            JamiChip {
                outlinedChip: true

                text: JamiStrings.addAContact
                iconSource: JamiResources.add_24dp_svg

                // We need to treat this particular chip as a button
                // otehrwise the button of the chip would need to be
                // clicked to trigger the popup
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        var dlg = viewCoordinator.presentDialog(appWindow, "../../mainview/components/ContactPicker.qml", {
                                                                    "type": ContactList.ONE_TO_ONE
                                                                })
                        dlg.contactSelected.connect(function(uri) {
                            if (root.selectedContacts.indexOf(uri) === -1)
                                root.selectedContacts.push(uri)
                        })
                    }
                }

            }
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