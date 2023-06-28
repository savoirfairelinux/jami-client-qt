import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import net.jami.Enums 1.1
import net.jami.Models 1.1
import "../../commoncomponents"
import "../js/keyboardshortcuttablecreation.js" as KeyboardShortcutTableCreation


Item{


    id: welcomeInfo

    property alias backgroundColor: bgRect.color
    property bool hasTitle: viewNode.hasTitle
    property bool hasDescription: viewNode.hasDescription

    property string title: viewNode.hasCustomTitle ? viewNode.customTitle : JamiStrings.welcomeToJami
    property string description: viewNode.hasCustomDescription ? viewNode.customDescription : JamiStrings.hereIsIdentifier

    readonly property real textWidth: 330

    property int initialWidth: identifier.width + 2 * JamiTheme.mainViewMargin
    property bool isLong :  false

    width : getWidth()
    height: getHeight()
    Layout.alignment: Qt.AlignVCenter

    function getWidth(){
        return initialWidth + (isLong ? textWidth + JamiTheme.mainViewMargin: 0);
    }
    function getHeight(){
        return 250;
    }

    Rectangle {
        id: bgRect
        radius: 30
        color: JamiTheme.backgroundColor
        height: childrenRect.height + 1 * JamiTheme.mainViewMargin

        width: welcomeInfo.width
        anchors.centerIn: parent


        Behavior on width  {
            NumberAnimation {
                duration: JamiTheme.shortFadeDuration
            }
        }

        ColumnLayout{
            id: columnLayoutInfo

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.topMargin: JamiTheme.mainViewMargin
            anchors.leftMargin: JamiTheme.mainViewMargin

            width:  childrenRect.width


            Loader {
                id: loader_welcomeTitle
                //height: item ? item.contentHeight : 0
                Layout.preferredHeight: item ? item.contentHeight : 0
                sourceComponent: welcomeInfo.hasTitle ? component_welcomeTitle : undefined
            }

            Loader {
                id: loader_identifierDescription
                Layout.preferredWidth: textWidth
                Layout.preferredHeight: item ? item.contentHeight : 0
                sourceComponent:{
                    if (welcomeInfo.hasDescription){
                        if(CurrentAccount.type !== Profile.Type.SIP){
                            return component_identifierDescription
                        }else{
                            return component_descriptionLabel
                        }
                    }else {
                        return undefined
                    }
                }
            }
        }

        JamiIdentifier {

            id: identifier

            isLong: false
            visible: CurrentAccount.type !== Profile.Type.SIP
            anchors.top: welcomeInfo.isLong ? parent.top : columnLayoutInfo.bottom
            anchors.right: parent.right
            anchors.topMargin: JamiTheme.preferredMarginSize
            anchors.rightMargin: JamiTheme.mainViewMargin
            anchors.leftMargin: JamiTheme.mainViewMargin
        }
    }

    Component {
        id: component_welcomeTitle
        Label {
            id: welcomeTitle

            width:  welcomeInfo.textWidth
            height: contentHeight

            font.pixelSize: JamiTheme.bigFontSize

            wrapMode: Text.WordWrap
            //horizontalAlignment: Text.AlignLeft
            //verticalAlignment: Text.AlignVCenter

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
        id: component_descriptionLabel
        Label {
            id: descriptionLabel
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
