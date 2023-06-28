import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import net.jami.Enums 1.1
import net.jami.Models 1.1
import "../../commoncomponents"
import "../js/keyboardshortcuttablecreation.js" as KeyboardShortcutTableCreation

JamiFlickable {
    id: tipsFlow
    property bool isLong: true
    clip: true

    width: getWidth()
    height: getHeight()

    function getWidth() {
        return tipsFlow.isLong ? 630 : 415;
    }
    function getHeight() {
        return flow.height + JamiTheme.preferredMarginSize * 2;
    }

    Flow {
        id: flow
        spacing: 13
        layoutDirection: UtilsAdapter.isRTL ? Qt.RightToLeft : Qt.LeftToRight
        anchors.margins: JamiTheme.preferredMarginSize

        property int maxTipBoxHeight: 0

        Repeater {
            id: tipsRepeater
            model: TipsModel
            Layout.alignment: Qt.AlignCenter

            delegate: TipBox {
                tipId: TipId
                title: Title
                description: Description
                type: Type
                property bool hideTipBox: false

                Component.onCompleted: {
                    flow.maxTipBoxHeight = Math.max(flow.maxTipBoxHeight, height);
                }

                visible: {
                    if (hideTipBox)
                        return false;
                    if (type === "backup") {
                        return LRCInstance.currentAccountType !== Profile.Type.SIP && CurrentAccount.managerUri.length === 0;
                    } else if (type === "customize") {
                        return CurrentAccount.alias.length === 0;
                    }
                    return true;
                }

                onIgnoreClicked: {
                    hideTipBox = true;
                }
            }
        }

//        Component.onCompleted: {
//            for (var i = 0; i < tipsRepeater.count; i++) {
//                var item = tipsRepeater.itemAt(i);
//                item.height = flow.maxTipBoxHeight;
//            }
//        }
    }
}
