import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import net.jami.Models 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"

BaseModalDialog {
    id: root

    title: JamiStrings.confirmAddition
    closeButtonVisible: false

    property string contactName: ""
    property string contactId: ""
    property bool isBanned: false

    signal addContact(string contactId, bool isBanned)
    signal dialogClosed()

    button1.text: JamiStrings.optionAdd
    button1.onClicked: {
        addContact(contactId, isBanned);
        close();
    }

    button2.text: JamiStrings.optionCancel
    button2.onClicked: close()

    onClosed: dialogClosed()

    popupContent: ColumnLayout {
        spacing: 10

        Label {
            Layout.alignment: Qt.AlignLeft
            Layout.maximumWidth: root.width - 4 * JamiTheme.preferredMarginSize
            color: JamiTheme.textColor
            text: JamiStrings.confirmAddUser.arg(root.contactName)
            font.pointSize: JamiTheme.textFontSize
            wrapMode: Text.Wrap
        }

        Rectangle {
            color: JamiTheme.backgroundRectangleColor
            Layout.preferredWidth: useridlabel.width + 100
            Layout.preferredHeight: contactInfoLayout.height
            Layout.maximumWidth: root.width - 80
            radius: 5

            ColumnLayout {
                id: contactInfoLayout
                anchors.centerIn: parent
                width: parent.width
                spacing: 10

                RowLayout {
                    Layout.margins: 10
                    spacing: 10

                    Avatar {
                        Layout.preferredWidth: 56
                        Layout.preferredHeight: 56
                        imageId: root.contactId
                        showPresenceIndicator: false
                        mode: Avatar.Mode.Contact
                    }

                    ColumnLayout {
                        spacing: 5
                        Layout.alignment: Qt.AlignLeft

                        Label {
                            text: root.contactName
                            font.pointSize: JamiTheme.settingsFontSize
                            color: JamiTheme.textColor
                            elide: Text.ElideRight
                        }

                        Label {
                            id: useridlabel
                            text: root.contactId
                            font.pointSize: JamiTheme.textFontSize
                            color: JamiTheme.faddedFontColor
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }

        Rectangle {
            color: JamiTheme.warningBackground
            Layout.preferredWidth: parent.width
            Layout.preferredHeight: warningLayout.height + 20
            Layout.maximumWidth: root.width - 80
            radius: 5
            border.color: JamiTheme.warningBorder
            border.width: 1

            RowLayout {
                id: warningLayout
                anchors.centerIn: parent
                anchors.margins: 15
                width: parent.width - 30
                spacing: 10

                Image {
                    source: JamiResources.hand_black_24dp_svg
                    fillMode: Image.PreserveAspectFit
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 24
                    Layout.alignment: Qt.AlignTop
                    sourceSize.width: 24
                    sourceSize.height: 24
                }

                Label {
                    text: JamiStrings.addContactWarning
                    font.pointSize: JamiTheme.textFontSize
                    color: JamiTheme.warningTextColor
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                }
            }
        }
    }
}