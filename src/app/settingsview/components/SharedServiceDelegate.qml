import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.impl

import net.jami.Constants 1.1
import net.jami.Adapters 1.1

import "../../commoncomponents"

ItemDelegate {
    id: root

    required property var modelData

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding,
                             implicitIndicatorHeight + topPadding + bottomPadding)

    padding: 8
    leftPadding: implicitHeight / 2 - serviceTypeIcon.height / 2
    rightPadding: implicitHeight / 2 - JamiTheme.switchPreferredHeight / 2
    spacing: 8

    function serviceHostForEndpoint(service) {
        var host = service.localHost || "localhost";
        if (host.indexOf(":") !== -1 && host[0] !== "[")
            return "[" + host + "]";
        return host;
    }

    function policyTag(policy) {
        if (policy === "public")
            return JamiStrings.sharedServicesPolicyTagPublic;
        if (policy === "specific")
            return JamiStrings.sharedServicesPolicyTagSpecific;
        return JamiStrings.sharedServicesPolicyTagContacts;
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

    contentItem: RowLayout {
        spacing: 4

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: implicitHeight

            spacing: 8

            IconImage {
                id: serviceTypeIcon

                Layout.alignment: Qt.AlignVCenter

                width: JamiTheme.iconButtonLarge
                height: JamiTheme.iconButtonLarge

                source: {
                    if (modelData.scheme === "http")
                        return JamiResources.language_24dp_svg;
                    else if (modelData.scheme === "https")
                        return JamiResources.vpn_lock_2_24dp_svg;
                    else
                        return JamiResources.build_circle_24dp_svg;
                }

                sourceSize.width: JamiTheme.iconButtonLarge
                sourceSize.height: JamiTheme.iconButtonLarge

                color: JamiTheme.textColor
            }

            Column {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 4

                Row {
                    spacing: 8
                    width: parent.width

                    Text {
                        width: Math.min(implicitWidth, parent.width - policyTagLabel.implicitWidth - parent.spacing)
                        text: modelData.name
                        color: JamiTheme.textColor

                        elide: Text.ElideRight
                        font.pixelSize: JamiTheme.sharedServicesDelegateTitlePixelSize
                    }

                    Label {
                        id: policyTagLabel

                        padding: 2
                        leftPadding: background.radius
                        rightPadding: background.radius

                        text: policyTag(modelData.policy)

                        color: JamiTheme.textColor

                        font.pixelSize: JamiTheme.sharedServicesDelegateDescriptionPixelSize

                        background: Rectangle {
                            radius: height / 2
                            border.color: JamiTheme.tintedBlue
                            color: JamiTheme.transparentColor
                        }
                    }
                }

                Text {
                    width: parent.width

                    visible: modelData.type !== "embedded"

                    text: modelData.description
                    color: JamiTheme.textColor
                    opacity: 0.7

                    elide: Text.ElideRight
                    font.pixelSize: JamiTheme.sharedServicesDelegateDescriptionPixelSize
                    font.italic: true
                }
            }
        }

        Row {
            Layout.alignment: Qt.AlignRight
            Layout.preferredHeight: implicitHeight

            spacing: 4

            NewIconButton {
                id: editButton

                iconSize: JamiTheme.iconButtonMedium
                iconSource: JamiResources.settings_24dp_svg
                toolTipText: JamiStrings.settings

                onClicked: {
                    viewCoordinator.presentDialog(appWindow, "settingsview/components/SharedServiceDialog.qml", {
                                                      "serviceType": modelData.type || "custom",
                                                      "editingId": modelData.id,
                                                      "serviceName": modelData.name || "",
                                                      "serviceDescription": modelData.description || "",
                                                      "serviceHost": modelData.localHost || "localhost",
                                                      "servicePort": modelData.localPort || "",
                                                      "servicePreferredPort": (modelData.preferredPort && modelData.preferredPort !== "0") ? modelData.preferredPort : "",
                                                      "serviceDirectory": modelData.directory || "",
                                                      "serviceScheme": modelData.type === "embedded" ? "http" : modelData.scheme,
                                                      "servicePolicy": modelData.policy || "contacts",
                                                      "serviceAllowed": modelData.allowedContacts || "",
                                                      "serviceEnabled": modelData.enabled === "true"
                                                  });
                }
            }

            NewIconButton {
                id: openButton

                iconSize: JamiTheme.iconButtonMedium
                iconSource: root.isHttpService(modelData) ? JamiResources.open_in_new_24dp_svg : JamiResources.content_copy_24dp_svg
                toolTipText: root.isHttpService(modelData) ? JamiStrings.sharedServicesOpenUrl.arg(root.serviceUrl(modelData)) : JamiStrings.sharedServicesCopyEndpoint.arg(root.serviceEndpoint(modelData))

                onClicked: {
                    if (root.isHttpService(modelData))
                        Qt.openUrlExternally(root.serviceUrl(modelData));
                    else
                        UtilsAdapter.setClipboardText(root.serviceEndpoint(modelData));
                }
            }

            JamiSwitch {
                anchors.verticalCenter: parent.verticalCenter
                checked: modelData.enabled === "true"
                onClicked: {
                    modelData.enabled = checked ? "true" : "false"
                    SharedServicesAdapter.updateSharedService(CurrentAccount.id, modelData);
                }
            }
        }
    }

    background: Rectangle {
        radius: height / 2
        color: root.hovered || root.highlighted ? JamiTheme.smartListSelectedColor : JamiTheme.editBackgroundColor
    }
}