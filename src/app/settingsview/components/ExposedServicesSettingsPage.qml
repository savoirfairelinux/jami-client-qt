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

    property var services: []

    function refresh() {
        services = ExposedServicesAdapter.getExposedServices(CurrentAccount.id);
    }

    function policyTag(policy) {
        if (policy === "public")
            return JamiStrings.exposedServicePolicyTagPublic;
        if (policy === "specific")
            return JamiStrings.exposedServicePolicyTagSpecific;
        return JamiStrings.exposedServicePolicyTagContacts;
    }

    function serviceHostForEndpoint(service) {
        var host = service.localHost || "localhost";
        if (host.indexOf(":") !== -1 && host[0] !== "[")
            return "[" + host + "]";
        return host;
    }

    function serviceEndpoint(service) {
        return root.serviceHostForEndpoint(service) + ":" + (service.localPort || "");
    }

    function serviceScheme(service) {
        return service.scheme || (service.type === "embedded" ? "http" : "");
    }

    function isHttpService(service) {
        var scheme = root.serviceScheme(service);
        return scheme === "http" || scheme === "https";
    }

    function serviceUrl(service) {
        return root.serviceScheme(service) + "://" + root.serviceEndpoint(service);
    }

    function resetEditor() {
        serviceEditorDialog.editingId = "";
        serviceEditorDialog.serviceType = "embedded";
        serviceEditorDialog.serviceName = "";
        serviceEditorDialog.serviceDescription = "";
        serviceEditorDialog.serviceHost = "localhost";
        serviceEditorDialog.servicePort = "";
        serviceEditorDialog.serviceDirectory = "";
        serviceEditorDialog.setServiceScheme("http");
        serviceEditorDialog.servicePolicy = "contacts";
        serviceEditorDialog.serviceAllowed = "";
        serviceEditorDialog.serviceEnabled = true;
    }

    function editService(service) {
        serviceEditorDialog.editingId = service.id;
        serviceEditorDialog.serviceType = service.type || "custom";
        serviceEditorDialog.serviceName = service.name || "";
        serviceEditorDialog.serviceDescription = service.description || "";
        serviceEditorDialog.serviceHost = service.localHost || "localhost";
        serviceEditorDialog.servicePort = service.localPort || "";
        serviceEditorDialog.serviceDirectory = service.directory || "";
        serviceEditorDialog.setServiceScheme(service.scheme || (serviceEditorDialog.serviceType === "embedded" ? "http" : ""));
        serviceEditorDialog.servicePolicy = service.policy || "contacts";
        serviceEditorDialog.serviceAllowed = service.allowedContacts || "";
        serviceEditorDialog.serviceEnabled = service.enabled === "true";
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

        FolderDialog {
            id: directoryDialog

            title: JamiStrings.selectFolder
            currentFolder: serviceEditorDialog.serviceDirectory.length > 0 ? serviceEditorDialog.serviceDirectory : StandardPaths.writableLocation(StandardPaths.HomeLocation)
            options: FolderDialog.ShowDirsOnly

            onAccepted: serviceEditorDialog.serviceDirectory = UtilsAdapter.getAbsPath(folder.toString())
        }

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
                iconSource: JamiResources.round_add_24dp_svg
                onClicked: {
                    root.resetEditor();
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
                implicitHeight: Math.max(rowLayout.implicitHeight + 24, 72)
                radius: height / 2
                color: JamiTheme.editBackgroundColor
                border.color: JamiTheme.tabbarBorderColor
                border.width: 1

                RowLayout {
                    id: rowLayout
                    anchors.fill: parent
                    anchors.leftMargin: 22
                    anchors.rightMargin: 22
                    anchors.topMargin: 12
                    anchors.bottomMargin: 12
                    spacing: 10

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 4

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            Text {
                                Layout.fillWidth: true
                                text: rowRect.modelData.name
                                color: JamiTheme.textColor
                                font.weight: Font.DemiBold
                                font.pixelSize: JamiTheme.settingsDescriptionPixelSize
                                elide: Text.ElideRight
                            }
                            Rectangle {
                                Layout.alignment: Qt.AlignVCenter
                                radius: height / 2
                                color: JamiTheme.tintedBlue
                                implicitWidth: tagText.implicitWidth + 12
                                implicitHeight: tagText.implicitHeight + 6
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
                                Layout.alignment: Qt.AlignVCenter
                                text: JamiStrings.exposedServiceDisabled
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
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Text {
                            visible: rowRect.modelData.type === "embedded" && (rowRect.modelData.directory || "").length > 0
                            text: JamiStrings.exposedServiceDirectory.arg(rowRect.modelData.directory || "")
                            color: JamiTheme.faddedLastInteractionFontColor
                            font.pixelSize: JamiTheme.settingsDescriptionPixelSize - 2
                            elide: Text.ElideMiddle
                            Layout.fillWidth: true
                        }
                    }

                    RowLayout {
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 4

                        NewIconButton {
                            iconSize: JamiTheme.iconButtonMedium
                            iconSource: root.isHttpService(rowRect.modelData) ? JamiResources.link_web_black_24dp_svg : JamiResources.content_copy_24dp_svg
                            toolTipText: root.isHttpService(rowRect.modelData) ? JamiStrings.exposedServiceOpenUrl.arg(root.serviceUrl(rowRect.modelData)) : JamiStrings.exposedServiceCopyEndpoint.arg(root.serviceEndpoint(rowRect.modelData))
                            onClicked: {
                                if (root.isHttpService(rowRect.modelData))
                                    Qt.openUrlExternally(root.serviceUrl(rowRect.modelData));
                                else
                                    UtilsAdapter.setClipboardText(root.serviceEndpoint(rowRect.modelData));
                            }
                        }

                        NewIconButton {
                            iconSize: JamiTheme.iconButtonMedium
                            iconSource: JamiResources.round_edit_24dp_svg
                            toolTipText: JamiStrings.edit
                            onClicked: {
                                root.editService(rowRect.modelData);
                                serviceEditorDialog.open();
                            }
                        }

                        NewIconButton {
                            iconSize: JamiTheme.iconButtonMedium
                            iconSource: JamiResources.delete_24dp_svg
                            color: JamiTheme.buttonTintedRed
                            hoveredColor: JamiTheme.buttonTintedRed
                            toolTipText: JamiStrings.optionDelete
                            onClicked: {
                                ExposedServicesAdapter.removeExposedService(CurrentAccount.id, rowRect.modelData.id);
                                root.refresh();
                            }
                        }
                    }
                }
            }
        }
    }

    BaseModalDialog {
        id: serviceEditorDialog

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

        titleText: editingId.length > 0 ? JamiStrings.edit : JamiStrings.exposedServicesAdd

        popupContent: ColumnLayout {
            spacing: 10
            Layout.preferredWidth: 440

            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                Text {
                    text: JamiStrings.exposedServiceTypeLabel
                    color: JamiTheme.textColor
                    font.pointSize: JamiTheme.settingsFontSize
                    Layout.fillWidth: true
                }
                SettingParaCombobox {
                    id: typeBox
                    Layout.preferredWidth: 240
                    textRole: "label"
                    valueRole: "value"
                    font.pointSize: JamiTheme.buttonFontSize
                    currentIndex: serviceEditorDialog.typeComboIndex()
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
                    onActivated: {
                        serviceEditorDialog.serviceType = currentValue;
                        if (currentValue === "embedded") {
                            serviceEditorDialog.serviceHost = "localhost";
                            serviceEditorDialog.setServiceScheme("http");
                        } else if (serviceEditorDialog.serviceHost.length === 0) {
                            serviceEditorDialog.serviceHost = "localhost";
                        }
                    }
                }
            }

            NewMaterialTextField {
                id: nameField
                Layout.fillWidth: true
                placeholderText: JamiStrings.exposedServiceNameLabel
                textFieldContent: serviceEditorDialog.serviceName
                onModifiedTextFieldContentChanged: serviceEditorDialog.serviceName = modifiedTextFieldContent
            }

            NewMaterialTextField {
                id: descriptionField
                Layout.fillWidth: true
                placeholderText: JamiStrings.exposedServiceDescriptionLabel
                textFieldContent: serviceEditorDialog.serviceDescription
                onModifiedTextFieldContentChanged: serviceEditorDialog.serviceDescription = modifiedTextFieldContent
            }

            RowLayout {
                visible: serviceEditorDialog.isEmbeddedService()
                Layout.fillWidth: true
                spacing: 10
                NewMaterialTextField {
                    id: directoryField
                    Layout.fillWidth: true
                    readOnly: true
                    placeholderText: JamiStrings.exposedServiceDirectoryPlaceholder
                    textFieldContent: serviceEditorDialog.serviceDirectory
                }
                NewMaterialButton {
                    implicitHeight: JamiTheme.newMaterialButtonHeight
                    outlinedButton: true
                    text: JamiStrings.exposedServiceChooseDirectory
                    iconSource: JamiResources.round_folder_24dp_svg
                    onClicked: directoryDialog.open()
                }
            }

            RowLayout {
                visible: !serviceEditorDialog.isEmbeddedService()
                Layout.fillWidth: true
                spacing: 10
                NewMaterialTextField {
                    id: hostField
                    Layout.fillWidth: true
                    placeholderText: JamiStrings.exposedServiceHostLabel
                    textFieldContent: serviceEditorDialog.serviceHost
                    onModifiedTextFieldContentChanged: serviceEditorDialog.serviceHost = modifiedTextFieldContent
                }
                NewMaterialTextField {
                    id: portField
                    Layout.preferredWidth: 110
                    placeholderText: JamiStrings.exposedServicePortLabel
                    textFieldContent: serviceEditorDialog.servicePort
                    validator: IntValidator {
                        bottom: 1
                        top: 65535
                    }
                    onModifiedTextFieldContentChanged: serviceEditorDialog.servicePort = modifiedTextFieldContent
                }
            }

            RowLayout {
                visible: !serviceEditorDialog.isEmbeddedService()
                Layout.fillWidth: true
                spacing: 10
                Text {
                    text: JamiStrings.exposedServiceSchemeLabel
                    color: JamiTheme.textColor
                    font.pointSize: JamiTheme.settingsFontSize
                    Layout.fillWidth: true
                }
                SettingParaCombobox {
                    id: schemeBox
                    Layout.preferredWidth: 240
                    textRole: "label"
                    valueRole: "value"
                    font.pointSize: JamiTheme.buttonFontSize
                    currentIndex: serviceEditorDialog.schemeComboIndex()
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
                    onActivated: {
                        serviceEditorDialog.serviceSchemeSelection = currentValue;
                        serviceEditorDialog.serviceScheme = serviceEditorDialog.effectiveScheme();
                    }
                }
            }

            NewMaterialTextField {
                id: customSchemeField
                visible: !serviceEditorDialog.isEmbeddedService() && serviceEditorDialog.serviceSchemeSelection === "custom"
                Layout.fillWidth: true
                placeholderText: JamiStrings.exposedServiceCustomSchemeLabel
                textFieldContent: serviceEditorDialog.serviceCustomScheme
                onModifiedTextFieldContentChanged: {
                    serviceEditorDialog.serviceCustomScheme = modifiedTextFieldContent;
                    serviceEditorDialog.serviceScheme = serviceEditorDialog.effectiveScheme();
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                Text {
                    text: JamiStrings.exposedServicePolicyLabel
                    color: JamiTheme.textColor
                    font.pointSize: JamiTheme.settingsFontSize
                    Layout.fillWidth: true
                }
                SettingParaCombobox {
                    id: policyBox
                    Layout.preferredWidth: 240
                    textRole: "label"
                    valueRole: "value"
                    font.pointSize: JamiTheme.buttonFontSize
                    currentIndex: serviceEditorDialog.policyComboIndex()
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
                    onActivated: serviceEditorDialog.servicePolicy = currentValue
                }
            }

            NewMaterialTextField {
                id: allowedField
                visible: serviceEditorDialog.servicePolicy === "specific"
                Layout.fillWidth: true
                placeholderText: JamiStrings.exposedServiceAllowedLabel
                textFieldContent: serviceEditorDialog.serviceAllowed
                onModifiedTextFieldContentChanged: serviceEditorDialog.serviceAllowed = modifiedTextFieldContent
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                Text {
                    text: JamiStrings.exposedServiceEnabled
                    color: JamiTheme.textColor
                    font.pointSize: JamiTheme.settingsFontSize
                    Layout.fillWidth: true
                }
                JamiSwitch {
                    checked: serviceEditorDialog.serviceEnabled
                    onToggled: serviceEditorDialog.serviceEnabled = checked
                }
            }
        }

        button1.text: JamiStrings.exposedServiceSave
        button1.iconSource: JamiResources.save_file_24dp_svg
        button1.enabled: serviceEditorDialog.canSave()
        button1.onClicked: {
            var embedded = serviceEditorDialog.isEmbeddedService();
            var service = {
                "type": serviceEditorDialog.serviceType,
                "name": serviceEditorDialog.serviceName.trim(),
                "description": serviceEditorDialog.serviceDescription,
                "localHost": embedded ? "localhost" : serviceEditorDialog.serviceHost.trim(),
                "localPort": embedded ? "0" : serviceEditorDialog.servicePort,
                "scheme": embedded ? "http" : serviceEditorDialog.effectiveScheme(),
                "directory": embedded ? serviceEditorDialog.serviceDirectory : "",
                "policy": serviceEditorDialog.servicePolicy,
                "allowedContacts": serviceEditorDialog.serviceAllowed,
                "enabled": serviceEditorDialog.serviceEnabled ? "true" : "false"
            };
            var saved = false;
            if (serviceEditorDialog.editingId.length > 0) {
                service.id = serviceEditorDialog.editingId;
                saved = ExposedServicesAdapter.updateExposedService(CurrentAccount.id, service);
            } else {
                saved = ExposedServicesAdapter.addExposedService(CurrentAccount.id, service).length > 0;
            }
            if (!saved)
                return;
            serviceEditorDialog.close();
            root.refresh();
        }

        button2.text: JamiStrings.exposedServiceCancel
        button2.iconSource: JamiResources.cancel_24dp_svg
        button2.onClicked: serviceEditorDialog.close()
    }
}
