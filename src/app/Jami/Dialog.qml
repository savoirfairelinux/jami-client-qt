import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Controls.Universal as UniversalStyle
import QtQuick.Effects
import QtQuick.Layouts
import QtQuick.Templates as T
import net.jami.Constants 1.1
import "../commoncomponents" as Common

T.Dialog {
    id: root

    property bool closeButtonVisible: true
    property real dialogPadding: 12

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding,
                            implicitHeaderWidth, implicitFooterWidth)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding
                             + (implicitHeaderHeight > 0 ? implicitHeaderHeight + spacing : 0)
                             + (implicitFooterHeight > 0 ? implicitFooterHeight + spacing : 0))

    padding: 30
    palette.window: JamiTheme.globalIslandColor
    palette.windowText: JamiTheme.textColor
    palette.text: JamiTheme.textColor
    UniversalStyle.Universal.theme: JamiTheme.darkTheme ? UniversalStyle.Universal.Dark : UniversalStyle.Universal.Light

    header: RowLayout {
        Controls.Label {
            objectName: "dialogTitle"
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignCenter
            Layout.leftMargin: root.dialogPadding
            Layout.topMargin: root.dialogPadding
            text: root.title
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            color: JamiTheme.textColor
            font.bold: true
            font.pointSize: JamiTheme.menuFontSize
            wrapMode: Text.Wrap
            visible: text.length > 0
        }

        Common.NewIconButton {
            id: closeButton
            objectName: "dialogCloseButton"
            Common.QWKSetParentHitTestVisible {}
            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
            Layout.rightMargin: root.dialogPadding
            Layout.topMargin: root.dialogPadding
            iconSize: JamiTheme.iconButtonMedium
            iconSource: JamiResources.round_close_24dp_svg
            toolTipText: JamiStrings.close
            visible: root.closeButtonVisible
            onClicked: root.close()
        }
    }

    footer: Controls.DialogButtonBox {
        visible: count > 0
        spacing: 8
        padding: root.dialogPadding
        topPadding: 0
        background: null
        delegate: Controls.Button {
            flat: true
        }
    }

    background: Rectangle {
        topLeftRadius: closeButton.background.radius + root.dialogPadding
        topRightRadius: closeButton.background.radius + root.dialogPadding
        bottomRightRadius: JamiTheme.newMaterialButtonHeight / 2 + root.dialogPadding
        bottomLeftRadius: JamiTheme.newMaterialButtonHeight / 2 + root.dialogPadding
        color: JamiTheme.globalIslandColor
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowBlur: JamiTheme.shadowBlur
            shadowColor: JamiTheme.shadowColor
            shadowHorizontalOffset: 3.0
            shadowVerticalOffset: 3.0
        }
    }

    T.Overlay.modal: Rectangle {
        color: JamiTheme.transparentColor
        ColorAnimation on color {
            to: JamiTheme.popupOverlayColor
            duration: 500
        }
    }

}