import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import net.jami.Enums 1.1
import net.jami.Models 1.1
import "../../commoncomponents"
import "../js/keyboardshortcuttablecreation.js" as KeyboardShortcutTableCreation

Item {
    id: welcomeInfo

    property alias backgroundColor: bgRect.color
    property bool hasTitle: viewNode.hasTitle
    property bool hasDescription: viewNode.hasDescription

    property string title: viewNode.hasCustomTitle ? viewNode.customTitle : JamiStrings.welcomeToJami
    property string description: viewNode.hasCustomDescription ? viewNode.customDescription : JamiStrings.hereIsIdentifier

    readonly property real textWidth: isLong ? 270 : 330

    property int initialWidth: loader_bottomIdentifier.width + 2 * JamiTheme.mainViewMargin
    property bool isLong: false

    function getWidth() {
        return bgRect.width;
    }
    function getHeight() {
        return bgRect.height;
    }

    Rectangle {
        id: bgRect
        radius: 30
        color: JamiTheme.backgroundColor
        height: childrenRect.height + 2*JamiTheme.mainViewMargin
        width: childrenRect.width + 2*JamiTheme.mainViewMargin
        //anchors.centerIn: parent

        Behavior on width  {
            NumberAnimation {
                duration: JamiTheme.shortFadeDuration
            }
        }

        RowLayout{
            id:rowLayoutInfo
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.topMargin: JamiTheme.mainViewMargin
            anchors.leftMargin: JamiTheme.mainViewMargin
            ColumnLayout {
                id: columnLayoutInfo

                Loader {
                    id: loader_welcomeTitle
                    Layout.preferredHeight: item ? item.contentHeight : 0
                    sourceComponent: welcomeInfo.hasTitle ? component_welcomeTitle : undefined
                }

                Loader {
                    id: loader_identifierDescription
                    Layout.preferredWidth: textWidth
                    Layout.preferredHeight: item ? item.contentHeight : 0
                    sourceComponent: {
                        if (welcomeInfo.hasDescription) {
                            if (CurrentAccount.type !== Profile.Type.SIP) {
                                return component_identifierDescription;
                            } else {
                                return component_identifierDescriptionSIP;
                            }
                        } else {
                            return undefined;
                        }
                    }
                }

                Loader {
                    id: loader_bottomIdentifier
                    objectName: "loader_bottomIdentifier"
                    active: !welcomeInfo.isLong
                    source: "../../commoncomponents/JamiIdentifier.qml"
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredHeight: active ? item.getHeight() : 0
                    Layout.preferredWidth: active ? item.getWidth() : 0
                }

                Binding {
                    target: loader_bottomIdentifier.item
                    property: "isLong"
                    value: false
                }
            }

            Loader {
                id: loader_sideIdentifier
                objectName: "loader_sideIdentifier"
                active: welcomeInfo.isLong
                source: "../../commoncomponents/JamiIdentifier.qml"
                Layout.preferredHeight: active ? item.getHeight() : 0
                Layout.preferredWidth: active ? item.getWidth() : 0
            }
            Binding {
                target: loader_sideIdentifier.item
                property: "isLong"
                value: false
            }
        }
    }

    Component {
        id: component_welcomeTitle
        Label {
            id: welcomeTitle

            width: welcomeInfo.textWidth
            height: contentHeight

            font.pixelSize: JamiTheme.bigFontSize
            wrapMode: Text.WordWrap
            text: welcomeInfo.title
            color: JamiTheme.textColor
            textFormat: TextEdit.PlainText
        }
    }

    Component {
        id: component_identifierDescription
        Label {
            id: identifierDescription
            visible: CurrentAccount.type !== Profile.Type.SIP

            width: welcomeInfo.textWidth
            height: contentHeight
            font.pixelSize: JamiTheme.headerFontSize

            wrapMode: Text.WordWrap

            text: welcomeInfo.description
            lineHeight: 1.25
            color: JamiTheme.textColor
            textFormat: TextEdit.PlainText
        }
    }

    Component {
        id: component_identifierDescriptionSIP
        Label {
            id: identifierDescriptionSIP
            visible: CurrentAccount.type === Profile.Type.SIP

            width: welcomeInfo.textWidth
            height: contentHeight
            font.pixelSize: JamiTheme.headerFontSize

            wrapMode: Text.WordWrap

            text: JamiStrings.description
            color: JamiTheme.textColor
            textFormat: TextEdit.PlainText
        }
    }
}
