/*
 * Copyright (C) 2019-2020 by Savoir-faire Linux
 * Author: Yang Wang   <yang.wang@savoirfairelinux.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.15
import QtQuick.Window 2.14
import QtQuick.Controls 2.14
import QtQuick.Controls.Universal 2.12
import QtQuick.Layouts 1.3
import QtGraphicalEffects 1.14
import QtQuick.Controls.Styles 1.4
import QtQuick.Dialogs 1.3
import Qt.labs.platform 1.1
import net.jami.Models 1.0

import "../../commoncomponents"

Rectangle {
    id: accountViewRect

    enum RegName {
        BLANK,
        INVALIDFORM,
        TAKEN,
        FREE,
        SEARCHING
    }

    property int regNameUi: CurrentAccountSettingsScrollPage.BLANK
    property string registeredName: ""
    property bool registeredIdNeedsSet: false

    property int refreshVariable : 0

    signal navigateToMainView
    signal navigateToNewWizardView
    signal navigateToSidePanelMenu

    function refreshRelevantUI(){
        refreshVariable++
        refreshVariable--
    }


    Connections {
        id: btnRegisterNameClickConnection
        target: btnRegisterName

        enabled: {
            refreshVariable
            switch (regNameUi) {
            case CurrentAccountSettingsScrollPage.FREE:
                return true
            default:
                return false
            }
        }

        function onClicked() {
            slotRegisterName()
        }
    }

    function updateAccountInfoDisplayed() {
        setAvatar()

        accountEnableCheckBox.checked = ClientWrapper.settingsAdaptor.get_CurrentAccountInfo_Enabled()
        displayNameLineEdit.text = ClientWrapper.settingsAdaptor.getCurrentAccount_Profile_Info_Alias()

        var showLocalAccountConfig = (ClientWrapper.settingsAdaptor.getAccountConfig_Manageruri() === "")
        passwdPushButton.visible = showLocalAccountConfig
        btnExportAccount.visible = showLocalAccountConfig
        linkDevPushButton.visible = showLocalAccountConfig

        registeredIdNeedsSet = (ClientWrapper.settingsAdaptor.get_CurrentAccountInfo_RegisteredName() === "")

        if(!registeredIdNeedsSet){
            currentRegisteredID.text = ClientWrapper.settingsAdaptor.get_CurrentAccountInfo_RegisteredName()
        } else {
            currentRegisteredID.text = ""
        }

        textCurrentRingID.text = ClientWrapper.settingsAdaptor.getCurrentAccount_Profile_Info_Uri()

        // update device list view
        updateAndShowDevicesSlot()

        bannedContactsListWidget.visible = false
        bannedContactsLayoutWidget.visible = (bannedListModel.rowCount() > 0)

        if (advanceSettingsView.visible) {
            advanceSettingsView.updateAccountInfoDisplayedAdvance()
        }
        refreshRelevantUI()
    }

    function connectCurrentAccount() {
        accountConnections_ContactModel.enabled = true
        accountConnections_DeviceModel.enabled = true
    }

    function disconnectAccountConnections() {
        accountConnections_ContactModel.enabled = false
        accountConnections_DeviceModel.enabled = false
    }

    function isPhotoBoothOpened() {
        return currentAccountAvatar.takePhotoState
    }

    function setAvatar() {
        currentAccountAvatar.setAvatarPixmap(
                    ClientWrapper.settingsAdaptor.getAvatarImage_Base64(
                        currentAccountAvatar.boothWidht),
                    ClientWrapper.settingsAdaptor.getIsDefaultAvatar())
    }

    function stopBooth() {
        currentAccountAvatar.stopBooth()
    }

    function toggleBannedContacts(){
        var bannedContactsVisible = bannedContactsListWidget.visible
        bannedContactsListWidget.visible = !bannedContactsVisible
        updateAndShowBannedContactsSlot()
    }

    function unban(index){
        ClientWrapper.settingsAdaptor.unbanContact(index)
        updateAndShowBannedContactsSlot()
    }

    Connections {
        id: accountConnections_ContactModel
        target: ClientWrapper.contactModel

        function onModelUpdated(uri, needsSorted) {
            updateAndShowBannedContactsSlot()
        }

        function onContactAdded(contactUri){
            updateAndShowBannedContactsSlot()
        }

        function onContactRemoved(contactUri){
            updateAndShowBannedContactsSlot()
        }
    }

    Connections {
        id: accountConnections_DeviceModel
        target: ClientWrapper.deviceModel

        function onDeviceAdded(id) {
            updateAndShowDevicesSlot()
        }

        function onDeviceRevoked(id, status) {
            updateAndShowDevicesSlot()
        }

        function onDeviceUpdated(id) {
            updateAndShowDevicesSlot()
        }
    }

    // slots
    function verifyRegisteredNameSlot() {
        if (ClientWrapper.settingsAdaptor.get_CurrentAccountInfo_RegisteredName() !== "") {
            regNameUi = CurrentAccountSettingsScrollPage.BLANK
        } else {
            registeredName = ClientWrapper.utilsAdaptor.stringSimplifier(
                        currentRegisteredID.text)
            if (registeredName !== "") {
                if (ClientWrapper.utilsAdaptor.validateRegNameForm(registeredName)) {
                    regNameUi = CurrentAccountSettingsScrollPage.SEARCHING
                    lookUpLabelTimer.restart()
                } else {
                    regNameUi = CurrentAccountSettingsScrollPage.INVALIDFORM
                }
            } else {
                regNameUi = CurrentAccountSettingsScrollPage.BLANK
            }
        }
    }

    Timer {
        id: lookUpLabelTimer

        interval: 300
        onTriggered: {
            beforeNameLookup()
        }
    }

    function beforeNameLookup() {
        ClientWrapper.nameDirectory.lookupName("", registeredName)
    }

    Connections {
        target: ClientWrapper.nameDirectory
        enabled: true

        function onRegisteredNameFound(status, address, name) {
            afterNameLookup(status, name)
        }
    }

    function afterNameLookup(status, regName) {
        if (registeredName === regName && regName.length > 2) {
            switch (status) {
            case NameDirectory.LookupStatus.NOT_FOUND:
                regNameUi = CurrentAccountSettingsScrollPage.FREE
                break
            default:
                regNameUi = CurrentAccountSettingsScrollPage.TAKEN
                break
            }
        } else {
            regNameUi = CurrentAccountSettingsScrollPage.BLANK
        }
    }

    function setAccEnableSlot(state) {
        ClientWrapper.accountModel.setAccountEnabled(ClientWrapper.utilsAdaptor.getCurrAccId(), state)
    }

    /*
     * JamiFileDialog for exporting account
     */
    JamiFileDialog {
        id: exportBtn_Dialog

        mode: JamiFileDialog.SaveFile

        title: qsTr("Export Account Here")
        folder: StandardPaths.writableLocation(StandardPaths.DesktopLocation)

        nameFilters: [qsTr("Jami archive files") + " (*.gz)", qsTr(
                "All files") + " (*)"]

        onAccepted: {
            // is there password? If so, go to password dialog, else, go to following directly
            var exportPath = ClientWrapper.utilsAdaptor.getAbsPath(file.toString())
            if (ClientWrapper.accountAdaptor.hasPassword()) {
                passwordDialog.openDialog(PasswordDialog.ExportAccount,exportPath)
                return
            } else {
                if (exportPath.length > 0) {
                    var isSuccessful = ClientWrapper.accountAdaptor.accoundModel().exportToFile(ClientWrapper.utilsAdaptor.getCurrAccId(), exportPath,"")
                    var title = isSuccessful ? qsTr("Success") : qsTr("Error")
                    var iconMode = isSuccessful ? StandardIcon.Information : StandardIcon.Critical
                    var info = isSuccessful ? qsTr("Export Successful") : qsTr("Export Failed")
                    msgDialog.openWithParameters(title,info, iconMode, StandardButton.Ok)
                }
            }
        }

        onRejected: {}

        onVisibleChanged: {
            if (!visible) {
                rejected()
            }
        }
    }

    function exportAccountSlot() {
        exportBtn_Dialog.open()
    }

    PasswordDialog {
        id: passwordDialog

        onDoneSignal: {
            var success = (code === successCode)
            var title = success ? qsTr("Success") : qsTr("Error")
            var iconMode = success ? StandardIcon.Information : StandardIcon.Critical

            var info
            switch(currentPurpose){
            case PasswordDialog.ExportAccount:
                info = success ? qsTr("Export Successful") : qsTr("Export Failed")
                break
            case PasswordDialog.ChangePassword:
                info = success ? qsTr("Password Changed Successfully") : qsTr("Password Change Failed")
                break
            case PasswordDialog.SetPassword:
                info = success ? qsTr("Password Set Successfully") : qsTr("Password Set Failed")
                passwdPushButton.text = success ? qsTr("Change Password") : qsTr("Set Password")
                break
            }

            msgDialog.openWithParameters(title,info, iconMode, StandardButton.Ok)
        }
    }

    MessageBox {
        id: msgDialog
    }

    function passwordClicked() {
        if (ClientWrapper.accountAdaptor.hasPassword()){
            passwordDialog.openDialog(PasswordDialog.ChangePassword)
        } else {
            passwordDialog.openDialog(PasswordDialog.SetPassword)
        }
    }

    function delAccountSlot() {
        deleteAccountDialog.open()
    }

    DeleteAccountDialog{
        id: deleteAccountDialog

        anchors.centerIn: parent.Center
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2

        onAccepted: {
            ClientWrapper.accountAdaptor.setSelectedAccountId()
            ClientWrapper.accountAdaptor.setSelectedConvId()

            if(ClientWrapper.utilsAdaptor.getAccountListSize() > 0){
                navigateToMainView()
            } else {
                navigateToNewWizardView()
            }
        }
    }

    NameRegistrationDialog{
        id : nameRegistrationDialog

        onAccepted: {
            registeredIdNeedsSet = false
        }
    }

    function slotRegisterName() {
        refreshRelevantUI()
        nameRegistrationDialog.openNameRegistrationDialog(registeredName)
    }

    LinkDeviceDialog{
        id: linkDeviceDialog

        onAccepted: {
            updateAndShowDevicesSlot()
        }
    }

    function showLinkDevSlot() {
        linkDeviceDialog.openLinkDeviceDialog()
    }

    RevokeDevicePasswordDialog{
        id: revokeDevicePasswordDialog

        onRevokeDeviceWithPassword:{
            revokeDeviceWithIDAndPassword(idOfDevice, password)
        }
    }

    MessageBox{
        id: revokeDeviceMessageBox

        property string idOfDev: ""

        title:qsTr("Remove Device")
        text :qsTr("Are you sure you wish to remove this device?")
        icon :StandardIcon.Information
        standardButtons: StandardButton.Ok | StandardButton.Cancel

        onYes: {
            accepted()
        }

        onNo:{
            rejected()
        }

        onDiscard: {
            rejected()
        }

        onAccepted: {
            revokeDeviceWithIDAndPassword(idOfDev,"")
        }

        onRejected: {}
    }

    function removeDeviceSlot(index){
        var idOfDevice = deviceItemListModel.data(deviceItemListModel.index(index,0), DeviceItemListModel.DeviceID)
        if(ClientWrapper.accountAdaptor.hasPassword()){
            revokeDevicePasswordDialog.openRevokeDeviceDialog(idOfDevice)
        } else {
            revokeDeviceMessageBox.idOfDev = idOfDevice
            revokeDeviceMessageBox.open()
        }
    }

    function revokeDeviceWithIDAndPassword(idDevice, password){
        ClientWrapper.deviceModel.revokeDevice(idDevice, password)
        updateAndShowDevicesSlot()
    }

    function updateAndShowBannedContactsSlot() {
        if(bannedListModel.rowCount() <= 0){
            bannedContactsLayoutWidget.visible = false
            return
        }

        bannedListModel.reset()
    }

    function updateAndShowDevicesSlot() {
        if(ClientWrapper.settingsAdaptor.getAccountConfig_Manageruri() === ""){
            linkDevPushButton.visible = true
        }

        deviceItemListModel.reset()
    }

    DeviceItemListModel {
        id: deviceItemListModel
    }

    BannedListModel{
        id: bannedListModel
    }


    anchors.fill: parent

    ColumnLayout {
        anchors.fill: accountViewRect
        //Layout.fillWidth: true
        //Layout.fillHeight: true
        spacing: 0
        //Layout.alignment: Qt.AlignHCenter


        RowLayout {

            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
            Layout.leftMargin: 16
            Layout.fillWidth: true
            Layout.maximumHeight: 64
            Layout.minimumHeight: 64
            Layout.preferredHeight: 64

            HoverableButton {
                id: backToSettingsMenuButton

                Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                Layout.preferredWidth: 30
                Layout.preferredHeight: 30

                radius: 30
                source: "qrc:/images/icons/ic_arrow_back_24px.svg"
                backgroundColor: "white"
                onExitColor: "white"

                visible: mainViewWindow.sidePanelHidden

                onClicked: {
                    navigateToSidePanelMenu()
                }
            }

            Label {

                id: accountPageTitle

                text: qsTr("Jami Account")
                Layout.leftMargin: 16
                font.pointSize: JamiTheme.titleFontSize
                font.kerning: true

                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
            }
        }

        ScrollView {
            id: accountScrollView

            property ScrollBar vScrollBar: ScrollBar.vertical

            //anchors.fill: settingsViewRect
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

            width: settingsViewRect.width
            height: settingsViewRect.height - accountPageTitle.height

            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            ScrollBar.vertical.policy: ScrollBar.AsNeeded

            clip: true

            /*
             * ScrollView Layout
             */
            ColumnLayout {
                id: accountViewLayout

                Layout.fillHeight: true
                Layout.fillWidth: true

                ///width: Math.max(accountScrollView.width, implicitWidth)
                //height: 500
                //Layout.alignment: Qt.A

                spacing: 24

                ToggleSwitch {
                    id: accountEnableCheckBox
                    Layout.topMargin: 16
                    Layout.leftMargin: 16
                    Layout.alignment: Qt.AlignHCenter

                    labelText: qsTr("Enable")
                    fontPointSize: JamiTheme.textFontSize

                    onSwitchToggled: {
                        setAccEnableSlot(checked)
                    }
                }

                /*
                 * Profile
                 */
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.leftMargin: 16
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 8

                    Label {
                        Layout.fillWidth: true

                        Layout.maximumHeight: 32
                        Layout.preferredHeight: 32
                        Layout.minimumHeight: 32

                        text: qsTr("Profile")
                        font.pointSize: JamiTheme.headerFontSize
                        font.kerning: true

                        horizontalAlignment: Text.AlignLeft
                        verticalAlignment: Text.AlignVCenter
                    }

                    PhotoboothView {
                        id: currentAccountAvatar

                        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                        Layout.maximumWidth: 261
                        Layout.preferredWidth: 261
                        Layout.minimumWidth: 261
                        Layout.maximumHeight: 261
                        Layout.preferredHeight: 261
                        Layout.minimumHeight: 261

                        onImageAcquired: {
                            ClientWrapper.settingsAdaptor.setCurrAccAvatar(imgBase64)
                        }

                        onImageCleared: {
                            ClientWrapper.settingsAdaptor.clearCurrentAvatar()
                            setAvatar()
                        }
                    }

                    InfoLineEdit {
                        id: displayNameLineEdit

                        //fieldLayoutWidth: 261

                        //Layout.leftMargin: 20
                        Layout.alignment: Qt.AlignHCenter

                        font.pointSize: JamiTheme.textFontSize
                        font.kerning: true

                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter

                        onEditingFinished: {
                            ClientWrapper.accountAdaptor.setCurrAccDisplayName(
                                        displayNameLineEdit.text)
                        }
                    }
                }

                /*
                 * Identity
                 */
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    Layout.leftMargin: 16
                    spacing: 8

                    Label {
                        Layout.fillWidth: true

                        Layout.maximumHeight: 32
                        Layout.preferredHeight: 32
                        Layout.minimumHeight: 32

                        text: qsTr("Identity")
                        font.pointSize: JamiTheme.headerFontSize
                        font.kerning: true

                        horizontalAlignment: Text.AlignLeft
                        verticalAlignment: Text.AlignVCenter
                    }

                    RowLayout {
                        spacing: 8
                        Layout.fillWidth: true
                        Layout.maximumHeight: 32

                        Label {
                            Layout.fillWidth: true
                            Layout.minimumHeight: 32
                            Layout.preferredHeight: 32
                            Layout.maximumHeight: 32

                            text: qsTr("Id")
                            font.pointSize: JamiTheme.textFontSize
                            font.kerning: true

                            horizontalAlignment: Text.AlignLeft
                            verticalAlignment: Text.AlignVCenter
                        }

                        TextField {
                            id: currentRingID

                            property var backgroundColor: "transparent"
                            property var borderColor: "transparent"

                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            font.pointSize: JamiTheme.textFontSize
                            font.kerning: true
                            font.bold: true

                            readOnly: true
                            selectByMouse: true

                            text: { textCurrentRingID.elidedText }

                            horizontalAlignment: Text.AlignLeft
                            verticalAlignment: Text.AlignVCenter

                            background: Rectangle {
                                anchors.fill: parent
                                radius: 0
                                border.color: currentRingID.borderColor
                                border.width: 0
                                color: currentRingID.backgroundColor
                            }

                            TextMetrics {
                                id: textCurrentRingID

                                elide: Text.ElideRight
                                elideWidth: accountViewRect.width - 32

                                text: { refreshVariable
                                    return ClientWrapper.settingsAdaptor.getCurrentAccount_Profile_Info_Uri()
                                }
                            }
                        }
                    }


                    RowLayout {
                        spacing: 8
                        Layout.fillWidth: true
                        Layout.minimumHeight: 32
                        Layout.preferredHeight: 32
                        Layout.maximumHeight: 32
                        layoutDirection: Qt.LeftToRight

                        Label {
                            id: lblRegisteredName

                            Layout.minimumWidth: 100
                            Layout.preferredWidth: 100
                            Layout.maximumWidth: 100

                            text: qsTr("Registered name")

                            font.pointSize: JamiTheme.textFontSize
                            font.kerning: true

                            horizontalAlignment: Text.AlignLeft
                            verticalAlignment: Text.AlignVCenter
                        }

                        RowLayout {
                            spacing: 8
                            Layout.fillWidth: true
                            Layout.maximumHeight: 32
                            Layout.alignment: Qt.AlignVCenter

                            TextField {
                                id: currentRegisteredID

                                Layout.fillWidth: true
                                //Layout.maximumWidth: 100
                                //Layout.preferredWidth: 100
                                //Layout.minimumWidth: 100

                                Layout.minimumHeight: 32
                                Layout.preferredHeight: 32
                                Layout.maximumHeight: 32

                                placeholderText: { refreshVariable
                                                   var result = registeredIdNeedsSet ? qsTr("Type here to register a username") : ""
                                                   return result}

                                text: {
                                    refreshVariable
                                    if (!registeredIdNeedsSet){
                                        return ClientWrapper.settingsAdaptor.get_CurrentAccountInfo_RegisteredName()
                                    } else {
                                        return ""
                                    }
                                }
                                selectByMouse: true
                                readOnly: { refreshVariable
                                            return !registeredIdNeedsSet}

                                font.pointSize: 10
                                font.kerning: true
                                font.bold: { refreshVariable
                                    return !registeredIdNeedsSet}

                                horizontalAlignment: Text.AlignLeft
                                verticalAlignment: Text.AlignVCenter

                                background: Rectangle {
                                    anchors.fill: parent
                                    radius: {refreshVariable
                                             var result = registeredIdNeedsSet ? height / 2 : 0
                                             return result}
                                    border.color: "transparent"
                                    border.width: {refreshVariable
                                                   var result = registeredIdNeedsSet ? 2 : 0
                                                   return result}
                                    color: {refreshVariable
                                            var result = registeredIdNeedsSet ? Qt.rgba(
                                                                      240 / 256, 240 / 256,
                                                                      240 / 256,
                                                                      1.0) : "transparent"
                                            return result}
                                }

                                onTextEdited: {
                                    verifyRegisteredNameSlot()
                                }

                                onEditingFinished: {
                                    verifyRegisteredNameSlot()
                                }
                            }

                            LookupStatusLabel {
                                id: lookupStatusLabel

                                visible:{refreshVariable
                                         var result = registeredIdNeedsSet
                                         && (regNameUi
                                             !== CurrentAccountSettingsScrollPage.BLANK)
                                            return result}

                                MouseArea {
                                    id: lookupStatusLabelArea
                                    anchors.fill: parent
                                    property bool isHovering: false

                                    onEntered: isHovering = true
                                    onExited: isHovering = false

                                    hoverEnabled: true
                                }

                                ToolTip.visible: lookupStatusLabelArea.isHovering
                                ToolTip.text: {
                                    switch (regNameUi) {
                                    case CurrentAccountSettingsScrollPage.BLANK:
                                        return qsTr("")
                                    case CurrentAccountSettingsScrollPage.INVALIDFORM:
                                        return qsTr("A registered name should not have any spaces and must be at least three letters long")
                                    case CurrentAccountSettingsScrollPage.TAKEN:
                                        return qsTr("This name is already taken")
                                    case CurrentAccountSettingsScrollPage.FREE:
                                        return qsTr("Register this name")
                                    case CurrentAccountSettingsScrollPage.SEARCHING:
                                        return qsTr("")
                                    default:
                                        return qsTr("")
                                    }
                                }

                                lookupStatusState: {
                                    switch (regNameUi) {
                                    case CurrentAccountSettingsScrollPage.BLANK:
                                        return "Blank"
                                    case CurrentAccountSettingsScrollPage.INVALIDFORM:
                                        return "Invalid"
                                    case CurrentAccountSettingsScrollPage.TAKEN:
                                        return "Taken"
                                    case CurrentAccountSettingsScrollPage.FREE:
                                        return "Free"
                                    case CurrentAccountSettingsScrollPage.SEARCHING:
                                        return "Searching"
                                    default:
                                        return "Blank"
                                    }
                                }
                            }

                            HoverableRadiusButton {
                                id: btnRegisterName

                                visible: {refreshVariable
                                            var result = registeredIdNeedsSet
                                         && (regNameUi
                                             === CurrentAccountSettingsScrollPage.FREE)
                                            return result}

                                Layout.maximumWidth: 80
                                Layout.preferredWidth: 80
                                Layout.minimumWidth: 80

                                Layout.minimumHeight: 30
                                Layout.preferredHeight: 30
                                Layout.maximumHeight: 30

                                text: qsTr("Register")
                                font.pointSize: 10
                                font.kerning: true

                                radius: height / 2
                            }

                            Item {
                                Layout.fillHeight: true
                                Layout.fillWidth: true
                            }
                        }
                    }
                }


                /*
                 * Buttons Pwd, Export, Delete
                 */
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter

                    spacing: 8

                    HoverableButtonTextItem {
                        id: passwdPushButton

                        visible: ClientWrapper.settingsAdaptor.getAccountConfig_Manageruri() === ""

                        Layout.alignment: Qt.AlignHCenter
                        Layout.minimumWidth: 160
                        Layout.preferredWidth: accountViewRect.width * 0.7
                        Layout.maximumWidth: 400

                        Layout.minimumHeight: 32
                        Layout.preferredHeight: 32
                        Layout.maximumHeight: 32

                        text: ClientWrapper.accountAdaptor.hasPassword() ? qsTr("Change Password") : qsTr("Set Password")

                        font.pointSize: JamiTheme.textFontSize
                        font.kerning: true

                        radius: height / 2

                        onClicked: {
                            passwordClicked()
                        }
                    }

                    HoverableButtonTextItem {
                        id: btnExportAccount

                        visible: ClientWrapper.settingsAdaptor.getAccountConfig_Manageruri() === ""

                        Layout.alignment: Qt.AlignHCenter
                        Layout.minimumWidth: 160
                        Layout.preferredWidth: accountViewRect.width * 0.7
                        Layout.maximumWidth: 400

                        Layout.minimumHeight: 32
                        Layout.preferredHeight: 32
                        Layout.maximumHeight: 32

                        text: qsTr("Export Account")
                        font.pointSize: JamiTheme.textFontSize
                        font.kerning: true

                        radius: height / 2

                        onClicked: {
                            exportAccountSlot()
                        }
                    }

                    HoverableButtonTextItem {
                        id: btnDeletAccount

                        backgroundColor: "red"
                        onEnterColor: Qt.rgba(150 / 256, 0, 0, 0.7)
                        onDisabledBackgroundColor: Qt.rgba(
                                                       255 / 256,
                                                       0, 0, 0.8)
                        onPressColor: backgroundColor
                        textColor: "white"

                        Layout.alignment: Qt.AlignHCenter
                        Layout.minimumWidth: 160
                        Layout.preferredWidth: accountViewRect.width * 0.7
                        Layout.maximumWidth: 400

                        Layout.minimumHeight: 32
                        Layout.preferredHeight: 32
                        Layout.maximumHeight: 32

                        text: qsTr("Delete Account")
                        font.pointSize: JamiTheme.textFontSize
                        font.kerning: true

                        radius: height / 2

                        onClicked: {
                            delAccountSlot()
                        }
                    }
                }

                /*
                 Linked devices
                 */
                ColumnLayout {

                    Layout.fillWidth: true
                    Layout.leftMargin: 16

                    Label {
                        Layout.fillWidth: true

                        Layout.maximumHeight: 32
                        Layout.preferredHeight: 32
                        Layout.minimumHeight: 32

                        text: qsTr("Linked Devices")
                        font.pointSize: JamiTheme.headerFontSize
                        font.kerning: true

                        horizontalAlignment: Text.AlignLeft
                        verticalAlignment: Text.AlignVCenter
                    }


                    ListViewJami {
                        id: settingsListView

                        Layout.fillWidth: true

                        //Layout.minimumWidth: 200
                        //Layout.preferredWidth: 200
                        //Layout.maximumWidth: 200

                        Layout.minimumHeight: 160
                        Layout.preferredHeight: 160
                        Layout.maximumHeight: 160

                        model: deviceItemListModel

                        delegate: DeviceItemDelegate{
                            id: settingsListDelegate

                            width: settingsListView.width
                            height: 72

                            deviceName : DeviceName
                            deviceId: DeviceID
                            isCurrent: IsCurrent

                            onClicked: {
                                settingsListView.currentIndex = index
                            }

                            onBtnRemoveDeviceClicked:{
                                removeDeviceSlot(index)
                            }
                        }
                    }

                    HoverableRadiusButton {
                        id: linkDevPushButton

                        visible: ClientWrapper.settingsAdaptor.getAccountConfig_Manageruri() === ""

                        //Layout.leftMargin: 20

                        Layout.fillWidth: true

                        Layout.maximumHeight: 32
                        Layout.preferredHeight: 32
                        Layout.minimumHeight: 32

                        radius: height / 2

                        text: qsTr("+Link Another Device")
                        font.pointSize: 10
                        font.kerning: true

                        onClicked: {
                            showLinkDevSlot()
                        }
                    }
                }

                /*
                 * Banned contacts
                 */
                ColumnLayout {
                    id: bannedContactsLayoutWidget

                    Layout.fillWidth: true
                    Layout.leftMargin: 16

                    spacing: 8

                    RowLayout {

                        Layout.fillWidth: true
                        Layout.maximumHeight: 32
                        Layout.preferredHeight: 32
                        Layout.minimumHeight: 32

                        Label {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            text: qsTr("Banned Contacts")
                            font.pointSize: JamiTheme.headerFontSize
                            font.kerning: true

                            horizontalAlignment: Text.AlignLeft
                            verticalAlignment: Text.AlignVCenter
                        }

                        HoverableRadiusButton {
                            id: bannedContactsBtn

                            Layout.maximumWidth: 32
                            Layout.preferredWidth: 32
                            Layout.minimumWidth: 32

                            Layout.minimumHeight: 32
                            Layout.preferredHeight: 32
                            Layout.maximumHeight: 32

                            buttonImageHeight: height
                            buttonImageWidth: height

                            radius: height / 2

                            icon.source: bannedContactsListWidget.visible? "qrc:/images/icons/round-arrow_drop_up-24px.svg" : "qrc:/images/icons/round-arrow_drop_down-24px.svg"
                            icon.height: 32
                            icon.width: 32

                            onClicked: {
                                toggleBannedContacts()
                            }
                        }
                    }

                    ColumnLayout {
                        id: bannedContactsListWidget

                        spacing: 8

                        ListViewJami {
                            id: bannedListWidget

                            Layout.fillWidth: true

                            Layout.minimumHeight: 150
                            Layout.preferredHeight: 150
                            Layout.maximumHeight: 150

                            model: bannedListModel

                            delegate: BannedItemDelegate{
                                id: bannedListDelegate

                                width: bannedListWidget.width
                                height: 74

                                contactName : ContactName
                                contactID: ContactID
                                contactPicture_base64: ContactPicture

                                onClicked: {
                                    bannedListWidget.currentIndex = index
                                }

                                onBtnReAddContactClicked: {
                                    unban(index)
                                }
                            }
                        }
                    }
                }

                /*
                 * Advanced Settigs Button
                 */
                HoverableRadiusButton {
                    id: advancedAccountSettingsPButton

                    //Layout.minimumWidth: 180

                    Layout.leftMargin: 16
                    Layout.minimumHeight: 30
                    Layout.preferredHeight: 30
                    Layout.maximumHeight: 30

                    radius: height / 2

                    text: qsTr("Advanced Account Settings")
                    font.pointSize: 10
                    font.kerning: true

                    icon.source: {
                        if (advanceSettingsView.visible) {
                            return "qrc:/images/icons/round-arrow_drop_up-24px.svg"
                        } else {
                            return "qrc:/images/icons/round-arrow_drop_down-24px.svg"
                        }
                    }

                    icon.height: 24
                    icon.width: 24

                    onClicked: {
                        advanceSettingsView.visible = !advanceSettingsView.visible
                        if (advanceSettingsView.visible) {
                            advanceSettingsView.updateAccountInfoDisplayedAdvance()
                            accountScrollView.vScrollBar.position = advancedAccountSettingsPButton.y / accountViewLayout.height
                        } else {
                            accountScrollView.vScrollBar.position = 0
                        }
                    }
                }

                /*
                 * Advanced Settings
                 */
                AdvancedSettingsView {
                    id: advanceSettingsView
                    Layout.leftMargin: 16
                    visible: false
                }

                /*
                 * To keep max width
                 */
                Rectangle {
                    color: "transparent"
                    Layout.minimumWidth: accountViewRect.width-32
                    Layout.preferredWidth: accountViewRect.width-32
                    Layout.maximumWidth: accountViewRect.width-32
                    Layout.fillHeight: true
                }
            }
        }
    }
}
