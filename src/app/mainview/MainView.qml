/*
 * Copyright (C) 2020-2026 Savoir-faire Linux Inc.
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
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import net.jami.Enums 1.1
import net.jami.Models 1.1

// Import qml component files.
import "components"
import "../"
import "../wizardview"
import "../settingsview"
import "../settingsview/components"

import "js/keyboardshortcuttablecreation.js" as KeyboardShortcutTableCreation

Item {
    id: mainView
    objectName: "mainView"

    property string currentConvId: CurrentConversation.id
    onCurrentConvIdChanged: {
        if (currentConvId !== '') {
            viewCoordinator.present("ConversationView")
        } else {
            viewCoordinator.present("WelcomePage")
        }
    }

    property color currentConversationColor: CurrentConversation.color
    property color tintColor: Qt.rgba(currentConversationColor.r, currentConversationColor.g, currentConversationColor.b, JamiTheme.chatViewBackgroundTintOpacity)
    property real tintOpacity: currentConvId === "" ? 0.0 : 1.0
    property color baseColor: Qt.tint(JamiTheme.globalBackgroundColor, tintColor)

    // WelcomePage background properties
    property variant uiCustomization: CurrentAccount.uiCustomization
    onUiCustomizationChanged: updateWelcomeBackgroundFlags()
    property bool hasCustomUi: false
    property bool hasCustomBgImage: false
    property string customBgUrl: ""
    property bool hasCustomBgColor: false
    property string customBgColor: ""

    onWidthChanged: Qt.callLater(JamiQmlUtils.updateMessageBarButtonsPoints)
    onHeightChanged: Qt.callLater(JamiQmlUtils.updateMessageBarButtonsPoints)

    Connections {
        target: CurrentAccount
        function onIdChanged() {
            updateWelcomeBackgroundFlags();
        }
    }

    Connections {
        target: JamiTheme
        function onDarkThemeChanged() {
            customBgUrl = hasCustomBgImage ? customBgUrl : JamiTheme.welcomeBg;
        }
    }

    function updateWelcomeBackgroundFlags() {
        hasCustomUi = Object.keys(uiCustomization).length > 0;
        hasCustomBgImage = (hasCustomUi && uiCustomization.backgroundType === "image");
        customBgUrl = hasCustomBgImage ? (CurrentAccount.managerUri + uiCustomization.backgroundColorOrUrl) : "";
        hasCustomBgColor = (hasCustomUi && uiCustomization.backgroundType === "color");
        customBgColor = hasCustomBgColor ? uiCustomization.backgroundColorOrUrl : "";
    }

    Component.onCompleted: {
        JamiQmlUtils.mainViewRectObj = mainView;
        updateWelcomeBackgroundFlags();
    }

    // JAMS-specific background colour
    Rectangle {
        id: welcomeBgRect
        anchors.fill: parent
        color: hasCustomBgColor ? customBgColor : "transparent"
        visible: hasCustomBgColor
        z: -1
    }

    // MainView's background colour
    // When NOT in a conversation, this will be transparent (i.e. the welcome page image)
    // When IN a conversation, this will be the conversation's assigned colour
    Rectangle {
        anchors.fill: parent
        color: baseColor
        opacity: tintOpacity

        // Will cause a fade between background colours when switching conversations
        Behavior on color {
            ColorAnimation {
                duration: JamiTheme.conversationColorFadeDuration
                easing.type: Easing.InOutQuad
            }
        }
    }


    // Will cause fade-in/out effect when transitioning between the welcome page and a conversation
    Behavior on tintOpacity {
        NumberAnimation {
            duration: JamiTheme.shortFadeDuration
            easing.type: Easing.InOutQuad
        }
    }

    // The global background image that can be seen when NOT in a conversation
    // Three cases (based on priority):
    // 1. The background image set by the user in the Appearance settings
    // 2. The background set by a JAMS administrator (if applicable)
    // 3. The default light/dark mode background
    CachedImage {
        id: welcomeCachedImgLogo
        downloadUrl: (AccountSettingsManager.accountSettingsPropertyMap.backgroundUri === undefined || AccountSettingsManager.accountSettingsPropertyMap.backgroundUri === "") ? (hasCustomBgImage ? customBgUrl : JamiTheme.welcomeBg) : AccountSettingsManager.accountSettingsPropertyMap.backgroundUri
        visible: !hasCustomBgColor
        anchors.fill: parent
        localPath: UtilsAdapter.getCachePath() + "/" + CurrentAccount.id + "/welcomeview/" + UtilsAdapter.base64Encode(downloadUrl) + fileExtension
        imageFillMode: Image.PreserveAspectCrop
        z: -1
    }

    // A blur effect applied to the background image (can be toggled in the Appareance settings)
    FastBlur {
        anchors.fill: welcomeCachedImgLogo
        source: welcomeCachedImgLogo
        radius: JamiTheme.welcomePageFastBlurRadius
        z: -1
        visible: AccountSettingsManager.accountSettingsPropertyMap.backgroundBlurEnabled && welcomeCachedImgLogo.visible
    }

    // A theme-based colour overlay applied to the background image (can be toggled in the Appareance settings)
    ColorOverlay {
        anchors.fill: welcomeCachedImgLogo
        source: welcomeCachedImgLogo
        color: JamiTheme.globalBackgroundColor
        opacity: JamiTheme.welcomePageColorOverlayOpacity
        z: -1
        visible: AccountSettingsManager.accountSettingsPropertyMap.backgroundScrimEnabled && welcomeCachedImgLogo.visible
    }

    WheelHandler {
        onWheel: (wheel)=> {
                     if (wheel.modifiers & Qt.ControlModifier) {
                         var delta = wheel.angleDelta.y / 120
                         UtilsAdapter.setAppValue(Settings.BaseZoom, parseFloat(UtilsAdapter.getAppValue(Settings.BaseZoom)) + delta * 0.1)
                     }
                 }
    }

    Shortcut {
        sequence: "Ctrl+M"
        context: Qt.ApplicationShortcut
        onActivated: JamiQmlUtils.requestSettingsPage(12)
    }

    Shortcut {
        sequence: "Ctrl++"
        context: Qt.ApplicationShortcut
        onActivated: {
            UtilsAdapter.setAppValue(Settings.BaseZoom, parseFloat(UtilsAdapter.getAppValue(Settings.BaseZoom)) + 0.1)
        }
    }

    Shortcut {
        sequence: "Ctrl+="
        context: Qt.ApplicationShortcut
        onActivated: {
            UtilsAdapter.setAppValue(Settings.BaseZoom, parseFloat(UtilsAdapter.getAppValue(Settings.BaseZoom)) + 0.1)
        }
    }

    Shortcut {
        sequence: "Ctrl+-"
        context: Qt.ApplicationShortcut
        onActivated: {
            UtilsAdapter.setAppValue(Settings.BaseZoom, parseFloat(UtilsAdapter.getAppValue(Settings.BaseZoom)) - 0.1)
        }
    }

    Shortcut {
        sequence: "Ctrl+_"
        context: Qt.ApplicationShortcut
        onActivated: {
            UtilsAdapter.setAppValue(Settings.BaseZoom, parseFloat(UtilsAdapter.getAppValue(Settings.BaseZoom)) - 0.1)
        }
    }

    Shortcut {
        sequence: "Ctrl+0"
        context: Qt.ApplicationShortcut
        onActivated: UtilsAdapter.setAppValue(Settings.BaseZoom, 1.0)
    }

    Shortcut {
        sequence: "Ctrl+G"
        context: Qt.ApplicationShortcut
        onActivated: JamiQmlUtils.requestSettingsPage(5)
    }

    Shortcut {
        sequence: "Ctrl+Alt+I"
        context: Qt.ApplicationShortcut
        onActivated: JamiQmlUtils.requestSettingsPage(0)
    }

    Shortcut {
        sequence: "Ctrl+P"
        context: Qt.ApplicationShortcut
        onActivated: JamiQmlUtils.requestSettingsPage(15)
    }

    Shortcut {
        sequence: "F10"
        context: Qt.ApplicationShortcut
        onActivated: {
            KeyboardShortcutTableCreation.createKeyboardShortcutTableWindowObject(appWindow)
            KeyboardShortcutTableCreation.showKeyboardShortcutTableWindow()
        }
    }

    Shortcut {
        sequence: "Esc"
        context: Qt.ApplicationShortcut
        onActivated: {
            MessagesAdapter.replyToId = "";
            MessagesAdapter.editId = "";
            layoutManager.popFullScreenItem();
        }
    }

    Shortcut {
        sequence: "Ctrl+D"
        context: Qt.ApplicationShortcut
        onActivated: CallAdapter.endCall()
        onActivatedAmbiguously: CallAdapter.endCall()
    }

    Shortcut {
        sequence: "Ctrl+Shift+A"
        context: Qt.ApplicationShortcut
        onActivated: LRCInstance.makeConversationPermanent()
    }

    Shortcut {
        sequence: "Ctrl+Shift+N"
        context: Qt.ApplicationShortcut
        onActivated: viewCoordinator.present("WizardView")
    }

    Shortcut {
        sequence: StandardKey.Quit
        context: Qt.ApplicationShortcut
        onActivated: Qt.quit()
    }
}
