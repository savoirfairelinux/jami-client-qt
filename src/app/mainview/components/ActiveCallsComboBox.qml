import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import net.jami.Helpers 1.1
import "../../commoncomponents"

ComboBox {
    id: root

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding,
                             implicitIndicatorHeight + topPadding + bottomPadding)


    //Component.onCompleted: console.warn("IVE BEEN MADE")

    padding: animation.spinningAnimationWidth + 4

    // List of objects: { accountId, convId, callId, status, statusStr, title, isSip, convAvatarSource, accountAvatarSource }
    // property var allActiveCalls: [
    //     // Jami account — IN_PROGRESS (Talking)
    //     { accountId: "acc_jami_1", convId: "conv1", callId: "call1", status: Call.Status.IN_PROGRESS,       statusStr: "Talking",                    title: "Alice",   isSip: false, convAvatarSource: "", accountAvatarSource: "" },
    //     // Jami account — PAUSED (Hold)
    //     { accountId: "acc_jami_1", convId: "conv2", callId: "call2", status: Call.Status.PAUSED,            statusStr: "Hold",                       title: "Bob",     isSip: false, convAvatarSource: "", accountAvatarSource: "" },
    //     // Jami account — INCOMING_RINGING
    //     { accountId: "acc_jami_2", convId: "conv3", callId: "call3", status: Call.Status.INCOMING_RINGING,  statusStr: "Incoming",                   title: "Charlie", isSip: false, convAvatarSource: "", accountAvatarSource: "" },
    //     // Jami account — OUTGOING_RINGING
    //     { accountId: "acc_jami_2", convId: "conv4", callId: "call4", status: Call.Status.OUTGOING_RINGING,  statusStr: "Calling",                    title: "Diana",   isSip: false, convAvatarSource: "", accountAvatarSource: "" },
    //     // Jami account — CONNECTING
    //     { accountId: "acc_jami_2", convId: "conv5", callId: "call5", status: Call.Status.CONNECTING,        statusStr: "Connecting",                 title: "Eve",     isSip: false, convAvatarSource: "", accountAvatarSource: "" },
    //     // Jami account — SEARCHING
    //     { accountId: "acc_jami_2", convId: "conv6", callId: "call6", status: Call.Status.SEARCHING,         statusStr: "Searching",                  title: "Frank",   isSip: false, convAvatarSource: "", accountAvatarSource: "" },
    //     // SIP account — IN_PROGRESS
    //     { accountId: "acc_sip_1",  convId: "conv7", callId: "call7", status: Call.Status.IN_PROGRESS,       statusStr: "Talking",                    title: "+1 555 0100", isSip: true,  convAvatarSource: "", accountAvatarSource: "" },
    //     // SIP account — PAUSED
    //     { accountId: "acc_sip_1",  convId: "conv8", callId: "call8", status: Call.Status.PAUSED,            statusStr: "Hold",                       title: "+1 555 0101", isSip: true,  convAvatarSource: "", accountAvatarSource: "" },
    //     // SIP account — INCOMING_RINGING
    //     { accountId: "acc_sip_2",  convId: "conv9", callId: "call9", status: Call.Status.INCOMING_RINGING,  statusStr: "Incoming",                   title: "+1 555 0102", isSip: true,  convAvatarSource: "", accountAvatarSource: "" },
    //     // SIP account — PEER_BUSY
    //     { accountId: "acc_sip_2",  convId: "convA", callId: "callA", status: Call.Status.PEER_BUSY,         statusStr: "Peer busy",                  title: "+1 555 0103", isSip: true,  convAvatarSource: "", accountAvatarSource: "" },
    //     // SIP account — CONNECTED
    //     { accountId: "acc_sip_2",  convId: "convB", callId: "callB", status: Call.Status.CONNECTED,         statusStr: "Communication established",  title: "+1 555 0104", isSip: true,  convAvatarSource: "", accountAvatarSource: "" },
    // ]

    property var allActiveCalls: []

    function refreshAllActiveCalls() {
        // Preserve snapshotted avatar URLs and titles for calls already in the list.
        // Avatar image provider resolves conversations against the *current* account,
        // so re-snapping after an account switch would produce a blank image.
        var preserved = ({})
        for (var k = 0; k < allActiveCalls.length; k++) {
            var entry = allActiveCalls[k]
            preserved[entry.callId] = {
                title:               entry.title,
                convAvatarSource:    entry.convAvatarSource,
                accountAvatarSource: entry.accountAvatarSource
            }
        }

        var calls = []
        var count = UtilsAdapter.getAccountListSize()
        for (var i = 0; i < count; i++) {
            var accountId = AccountListModel.data(AccountListModel.index(i, 0), AccountList.Role.ID)
            var accountType = AccountListModel.data(AccountListModel.index(i, 0), AccountList.Role.Type)
            if (!accountId || !UtilsAdapter.hasCall(accountId))
                continue
            var convIds = UtilsAdapter.getCallConvsForAccount(accountId)
            for (var j = 0; j < convIds.length; j++) {
                var convId = convIds[j]
                var callId = UtilsAdapter.getCallId(accountId, convId)
                if (!callId)
                    continue
                var status = UtilsAdapter.getCallStatus(callId, accountId)
                var prev = preserved[callId]
                var title            = prev ? prev.title            : UtilsAdapter.getBestName(accountId, convId)
                var convAvatarSource = prev ? prev.convAvatarSource : 'image://avatarimage/conversation_' + convId + '_' + AvatarRegistry.getUid(convId)
                var accountAvatarSource = prev ? prev.accountAvatarSource : 'image://avatarimage/account_' + accountId + '_' + AvatarRegistry.getUid(accountId)
                calls.push({
                               accountId: accountId,
                               convId: convId,
                               callId: callId,
                               status: status,
                               statusStr: UtilsAdapter.getCallStatusStr(status),
                               title: title,
                               isSip: accountType === Profile.Type.SIP,
                               convAvatarSource: convAvatarSource,
                               accountAvatarSource: accountAvatarSource
                           })
            }
        }
        allActiveCalls = calls
    }

    Connections {
        target: CallAdapter
        function onCallStatusChanged(status, accountId, convUid) {
            refreshAllActiveCalls()
        }
    }

    Connections {
        target: LRCInstance
        function onCurrentAccountIdChanged() {
            refreshAllActiveCalls()
        }
    }

    Component.onCompleted: refreshAllActiveCalls()

    visible: allActiveCalls.length > 0

    model: allActiveCalls

    delegate: ItemDelegate {
        id: delegate

        required property var model
        required property int index

        property string durationText: CallAdapter.getCallDurationTime(delegate.model[root.textRole].accountId,
                                                                      delegate.model[root.textRole].convId)

        Timer {
            interval: 1000
            running: true
            repeat: true
            onTriggered: delegate.durationText = CallAdapter.getCallDurationTime(delegate.model[root.textRole].accountId,
                                                                                 delegate.model[root.textRole].convId)
        }

        width: ListView.view.width
        height: root.background.height

        topPadding: 2
        bottomPadding: 2
        leftPadding: background.radius / 2
        rightPadding: background.radius - (contactAvatar.width / 2)

        contentItem: RowLayout {
            spacing: 10

            Avatar {
                id: avatar

                Layout.alignment: Qt.AlignVCenter

                visible: false

                width: 36
                height: 36

                imageId: delegate.model[root.textRole].accountId
                mode: Avatar.Mode.Account
                showPresenceIndicator: false
            }

            Button {
                Layout.alignment: Qt.AlignVCenter

                enabled: false

                icon.width: JamiTheme.iconButtonMedium
                icon.height: JamiTheme.iconButtonMedium
                icon.color: JamiTheme.textColor
                icon.source: {
                    switch(delegate.model[root.textRole].status) {
                    case Call.Status.PAUSED:
                        return JamiResources.phone_paused_24dp_svg;
                    case Call.Status.INCOMING_RINGING:
                        return JamiResources.incoming_call_svg;
                    case Call.Status.OUTGOING_RINGING:
                        return JamiResources.outgoing_call_svg;
                    case Call.Status.IN_PROGRESS:
                    default:
                        return JamiResources.start_audiocall_24dp_svg;
                    }
                }

                background: null
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 2

                RowLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter

                    spacing: 0

                    Text {
                        Layout.fillWidth: false
                        text: "Call with "
                        color: JamiTheme.textColor
                        font.pixelSize: JamiTheme.headerFontSize
                        font.bold: true
                        elide: Text.ElideRight
                    }

                    Button {
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft

                        padding: 0
                        rightPadding: 2

                        icon.source: delegate.model[root.textRole].isSip ? JamiResources.sip_24dp_svg : JamiResources.jami_id_new_svg
                        icon.width: 20
                        icon.height: 20
                        icon.color: delegate.model[root.textRole].isSip ? JamiTheme.textColor : JamiTheme.tintedBlue

                        background: null
                    }

                    Text {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft

                        text: delegate.model[root.textRole].title
                        color: JamiTheme.textColor
                        horizontalAlignment: Text.AlignLeft
                        font.pixelSize: JamiTheme.headerFontSize
                        font.bold: true
                        elide: Text.ElideRight
                    }
                }
                Text {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft

                    text: delegate.model[root.textRole].statusStr
                          + (delegate.durationText ? " · " + delegate.durationText : "")
                    color: JamiTheme.textColor
                    font.pixelSize: JamiTheme.menuFontSize
                    elide: Text.ElideRight
                }
            }

            Image {
                id: contactAvatar

                Layout.alignment: Qt.AlignVCenter

                width: 36
                height: 36

                sourceSize.width: Math.max(24, width)
                sourceSize.height: Math.max(24, height)

                source: delegate.model[root.textRole].convAvatarSource
                fillMode: Image.PreserveAspectFit
                smooth: true
                antialiasing: true
            }
        }

        background: Rectangle {
            radius: height / 2
            color: hovered || highlighted ? JamiTheme.smartListHoveredColor : JamiTheme.globalIslandColor

            Behavior on color {
                ColorAnimation {
                    duration: JamiTheme.shortFadeDuration
                }
            }
        }

        highlighted: root.highlightedIndex === index
    }

    indicator: Button {
        anchors.verticalCenter: root.verticalCenter
        anchors.right: root.right

        icon.source: JamiResources.expand_less_24dp_svg
        icon.width: JamiTheme.iconButtonMedium
        icon.height: JamiTheme.iconButtonMedium
        icon.color: JamiTheme.textColor

        background: null

        transform: Rotation {
            id: rotation
            origin.x: indicator.width / 2
            origin.y: indicator.height / 2
            angle: popup.visible ? 0 : 180

            Behavior on angle {
                NumberAnimation {
                    duration: JamiTheme.shortFadeDuration
                    easing.type: Easing.InOutQuad
                }
            }
        }
    }

    contentItem: RowLayout {
        Button {
            Layout.alignment: Qt.AlignVCenter

            // We want just the icon and not the features of a button
            enabled: false

            icon.source: JamiResources.start_audiocall_24dp_svg
            icon.width: JamiTheme.iconButtonMedium
            icon.height: JamiTheme.iconButtonMedium
            icon.color: JamiTheme.textColor

            background: null
        }

        Text {
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: true

            text: "Active calls"
            color: JamiTheme.textColor
            elide: Text.ElideRight
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }

    popup: Popup {
        width: root.width
        height: Math.min(contentItem.implicitHeight + topPadding + bottomPadding, root.Window.height - topMargin - bottomMargin)

        y: -root.implicitBackgroundHeight + 50

        padding: 12
        spacing: 4

        contentItem: ListView {
            implicitHeight: contentHeight
            spacing: 4

            clip: true

            model: root.popup.visible ? root.delegateModel : null
            currentIndex: root.highlightedIndex
        }

        background: Rectangle {
            color: JamiTheme.globalIslandColor
            border.color: JamiTheme.buttonCallLightGreen
            border.width: 2
            radius: (root.background.height / 2) + popup.padding
        }
    }

    background: Rectangle {
        color: JamiTheme.darkTheme ? JamiTheme.buttonCallDarkGreen : JamiTheme.buttonCallLightGreen
        radius: height / 2

        SpinningAnimation {
            id: animation
            anchors.fill: parent
            mode: SpinningAnimation.Mode.Radial
            color: !JamiTheme.darkTheme ? JamiTheme.buttonCallDarkGreen : JamiTheme.buttonCallLightGreen
            spinningAnimationWidth: 4
            spinningAnimationDuration: 1500
        }
    }
}
