import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ItemDelegate {
    id: root
    property string id: ""
    property string title: ""
    property string icon: ""
    property string background: ""
    property string description: ""
    property string author: ""

    ColumnLayout {
        Layout.preferredWidth: 50
        RowLayout {
        RowLayout{
            Layout.alignment: Qt.AlignRight
            MaterialButton {
                id: install
                TextMetrics {
                    id: installTextSize
                    font.weight: Font.Bold
                    font.pixelSize: JamiTheme.wizardViewButtonFontPixelSize
                    font.capitalization: Font.AllUppercase
                    text: JamiStrings.install
                }
                secondary: true
                preferredWidth: updateTextSize.width
                text: JamiStrings.install
                fontSize: 15
            }
        }
        RowLayout {
            Layout.fillWidth: true
            preferredHeight: 30
            Label {
                id: pluginImage
                Layout.leftMargin: 8
                Layout.topMargin: 8
                Layout.alignment: Qt.AlignLeft | Qt.AlingVCenter
                width: JamiTheme.preferredFieldHeight
                Layout.fillHeight: true

                background: Rectangle {
                    color: "transparent"
                    Image {
                        anchors.centerIn: parent
                        source: "file:" + icon // TODO: should check the file path
                        sourceSize: Qt.size(256, 256)
                        mipmap: true
                        width: JamiTheme.preferredFieldHeight
                        height: JamiTheme.preferredFieldHeight
                    }
                }
            }

            Label {
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.topMargin: 8
                Layout.leftMargin: 8
                color: JamiTheme.textColor

                font.pointSize: JamiTheme.settingsFontSize
                font.kerning: true
                text: pluginName === "" ? pluginId : pluginName
                verticalAlignment: Text.AlignVCenter
            }
        }
      }
        RowLayout {
            RowLayout {
                Label {
                    id: descriptionLabel
                    anchors.bottomMargin: JamiTheme.preferredMarginSize * 2
                    font.pixelSize: JamiTheme.headerFontSize
                    wrapMode: Text.WordWrap
                    text: description
                    color: JamiTheme.textColor
                }
            }
            RowLayout {
                Label {
                    Layout.fillWidth: true
                    Layout.topMargin: 8
                    Layout.leftMargin: 8
                    color: JamiTheme.textColor

                    font.pointSize: JamiTheme.settingsFontSize
                    font.kerning: true
                    text: "By " + author
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }
}
