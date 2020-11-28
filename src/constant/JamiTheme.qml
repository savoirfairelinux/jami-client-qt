/*
 * Copyright (C) 2020 by Savoir-faire Linux
 * Author: Mingrui Zhang <mingrui.zhang@savoirfairelinux.com>
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

// JamiTheme as a singleton is to provide global theme property entry.
pragma Singleton

import net.jami.Adapters 1.0
import net.jami.Enums 1.0
import net.jami.Models 1.0

import QtQuick 2.14

Item {
    property bool darkTheme: SettingsAdapter.getAppValue(Settings.EnableDarkTheme)

    // Color strings
    property string blackColor: "#000000"
    property string whiteColor: "#ffffff"
    property string transparentColor: "transparent"
    property string primaryForegroundColor: darkTheme? whiteColor : blackColor
    property string primaryBackgroundColor: darkTheme? bgDarkMode_ : whiteColor

    property string pressedButtonColor: darkTheme? pressColor : "#a0a0a0"
    property string hoveredButtonColor: darkTheme? hoverColor : "#c7c7c7"
    property string normalButtonColor: darkTheme? backgroundColor : "#e0e0e0"

    property string invertedPressedButtonColor: Qt.rgba(0, 0, 0, 0.5)
    property string invertedHoveredButtonColor: Qt.rgba(0, 0, 0, 0.6)
    property string invertedNormalButtonColor: Qt.rgba(0, 0, 0, 0.75)

    property string hoverColor: darkTheme? "#515151" : "#c7c7c7"
    property string pressColor: darkTheme? "#777" : "#c0c0c0"
    property string selectedColor: darkTheme? "#0e81c5" : "#e0e0e0"
    property string editBackgroundColor: darkTheme? "#373737" : lightGrey_
    property string textColor: primaryForegroundColor

    property string tabbarBorderColor: darkTheme? "black" : "#e3e3e3"
    property string presenceGreen: "#4cd964"
    property string notificationRed: "#ff3b30"
    property string unPresenceOrange: "orange"
    property string backgroundColor: darkTheme? bgSideBarDarkMode_ : lightGrey_
    property string secondaryBackgroundColor: darkTheme? bgDarkMode_ : "white"
    property string backgroundDarkColor: rgb256(220, 220, 220)

    property string screenSelectionBorderGreen: "green"

    property string acceptButtonGreen: "#4caf50"
    property string acceptButtonHoverGreen: "#5db761"
    property string acceptButtonPressedGreen: "#449d48"

    property string declineButtonRed: "#f44336"
    property string declineButtonHoverRed: "#f5554a"
    property string declineButtonPressedRed: "#db3c30"

    property string hangUpButtonTintedRed: "#ff0000"
    property string buttonTintedBlue: "#00aaff"
    property string buttonTintedBlueHovered: "#0e81c5"
    property string buttonTintedBluePressed: "#273261"
    property string buttonTintedGrey: darkTheme? "#555" : "#999"
    property string buttonTintedGreyHovered: "#777"
    property string buttonTintedGreyPressed: "#777"
    property string buttonTintedGreyInactive: darkTheme? "#777" : "#bbb"
    property string buttonTintedBlack: darkTheme? "#fff" : "#333"
    property string buttonTintedBlackHovered: darkTheme? "#ddd" : "#111"
    property string buttonTintedBlackPressed: darkTheme? "#ddd" : "#000"
    property string buttonTintedRed: "red"
    property string buttonTintedRedHovered: "#c00"
    property string buttonTintedRedPressed: "#b00"

    property string selectionBlue: darkTheme? "#0061a5" : "#109ede"
    property string selectionGreen: "#21be2b"
    property string rubberBandSelectionBlue: "steelblue"

    property string closeButtonLighterBlack: "#4c4c4c"

    property string contactSearchBarPlaceHolderTextFontColor: "#767676"
    property string contactSearchBarPlaceHolderGreyBackground: "#dddddd"

    property string draftRed: "#cf5300"

    property string sipInputButtonBackgroundColor: "#336699"
    property string sipInputButtonHoverColor: "#4477aa"
    property string sipInputButtonPressColor: "#5588bb"

    property string accountCreationOtherStepColor: "grey"
    property string accountCreationCurrentStepColor: "#28b1ed"

    // Font.
    property string faddedFontColor: darkTheme? "#c0c0c0" : "#a0a0a0"
    property string faddedLastInteractionFontColor: darkTheme? "#c0c0c0" : "#505050"

    property string chatviewButtonColor: darkTheme? "#28b1ed" : "#003b4e"

    property int splitViewHandlePreferredWidth: 4
    property int textFontSize: 9
    property int tinyFontSize: 7
    property int settingsFontSize: 9
    property int buttonFontSize: 9
    property int headerFontSize: 13
    property int titleFontSize: 16
    property int menuFontSize: 12

    property int maximumWidthSettingsView: 600
    property int settingsHeaderpreferredHeight: 64
    property int preferredFieldWidth: 256
    property int preferredFieldHeight: 32
    property int preferredMarginSize: 16
    property int preferredDialogWidth: 400
    property int preferredDialogHeight: 300
    property int minimumPreviewWidth: 120

    // Misc.
    property color white: "white"
    property color darkGrey: rgb256(63, 63, 63)

    // Jami theme colors
    function rgb256(r, g, b) {
        return Qt.rgba(r / 255, g / 255, b / 255, 1.0)
    }

    function setTheme(dark) {
        darkTheme = dark
        primaryForegroundColor = darkTheme? whiteColor : blackColor
        primaryBackgroundColor = darkTheme? bgDarkMode_ : whiteColor
        pressedButtonColor = darkTheme? pressColor : "#a0a0a0"
        hoveredButtonColor = darkTheme? hoverColor : "#c7c7c7"
        normalButtonColor = darkTheme? backgroundColor : "#e0e0e0"
        hoverColor = darkTheme? "#515151" : "#c7c7c7"
        pressColor = darkTheme? "#777" : "#c0c0c0"
        selectedColor = darkTheme? "#0e81c5" : "#e0e0e0"
        editBackgroundColor = darkTheme? "#373737" : lightGrey_
        tabbarBorderColor = darkTheme? "black" : "#e3e3e3"
        backgroundColor = darkTheme? bgSideBarDarkMode_ : lightGrey_
        secondaryBackgroundColor = darkTheme? bgDarkMode_ : "white"
        buttonTintedGrey = darkTheme? "#555" : "#999"
        buttonTintedGreyInactive = darkTheme? "#777" : "#bbb"
        buttonTintedBlack = darkTheme? "#fff" : "#333"
        buttonTintedBlackHovered = darkTheme? "#ddd" : "#111"
        buttonTintedBlackPressed = darkTheme? "#ddd" : "#000"
        selectionBlue = darkTheme? "#0061a5" : "#109ede"
        faddedFontColor = darkTheme? "#c0c0c0" : "#a0a0a0"
        faddedLastInteractionFontColor = darkTheme? "#c0c0c0" : "#505050"
        chatviewButtonColor = darkTheme? "#28b1ed" : "#003b4e"
        blueLogo_ = darkTheme? "white" : rgb256(0, 7, 71)

    }

    property color wizardBlueButtons: "#28b1ed"
    property color blueLogo_: darkTheme? "white" : rgb256(0, 7, 71)
    property color lightGrey_: rgb256(242, 242, 242)
    property color grey_: rgb256(160, 160, 160)
    property color red_: rgb256(251, 72, 71)
    property color urgentOrange_: rgb256(255, 165, 0)
    property color green_: rgb256(127, 255, 0)
    property color presenceGreen_: rgb256(76, 217, 100)
    property color bgSideBarDarkMode_: rgb256(24, 24, 24)
    property color bgDarkMode_: rgb256(32, 32, 32)

    property int fadeDuration: 150
}
