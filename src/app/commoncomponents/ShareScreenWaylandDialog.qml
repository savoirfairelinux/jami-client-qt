import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.impl

import net.jami.Constants 1.1
import net.jami.Adapters 1.1

BaseModalDialog {
    id: root

    property bool shareScreenAudio: true
    property int selectionType: 0  // 0 = none, 1 = entire screen, 2 = window
    property bool cancelDialog: false

    titleText: "Share screen"

    closeButtonVisible: false

    button1.text: "Share"
    button1.iconSource: JamiResources.share_screen_black_24dp_svg
    button1.enabled: selectionType !== 0
    button1.onClicked: {
        cancelDialog = false;
        close();
    }
    button2.text: "Cancel"
    button2.onClicked: {
        cancelDialog = true;
        close();
    }


    onClosed: {
        if (!cancelDialog) {
            if (root.selectionType === 1) {
                AvAdapter.shareEntireScreenWayland(root.shareScreenAudio)
            }
            else if (root.selectionType === 2) {
                AvAdapter.shareWindowWayland(root.shareScreenAudio)
            }
        }
    }

    Behavior on implicitHeight {
        NumberAnimation {
            duration: JamiTheme.shortFadeDuration
        }
    }

    popupContent: Column {
        Row {
            id: selectionRow
            spacing: 8

            Control {
                id: desktopSelection

                property bool selected: false

                implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                                        implicitContentWidth + leftPadding + rightPadding)
                implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                                         implicitContentHeight + topPadding + bottomPadding)

                padding: 64

                contentItem: ColumnLayout {
                    spacing: 8
                    Text {
                        text: "Share entire screen"
                        color: JamiTheme.textColor
                        horizontalAlignment: Text.AlignHCenter
                    }

                    IconImage {
                        Layout.alignment: Qt.AlignHCenter

                        width: JamiTheme.iconButtonLarge
                        height: JamiTheme.iconButtonLarge

                        source: JamiResources.laptop_black_24dp_svg
                        sourceSize.width: JamiTheme.iconButtonLarge
                        sourceSize.height: JamiTheme.iconButtonLarge

                        color: desktopSelection.hovered || desktopSelection.selected ? JamiTheme.tintedBlue : JamiTheme.textColor

                        Behavior on color {
                            ColorAnimation {
                                duration: JamiTheme.shortFadeDuration
                            }
                        }
                    }
                }

                background: Rectangle {
                    radius: 8
                    color: desktopSelection.selected ? JamiTheme.smartListSelectedColor : JamiTheme.editBackgroundColor
                    border.color: desktopSelection.hovered || desktopSelection.selected ? JamiTheme.tintedBlue : JamiTheme.hoveredButtonColor
                    border.width: 2

                    Behavior on border.color {
                        ColorAnimation {
                            duration: JamiTheme.shortFadeDuration
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        desktopSelection.selected = true;
                        windowSelection.selected = false;
                        root.selectionType = 1;
                    }
                }
            }

            Control {
                id: windowSelection

                property bool selected: false

                implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                                        implicitContentWidth + leftPadding + rightPadding)
                implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                                         implicitContentHeight + topPadding + bottomPadding)

                padding: 64

                contentItem: ColumnLayout {
                    spacing: 8
                    Text {
                        text: "Share a window"
                        color: JamiTheme.textColor
                        horizontalAlignment: Text.AlignHCenter
                    }
                    IconImage {
                        Layout.alignment: Qt.AlignHCenter

                        width: JamiTheme.iconButtonLarge
                        height: JamiTheme.iconButtonLarge

                        source: JamiResources.window_black_svg
                        sourceSize.width: JamiTheme.iconButtonLarge
                        sourceSize.height: JamiTheme.iconButtonLarge

                        color: windowSelection.hovered || windowSelection.selected ? JamiTheme.tintedBlue : JamiTheme.textColor

                        Behavior on color {
                            ColorAnimation {
                                duration: JamiTheme.shortFadeDuration
                            }
                        }
                    }
                }

                background: Rectangle {
                    radius: 8
                    color: windowSelection.selected ? JamiTheme.smartListSelectedColor : JamiTheme.editBackgroundColor
                    border.color: windowSelection.hovered || windowSelection.selected ? JamiTheme.tintedBlue : JamiTheme.hoveredButtonColor
                    border.width: 2

                    Behavior on border.color {
                        ColorAnimation {
                            duration: JamiTheme.shortFadeDuration
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        windowSelection.selected = true;
                        desktopSelection.selected = false;
                        root.selectionType = 2;
                    }
                }
            }
        }


        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            CheckBox {
                id: audioCheckbox

                anchors.verticalCenter: parent.verticalCenter

                text: "Share desktop audio"
                checked: root.shareScreenAudio

                indicator: IconImage {
                    anchors.verticalCenter: audioCheckbox.verticalCenter
                    width: JamiTheme.iconButtonMedium
                    height: JamiTheme.iconButtonMedium

                    source: root.shareScreenAudio ? JamiResources.check_box_24dp_svg : JamiResources.check_box_outline_blank_24dp_svg
                    sourceSize.width: JamiTheme.iconButtonMedium
                    sourceSize.height: JamiTheme.iconButtonMedium

                    color: JamiTheme.textColor
                }

                contentItem: Text {
                    text: audioCheckbox.text
                    color: JamiTheme.textColor
                    verticalAlignment: Text.AlignVCenter
                    leftPadding: audioCheckbox.indicator.implicitWidth + 8
                }

                onClicked: {root.shareScreenAudio = !root.shareScreenAudio}
            }

            NewIconButton {
                anchors.verticalCenter: parent.verticalCenter

                iconSize: JamiTheme.iconButtonSmall
                iconSource: JamiResources.bidirectional_help_outline_24dp_svg
                toolTipText: JamiStrings.showMore

                onClicked: showMoreText.visible = !showMoreText.visible
            }
        }

        Text {
            id: showMoreText

            anchors.horizontalCenter: parent.horizontalCenter

            width: selectionRow.width

            text: "Leaving this checked will share all audio coming from your desktop (including from windows which you choose not to share)"
            horizontalAlignment: Text.AlignHCenter
            color: JamiTheme.textColor
            wrapMode: Text.WordWrap

            visible: false

            opacity: visible ? 1.0 : 0.0

            Behavior on opacity {
                NumberAnimation {
                    duration: JamiTheme.shortFadeDuration
                }
            }
        }
    }
}
