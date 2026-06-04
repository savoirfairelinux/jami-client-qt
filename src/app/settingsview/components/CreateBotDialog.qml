import QtQuick
import QtQuick.Controls
import QtQuick.Controls.impl
import QtQuick.Layouts
import Qt.labs.platform
import Qt5Compat.GraphicalEffects

import net.jami.Constants 1.1
import net.jami.Adapters 1.1

import "../../commoncomponents"

BaseModalDialog {
    id: root

    property string botDisplayName: ""
    property string botUsername: ""
    property string botAvatarPath: ""
    property string generatedToken: ""
    property string pendingTokenLabel: ""
    property string pendingBotAccountId: ""

    enum Stage {ChooseDisplayName = 0, CopyToken = 1}
    property int currentStage: CreateBotDialog.Stage.ChooseDisplayName

    titleText: JamiStrings.createNewBot

    closePolicy: currentStage === CreateBotDialog.Stage.CopyToken ? Popup.CloseOnEscape : (Popup.CloseOnEscape | Popup.CloseOnPressOutside)

    popupContent: ColumnLayout {
        id: popupContentColumnLayout

        width: root.maximumPopupWidth
        spacing: 16

        Loader {
            id: chooseDisplayNameStage

            Layout.alignment: Qt.AlignCenter
            Layout.maximumWidth: root.maximumPopupWidth

            active: currentStage === CreateBotDialog.Stage.ChooseDisplayName
            visible: active

            sourceComponent: ColumnLayout {

                spacing: 16

                AbstractButton {
                    id: avatarPicker

                    Layout.alignment: Qt.AlignHCenter

                    width: 150
                    height: 150
                    padding: 0

                    contentItem: Item {
                        Image {
                            id: avatarImage

                            anchors.fill: parent

                            source: root.botAvatarPath ? ("file://" + root.botAvatarPath) : ""

                            fillMode: Image.PreserveAspectCrop
                            visible: root.botAvatarPath.length > 0

                            layer.enabled: root.botAvatarPath.length > 0
                            layer.effect: OpacityMask {
                                maskSource: Rectangle {
                                    width: avatarImage.width
                                    height: avatarImage.height
                                    radius: height / 2
                                }
                            }
                        }

                        IconImage {
                            anchors.centerIn: parent

                            source: JamiResources.add_24dp_svg
                            sourceSize.width: JamiTheme.iconButtonMedium
                            sourceSize.height: JamiTheme.iconButtonMedium

                            color: JamiTheme.textColor

                            scale: avatarPicker.hovered || avatarPicker.activeFocus ? JamiTheme.iconButtonLarge/ JamiTheme.iconButtonMedium: 1.0
                            Behavior on scale {
                                NumberAnimation {
                                    duration: JamiTheme.shortFadeDuration
                                }
                            }

                            visible: root.botAvatarPath.length === 0
                        }
                    }

                    background: Rectangle {
                        radius: height / 2
                        color: JamiTheme.botImagePickerBackgroundColor
                    }

                    onClicked: {
                        var dlg = viewCoordinator.presentDialog(appWindow, "commoncomponents/JamiFileDialog.qml", {
                                                                    title: JamiStrings.selectProfilePicture,
                                                                    fileMode: JamiFileDialog.OpenFile,
                                                                    folder: StandardPaths.writableLocation(StandardPaths.PicturesLocation),
                                                                    nameFilters: [JamiStrings.imageFiles, JamiStrings.allFiles]
                                                                });
                        dlg.fileAccepted.connect(function(file) {
                            root.botAvatarPath = UtilsAdapter.getAbsPath(file);
                            UtilsAdapter.setTempCreationImageFromFile(root.botAvatarPath);
                            appWindow.raise();
                            appWindow.requestActivate();
                        });
                    }

                    Accessible.role: Accessible.Button
                    Accessible.name: JamiStrings.selectProfilePicture
                }

                NewMaterialButton {
                    Layout.alignment: Qt.AlignHCenter
                    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                                             implicitContentHeight + topPadding + bottomPadding)

                    outlinedButton: true
                    color: JamiTheme.redColor

                    text: JamiStrings.removeImage

                    visible: root.botAvatarPath !== ""

                    onClicked: root.botAvatarPath = ""
                }


                NewMaterialTextField {
                    id: botDisplayNameTextField

                    Layout.fillWidth: true

                    leadingIconSource: JamiResources.robot_2_24dp_svg
                    placeholderText: JamiStrings.botName

                    onEditingFinished: root.botDisplayName = modifiedTextFieldContent
                }
            }
        }

        Loader {
            id: copyTokenStage

            Layout.fillWidth: true
            Layout.maximumWidth: root.maximumPopupWidth

            active: currentStage === CreateBotDialog.Stage.CopyToken
            visible: active

            sourceComponent: ColumnLayout {

                spacing: 8

                Text {
                    Layout.fillWidth: true

                    color: JamiTheme.textColor
                    text: JamiStrings.botTokenInfo
                }

                RowLayout {
                    Layout.fillWidth: true

                    spacing: 4

                    TextArea {
                        id: generatedTokenLabel

                        Layout.fillWidth: true

                        padding: 8

                        text: root.generatedToken
                        color: JamiTheme.textColor
                        wrapMode: Text.WrapAnywhere
                        font.family: JamiTheme.ubuntuMonoFontFamily

                        readOnly: true
                        selectByMouse: true
                        selectByKeyboard: true

                        selectionColor: JamiTheme.tintedBlue
                        selectedTextColor: JamiTheme.textColor

                        background: Rectangle {
                            radius: height / 2
                            color: JamiTheme.globalBackgroundColor
                        }
                    }

                    NewIconButton {
                        Layout.alignment: Qt.AlignVCenter

                        iconSize: JamiTheme.iconButtonMedium
                        iconSource: JamiResources.content_copy_24dp_svg
                        toolTipText: JamiStrings.copy

                        onClicked: {
                            UtilsAdapter.setClipboardText(root.generatedToken)
                        }
                    }
                }
            }
        }
    }

    button1.text: root.currentStage === CreateBotDialog.Stage.CopyToken ? "Finish" : "Next"

    button1.onClicked: {
        switch(root.currentStage) {
        case CreateBotDialog.Stage.ChooseDisplayName:
            // Create the account with nothing but a display name and an image
            root.pendingTokenLabel = root.botDisplayName;
            root.pendingBotAccountId = "";
            const botOwner = CurrentAccount.uri
            AccountAdapter.createJamiAccount(JamiQmlUtils.setUpAccountCreationInputPara({
                                                                                            "registeredName": "",
                                                                                            "alias": root.botDisplayName,
                                                                                            "password": "",
                                                                                            "avatar": UtilsAdapter.tempCreationImage(),
                                                                                            "botOwner": "jami:" + botOwner
                                                                                        }));
            break;
        case CreateBotDialog.Stage.CopyToken:
            UtilsAdapter.setTempCreationImageFromString("", "temp");
            root.close();
            break;
        default:
            UtilsAdapter.setTempCreationImageFromString("", "temp");
            root.close();
        }
    }

    Connections {
        target: AccountAdapter

        function onAccountAdded(accountId, index) {
            if (root.currentStage !== CreateBotDialog.Stage.ChooseDisplayName)
                return;

            root.pendingBotAccountId = accountId;
            ApiTokenListModel.accountId = accountId;
            root.generatedToken = ApiTokenListModel.createToken(root.pendingTokenLabel);
            root.pendingTokenLabel = "";
            root.currentStage = CreateBotDialog.Stage.CopyToken;
        }
    }

    Component.onDestruction: UtilsAdapter.setTempCreationImageFromString("", "temp")

}