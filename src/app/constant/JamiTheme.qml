/*
 * Copyright (C) 2020-2024 Savoir-faire Linux Inc.
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
import QtQuick
import net.jami.Adapters 1.1
import net.jami.Enums 1.1

Item {
    property bool darkTheme: UtilsAdapter.useApplicationTheme()

    Connections {
        target: UtilsAdapter

        function onChangeFontSize() {
            baseZoom = UtilsAdapter.getAppValue(Settings.BaseZoom);
        }

        function onAppThemeChanged() {
            darkTheme = UtilsAdapter.useApplicationTheme();
        }
    }

    // Jami theme colors
    function rgba256(r, g, b, a) {
        return Qt.rgba(r / 255, g / 255, b / 255, a / 100.);
    }

    function calcSize(size) {
        return Math.min(Math.max(5, baseZoom * size), 30);
    }

    function pixelToPoint(size) {
        return size * 0.75;
    }

    property real baseZoom: UtilsAdapter.getAppValue(Settings.BaseZoom)
    property real fontSizeOffset: (Qt.platform.os.toString() === "osx" ? 3 : 0)
    property real fontSizeOffsetSmall: (Qt.platform.os.toString() === "osx" ? 1 : 0)

    // General
    property color blackColor: "#000000"
    property color redColor: "red"
    property color whiteColor: "#ffffff"
    property color darkBlueGreen: "#123F4A"
    property color darkGreyColor: "#272727"
    property color darkGreyColorOpacityFade: "#cc000000" // 80%
    property color darkGreyColorOpacity: "#be272727" // 77%
    property color tintedBlue: darkTheme ? lightTintedBlue : darkTintedBlue
    property color lightTintedBlue: "#03B9E9"
    property color darkTintedBlue: "#005699"
    property color sysColor: "#F0EFEF"

    property color transparentColor: "transparent"
    property color primaryForegroundColor: darkTheme ? whiteColor : blackColor
    property color primaryBackgroundColor: darkTheme ? bgDarkMode_ : whiteColor
    property color backgroundColor: darkTheme ? bgSideBarDarkMode_ : lightGrey_
    property color shadowColor: "#80000000"
    property color secondaryBackgroundColor: darkTheme ? bgDarkMode_ : whiteColor
    property color greyBorderColor: "#333"
    property color selectionBlue: darkTheme ? "#0061a5" : "#109ede"

    property color hoverColor: darkTheme ? "#4d4d4d" : "#DEDEDE"
    property color pressColor: darkTheme ? "#777" : "#c0c0c0"
    property color selectedColor: darkTheme ? "#0e81c5" : "#e0e0e0"
    property color smartListHoveredColor: darkTheme ? "#4d4d4d" : "#dedede"
    property color smartListSelectedColor: darkTheme ? "#4d4d4d" : "#dedede"
    property color editBackgroundColor: darkTheme ? "#373737" : lightGrey_
    property color textColor: primaryForegroundColor
    property color textColorHovered: darkTheme ? "#cccccc" : "#333333"
    property color tabbarBorderColor: darkTheme ? blackColor : "#e3e3e3"
    property color popupOverlayColor: darkTheme ? Qt.rgba(255, 255, 255, 0.22) : Qt.rgba(0, 0, 0, 0.33)
    property real formsRadius: 30

    property color warningRedRectangle: darkTheme ? "#3c131a" : "#fae5e8"

    // Side panel
    property color presenceGreen: "#4cd964"
    property color notificationRed: "#ff3b30"
    property color notificationBlue: "#31b7ff"
    property color unPresenceOrange: "orange"
    property color draftTextColor: "#cf5300"
    property color selectedTabColor: primaryForegroundColor
    property color filterBadgeColor: "#eed4d8"
    property color filterBadgeTextColor: "#cc0022"

    // General buttons
    property color pressedButtonColor: darkTheme ? pressColor : "#a0a0a0"
    property color hoveredButtonColor: darkTheme ? "#4d4d4d" : "#dedede"
    property color hoveredButtonColorWizard: darkTheme ? "#4d4d4d" : "#dedede"
    property color normalButtonColor: darkTheme ? backgroundColor : "#e0e0e0"

    property color invertedPressedButtonColor: Qt.rgba(0, 0, 0, 0.5)
    property color invertedHoveredButtonColor: Qt.rgba(0, 0, 0, 0.6)
    property color invertedNormalButtonColor: Qt.rgba(0, 0, 0, 0.75)

    property color editLineColor: "#03b9e9"
    property color buttonTintedBlue: tintedBlue
    property color buttonTintedBlueHovered: darkTheme ? "#039CC4" : "#0071c9"
    property color buttonTintedBlueInternalHover: Qt.rgba(0, 86, 153, 0.2)
    property color buttonTintedBluePressed: "#0071c9"
    property color buttonTintedGrey: darkTheme ? "#555" : "#999"
    property color buttonTintedGreyHovered: "#777"
    property color buttonTintedGreyPressed: "#777"
    property color buttonTintedGreyInactive: darkTheme ? "#777" : "#bbb"
    property color buttonTintedBlack: darkTheme ? "#fff" : "#333"
    property color buttonTintedBlackHovered: darkTheme ? "#ddd" : "#111"
    property color buttonTintedBlackPressed: darkTheme ? "#ddd" : "#000"
    property color buttonTintedRed: "red"
    property color buttonTintedRedHovered: "#c00"
    property color buttonTintedRedPressed: "#b00"
    property color acceptGreen: rgba256(11, 130, 113, 100)
    property color acceptGreenTransparency: rgba256(11, 130, 113, 56)
    property color refuseRed: rgba256(204, 0, 34, 100)
    property color refuseRedTransparent: rgba256(204, 0, 34, 56)
    property color mosaicButtonNormalColor: "#272727"
    property color whiteColorTransparent: rgba256(255, 255, 255, 50)
    property color raiseHandColor: rgba256(0, 184, 255, 77)

    property color primaryTextColor: darkTheme ? "black" : "white"
    property color secAndTertiTextColor: buttonTintedBlue
    property color secondaryButtonBorderColor: darkTheme ? "#1D5F70" : "#A3C2DA"
    property color secondaryButtonHoveredBorderColor: tintedBlue
    property color secAndTertiHoveredBackgroundColor: darkTheme ? "#123F4A" : "#E5EEF5"
    property color closeButtonLighterBlack: "#4c4c4c"

    property color redButtonColor: darkTheme ? "#FA2E30" : "#CC0022"

    property color backgroundRectangleColor: darkTheme ? "#333333" : "#F0EFEF"
    property color deleteRedButton: "#CC0022"

    property color editButtonBorderColor: darkTheme ? "#333333" : "#F0EFEF"

    // Jami switch
    property color switchBackgroundCheckedColor: "#8dbaea"
    property color switchBackgroundColor: darkTheme ? "#626262" : "#E5EEF5"
    property color switchHandleColor: darkTheme ? "#2B2B2B" : whiteColor
    property color switchHandleCheckedColor: tintedBlue
    property color switchHandleBorderColor: tintedBlue
    property color switchHandleCheckedBorderColor: darkTheme ? "#0071c9" : "#005699"

    // Combobox
    property color comboBoxBackgroundColor: darkTheme ? editBackgroundColor : selectedColor
    property color comboboxBorderColorActive: darkTheme ? "#03B9E9" : "#005699"
    property color comboboxBorderColor: darkTheme ? "#1D5F70" : "#A3C2DA"
    property color comboboxIconColor: darkTheme ? "#03B9E9" : "#005699"
    property color comboboxBackgroundColorHovered: darkTheme ? "#123F4A" : "#E5EEF5"
    property color comboboxTextColor: darkTheme ? "#03B9E9" : "#005699"
    property color comboboxTextColorHovered: tintedBlue
    property color accountComboBoxBackgroundColor: darkTheme ? "#333333" : lightGrey_

    // Spinbox
    property color spinboxBackgroundColor: darkTheme ? editBackgroundColor : selectedColor
    property color spinboxBorderColor: darkTheme ? "#1D5F70" : "#A3C2DA"

    //RecordBox
    property color screenshotButtonColor: "#CC0022"
    property color recordBoxcloseButtonColor: "#8d8a87"
    property color recordBoxHoverColor: "#4D4D4D"
    property color recordBoxButtonColor: "#272727"

    // Toast
    property color toastColor: darkTheme ? "#f0f0f0" : "#000000"
    property color toastRectColor: !darkTheme ? "#f0f0f0" : "#000000"
    property real toastFontSize: calcSize(15)

    // Call buttons
    property color acceptButtonGreen: "#4caf50"
    property color acceptButtonHoverGreen: "#5db761"
    property color acceptButtonPressedGreen: "#449d48"

    property color declineButtonRed: "#f44336"
    property color declineButtonHoverRed: "#f5554a"
    property color declineButtonPressedRed: "#db3c30"

    property color sipInputButtonBackgroundColor: "#336699"
    property color sipInputButtonHoverColor: "#4477aa"
    property color sipInputButtonPressColor: "#5588bb"

    property string buttonConference: "transparent"
    property string buttonConferenceHovered: "#110000"
    property string buttonConferencePressed: "#110000"

    // Wizard / account manager
    property color accountCreationOtherStepColor: "grey"
    property color accountCreationCurrentStepColor: "#28b1ed"
    property color wizardBlueButtons: "#28b1ed"
    property color wizardGreenColor: "#aed581"
    property color requiredFieldColor: "#ff1f62"
    property color requiredFieldBackgroundColor: "#fee4e9"
    property color customizePhotoColor: "#0B03DB"
    property color customizePhotoHoveredColor: "#3B35E2"
    property color customizeRectangleColor: darkTheme ? "#333333" : "#F0EFEF"

    // Misc
    property color recordIconColor: "#dc2719"
    property color successLabelColor: "#2b5084"
    property color rubberBandSelectionBlue: "steelblue"
    property color screenSelectionBorderColor: raiseHandColor
    property color separationLine: darkTheme ? selectedColor : backgroundColor

    // ParticipantCallInStatusView
    property color participantCallInStatusTextColor: whiteColor

    // InvitationView
    property color blockOrange: rgba256(232, 92, 36, 100)
    property color blockOrangeTransparency: rgba256(232, 92, 36, 56)

    // Chatview
    property color jamiLightBlue: darkTheme ? "#003b4e" : Qt.rgba(59, 193, 211, 0.3)
    property color jamiDarkBlue: darkTheme ? "#28b1ed" : "#003b4e"
    property color chatviewTextColor: darkTheme ? "#f0f0f0" : "#000000"
    property color chatviewTextColorLight: "#f0f0f0"
    property color chatviewTextColorDark: "#353637"
    property color chatviewLinkColorLight: "#f0f0f0"
    property color chatviewLinkColorDark: "#353637"
    property real chatviewFontSize: calcSize(15)
    property real chatviewEmojiSize: calcSize(60)
    property color timestampColor: darkTheme ? "#515151" : "#E5E5E5"
    property color messageReplyColor: darkTheme ? "#bbb" : "#A7A7A7"
    property color messageOutTxtColor: "#000000"
    property color messageInBgColor: darkTheme ? "#303030" : "#e5e5e5"
    property color messageOutBgColor: darkTheme ? "#616161" : "#005699"
    property color messageInTxtColor: "#FFFFFF"
    property color fileOutTimestampColor: darkTheme ? "#eee" : "#555"
    property color fileInTimestampColor: darkTheme ? "#999" : "#555"
    property color chatviewBgColor: darkTheme ? bgDarkMode_ : whiteColor
    property color bgInvitationRectColor: darkTheme ? "#222222" : whiteColor
    property color messageBarPlaceholderTextColor: darkTheme ? "#909090" : "#7e7e7e"
    property color placeholderTextColor: darkTheme ? "#7a7a7a" : "black" //Qt.rgba(0, 0, 0, 0.2)
    property color placeholderTextColorWhite: "#cccccc"
    property color inviteHoverColor: darkTheme ? blackColor : whiteColor
    property color chatviewButtonColor: darkTheme ? whiteColor : blackColor
    property color bgTextInput: darkTheme ? "#060608" : whiteColor
    property color previewTextContainerColor: darkTheme ? "#959595" : "#ececec"
    property color previewImageBackgroundColor: whiteColor
    property color previewCardContainerColor: darkTheme ? blackColor : whiteColor
    property color previewUrlColor: darkTheme ? "#eeeeee" : "#333"
    property color messageWebViewFooterButtonImageColor: darkTheme ? "#838383" : "#656565"
    property color chatviewSecondaryInformationColor: "#A7A7A7"
    property color draftIconColor: "#707070"

    // ChatView Footer
    property color chatViewFooterListColor: darkTheme ? blackColor : "#E5E5E5"
    property color chatViewFooterImgHoverColor: darkTheme ? whiteColor : blackColor
    property color chatViewFooterImgColor: darkTheme ? "#909090" : "#7e7e7e"
    property color chatViewFooterImgDisableColor: darkTheme ? "#4d4d4d" : "#cbcbcb"
    property color showMoreButtonOpenColor: darkTheme ? "#4d4d4d" : "#e5e5e5"
    property color chatViewFooterSeparateLineColor: darkTheme ? "#5c5c5c" : "#929292"
    property color chatViewFooterSendButtonColor: darkTheme ? "#03B9E9" : "#005699"
    property color chatViewFooterSendButtonDisableColor: darkTheme ? "#191a1c" : "#f0f0f1"
    property color chatViewFooterSendButtonImgColor: darkTheme ? blackColor : whiteColor
    property color chatViewFooterSendButtonImgColorDisable: darkTheme ? "#4d4d4d" : "#cbcbcb"
    property color chatViewFooterRectangleBorderColor: darkTheme ? "#4d4d4d" : "#e5e5e5"

    // ChatView Header
    property real chatViewHeaderButtonRadius: 5

    // mapPosition
    property color mapButtonsOverlayColor: darkTheme ? "#000000" : "#f0f0f0"
    property color mapButtonColor: darkTheme ? "#f0f0f0" : "#000000"
    property color sharePositionIndicatorColor: darkTheme ? "#03B9E9" : "#005699"
    property color sharedPositionIndicatorColor: darkTheme ? whiteColor : blackColor

    // EmojiReact
    property real emojiBubbleSize: calcSize(17)
    property real emojiBubbleSizeBig: calcSize(21)
    property real emojiReactSize: calcSize(12)
    property real emojiPopupFontsize: calcSize(25)
    property real emojiPopupFontsizeBig: calcSize(28)
    property real namePopupFontsize: calcSize(15)
    property real avatarSize: 30
    property int emojiPushButtonSize: 30
    property int emojiMargins: 16
    property color emojiReactBubbleBgColor: darkTheme ? darkGreyColor : whiteColor
    property color emojiReactPushButtonColor: darkTheme ? "#bbb" : "#003b4e"
    property real messageOptionTextFontSize: calcSize(15)
    property int emojiPickerWidth: 400
    property int emojiPickerHeight: 425
    property int defaulMaxWidthReaction: 350

    // Files To Send Container
    property color removeFileButtonColor: Qt.rgba(96, 95, 97, 0.5)
    property color removeFileButtonHoverColor: "#DEDEDE"
    property color fileIconDarkColor: "#656565"
    property color fileIconLightColor: "#A6A6A6"
    property color fileIconColor: darkTheme ? "#A6A6A6" : "#656565"
    property color fileBackgroundColor: darkTheme ? "#515151" : "#c3c3c3"

    // JamiScrollBar
    property color scrollBarHandleColor: "#cecece"

    // TypingDots
    property color typingDotsNormalColor: darkTheme ? "#686b72" : "lightgrey"
    property color typingDotsEnlargeColor: darkTheme ? "white" : Qt.darker("lightgrey", 3.0)

    // Font
    property color faddedFontColor: darkTheme ? "#c0c0c0" : "#a0a0a0"
    property color faddedLastInteractionFontColor: darkTheme ? "#c0c0c0" : "#505050"

    property color darkGrey: rgba256(63, 63, 63, 100)
    property color blueLogo_: darkTheme ? whiteColor : rgba256(0, 7, 71, 100)
    property color lightGrey_: rgba256(242, 242, 242, 100)
    property color mediumGrey: rgba256(218, 219, 220, 100)
    property color grey_: rgba256(160, 160, 160, 100)
    property color red_: rgba256(251, 72, 71, 100)
    property color urgentOrange_: rgba256(255, 165, 0, 100)
    property color green_: rgba256(127, 255, 0, 100)
    property color presenceGreen_: rgba256(76, 217, 100, 100)
    property color bgSideBarDarkMode_: rgba256(24, 24, 24, 100)
    property color bgDarkMode_: "#201f21"

    property int shortFadeDuration: 150
    property int longFadeDuration: 400
    property int recordBlinkDuration: 500
    property int overlayFadeDelay: 4000
    property int overlayFadeDuration: 250
    property int smartListTransitionDuration: 120

    // Sizes
    property real mainViewLeftPaneMinWidth: 300
    property real currentLeftPaneWidth: mainViewLeftPaneMinWidth
    property real mainViewPaneMinWidth: 490
    property real qrCodeImageSize: 256
    property real splitViewHandlePreferredWidth: 4
    property real indicatorFontSize: calcSize(6)
    property real tinyFontSize: calcSize(7 + fontSizeOffset)
    property real textFontSize: calcSize(9 + fontSizeOffset)
    property real smallFontSize: calcSize(9 + fontSizeOffsetSmall)
    property real mediumFontSize: calcSize(10.5 + fontSizeOffset)
    property real bigFontSize: calcSize(22)
    property real settingsFontSize: calcSize(11 + fontSizeOffset)
    property real buttonFontSize: calcSize(9)
    property real materialButtonPreferredHeight: calcSize(36)
    property real participantFontSize: calcSize(10 + fontSizeOffset)
    property real menuFontSize: calcSize(12 + fontSizeOffset)
    property real headerFontSize: calcSize(14.25 + fontSizeOffset)
    property real titleFontSize: calcSize(16 + fontSizeOffset)
    property real title2FontSize: calcSize(15 + fontSizeOffset)
    property real tinyCreditsTextSize: calcSize(13 + fontSizeOffset)
    property real creditsTextSize: calcSize(15 + fontSizeOffset)
    property real primaryRadius: calcSize(4)
    property real filterItemFontSize: calcSize(mediumFontSize)
    property real filterBadgeFontSize: calcSize(8.25)
    property real editedFontSize: calcSize(8)
    property real accountListItemHeight: 64
    property real accountListAvatarSize: 40
    property real smartListItemHeight: 64
    property real smartListAvatarSize: 52
    property real avatarSizeInCall: 130
    property real aboutButtonPreferredWidth: 150
    property real aboutLogoPreferredWidth: 183
    property real aboutLogoPreferredHeight: 61
    property real callButtonPreferredSize: 50
    property real contextMenuItemTextPreferredWidth: 152
    property real contextMenuItemTextMaxWidth: 182
    property int participantCallInStatusViewWidth: 175
    property int participantCallInStatusViewHeight: 300
    property int participantCallInStatusDelegateHeight: 85
    property int participantCallInStatusDelegateRadius: 5
    property real participantCallInStatusOpacity: 0.77
    property int participantCallInAvatarSize: 60
    property int participantCallInNameFontSize: calcSize(11)
    property int participantCallInStatusFontSize: calcSize(8)
    property int participantCallInStatusTextWidthLimit: 80
    property int participantCallInStatusTextWidth: 40
    property int mosaicButtonRadius: 5
    property int mosaicButtonPreferredMargin: 5
    property real mosaicButtonOpacity: 0.77
    property int mosaicButtonTextPreferredWidth: 40
    property int mosaicButtonTextPreferredHeight: 16
    property int mosaicButtonTextPointSize: calcSize(8 + fontSizeOffsetSmall)
    property int mosaicButtonPreferredWidth: 70
    property int mosaicButtonMaxWidth: 100
    property real avatarPresenceRatio: 0.26
    property int avatarReadReceiptSize: 18

    property int menuItemsPreferredWidth: 220
    property int menuItemsPreferredHeight: 36
    property int menuItemsCommonBorderWidth: 1
    property int menuBorderPreferredHeight: 5

    property real maximumWidthSettingsView: 516
    property real settingsHeaderpreferredHeight: 64
    property real preferredFieldWidth: 256
    property real preferredFieldHeight: 36
    property real preferredButtonSettingsHeight: 46
    property real preferredMarginSize: 16
    property real preferredSettingsMarginSize: 40
    property real preferredSettingsContentMarginSize: 30
    property real preferredSettingsBottomMarginSize: 30
    property real settingsMarginSize: 8
    property real preferredDialogWidth: 400
    property real preferredDialogHeight: 300
    property real minimumPreviewWidth: 120
    property real minimumMapWidth: 250
    property real pluginHandlersPopupViewHeight: 200
    property real pluginHandlersPopupViewDelegateHeight: 50
    property color pluginDefaultBackgroundColor: "#666666"
    property real remotePluginMinimumDelegateWidth: 430
    property real remotePluginMinimumDelegateHeight: 275
    property real remotePluginMaximumDelegateWidth: 645
    property real remotePluginMaximumDelegateHeight: 413
    property real iconMargin: 25 * baseZoom
    property real remotePluginDelegateWidth: remotePluginMinimumDelegateWidth * baseZoom
    property real remotePluginDelegateHeight: remotePluginMinimumDelegateHeight * baseZoom
    property color pluginViewBackgroundColor: darkTheme ? "#000000" : "#F0EFEF"
    property real secondaryDialogDimension: 500

    property real lineEditContextMenuItemsHeight: 15
    property real lineEditContextMenuItemsWidth: 100
    property real lineEditContextMenuSeparatorsHeight: 2
    property color menuSeparatorColor: darkTheme ? "#4d4d4d" : "#DEDEDE"

    // Recording
    property real recordingBtnSize: 12
    property real recordingIndicatorSize: 24

    // TimestampInfo
    property int timestampLinePadding: 40
    property int dayTimestampHPadding: 16
    property real dayTimestampVPadding: 32
    property real timestampFont: calcSize(12)
    property int timestampIntervalTime: 120

    // SwarmDetailsPage
    property real swarmDetailsPageTopMargin: 32
    property real swarmDetailsPageDocumentsMargins: 5
    property real swarmDetailsPageDocumentsMediaRadius: 15
    property real swarmDetailsPageDocumentsPaperClipSize: 24
    property real swarmDetailsPageDocumentsMediaSize: 150
    property real swarmDetailsPageDocumentsHeight: 40 * baseZoom
    property real swarmDetailsPageDocumentsMinHeight: 40

    // Call information
    property real textFontPointSize: calcSize(10)
    property real titleFontPointSize: calcSize(13)
    property color callInfoColor: whiteColor
    property int callInformationElementsSpacing: 5
    property int callInformationBlockSpacing: 25
    property int callInformationlayoutMargins: 10

    // Jami switch
    property real switchIndicatorRadius: 30
    property real switchPreferredHeight: 20
    property real switchPreferredWidth: 40
    property real switchIndicatorPreferredWidth: 20

    // Modal Popup
    property real modalPopupRadius: 20
    property real photoPopupRadius: 5

    //MessagesResearch
    property color blueLinkColor: darkTheme ? "#3366BB" : "#0645AD"
    property real jumpToFontSize: calcSize(13)
    property real searchbarSize: 200

    // MessageWebView
    property real chatViewHairLineSize: 1
    property real chatViewMaximumWidth: 900
    property real chatViewHeaderPreferredHeight: 64
    property real chatViewFooterPreferredHeight: 35
    property real chatViewFooterMaximumHeight: 315
    property real chatViewFooterRowSpacing: 4
    property real chatViewFooterButtonSize: 36
    property real chatViewFooterRealButtonSize: 26
    property real chatViewFooterButtonIconSize: 48
    property real chatViewFooterButtonRadius: 5
    property real chatViewFooterTextAreaMaximumHeight: 260
    property real chatViewScrollToBottomButtonBottomMargin: 8

    property real usernameBlockFontSize: calcSize(12)
    property real usernameBlockLineHeight: 14
    property real usernameBlockPadding: contactMessageAvatarSize + 8

    // TypingDots
    property real typingDotsAnimationInterval: 500
    property real typingDotsRadius: 30
    property real typingDotsSize: 8

    // MessageWebView File Transfer Container
    property real filesToSendContainerSpacing: 25
    property real filesToSendContainerPadding: 10
    property real filesToSendDelegateHeight: 100
    property real filesToSendDelegateRadius: 7
    property real filesToSendDelegateButtonSize: 16
    property real filesToSendDelegateFontPointSize: calcSize(10 + fontSizeOffset)
    property real layoutWidthFileTransfer: 56

    // SBSMessageBase
    property int sbsMessageBasePreferredPadding: 12
    property int sbsMessageBaseMaximumReplyWidth: baseZoom * 300
    property int sbsMessageBaseMaximumReplyHeight: baseZoom * 40
    property int sbsMessageBaseReplyBottomMargin: baseZoom * 10
    property int sbsMessageBaseReplyMargin: 45
    property int sbsMessageBaseReplyTopMargin: 6

    // MessageBar
    property int messageBarMarginSize: 10
    property int messageBarMinimumWidth: 438

    // InvitationView
    property real invitationViewAvatarSize: 112
    property real invitationViewButtonRadius: 25
    property real invitationViewButtonSize: 48
    property real invitationViewButtonIconSize: 24
    property real invitationViewButtonsSpacing: 30

    //JamiIdentifier
    property real jamiIdMargins: 36
    property real jamiIdLogoWidth: 70
    property real jamiIdLogoHeight: 24
    property real jamiIdFontSize: calcSize(19)
    property real jamiIdSmallFontSize: calcSize(11)
    property color jamiIdColor: darkTheme ? blackColor : sysColor
    property color mainColor: "#005699"
    property real pushButtonSize: 22
    property real pushButtonMargins: 10
    property color jamiIdBackgroundColor: darkTheme ? "#333333" : "#F0EFEF"
    property color redDotColor: "#CC0022"

    // MainView
    property color rectColor: darkTheme ? blackColor : "#e5eef5"
    property color welcomeText: darkTheme ? "#0071c9" : "#002B4A"
    property real illustrationWidth: 212
    property real illustrationHeight: 244

    // WizardView
    property real wizardViewPageLayoutSpacing: 12
    property real wizardViewPageBackButtonMargins: 20
    property real wizardViewPageBackButtonSize: 30
    property real wizardViewPageBackButtonWidth: 51
    property real wizardViewPageBackButtonHeight: 30
    property real wizardViewTitleFontPixelSize: calcSize(26)
    property real wizardViewDescriptionFontPixelSize: calcSize(15)
    property real wizardViewButtonFontPixelSize: calcSize(15)
    property real wizardViewAboutJamiFontPixelSize: calcSize(12)
    property real wizardViewLayoutTopMargin: 38
    property real wizardViewTextLineHeight: 1.4
    property real wizardViewMarginSize: pixelToPoint(10)
    property real wizardViewBlocMarginSize: pixelToPoint(40)
    property real wizardViewDescriptionMarginSize: pixelToPoint(20)

    // WizardView Welcome Page
    property real welcomeLabelPointSize: 30
    property var welcomeLogo: darkTheme ? JamiResources.logo_jami_standard_coul_white_svg : JamiResources.logo_jami_standard_coul_svg
    property real welcomeLogoWidth: 100
    property real welcomeLogoHeight: 100
    property real wizardButtonWidth: 400
    property real wizardButtonHeightMargin: 31
    property color welcomeViewBackgroundColor: darkTheme ? lightGrey_ : secondaryBackgroundColor
    property real welcomeRectSideMargins: 45
    property real welcomeRectTopMargin: 90
    property real welcomePageSpacing: 13
    property real welcomeGridWidth: 3 * JamiTheme.tipBoxWidth + 2 * JamiTheme.welcomePageSpacing
    property real welcomeThirdGridWidth: (welcomeGridWidth - JamiTheme.welcomePageSpacing) / 3
    property real welcomeShortGridWidth: 2 * JamiTheme.tipBoxWidth + JamiTheme.welcomePageSpacing
    readonly property string welcomeBg: darkTheme ? JamiResources.background_don_dark_jpg : JamiResources.background_don_white_jpg
    property color welcomeBlockColor: darkTheme ? "#4D000000" : "#4DFFFFFF"

    // WizardView Advanced Account Settings
    property color lightBlue_: darkTheme ? "#03B9E9" : "#e5eef5"
    property color shadowColorBlue: Qt.rgba(0, 0.34, 0.6, 0.16)
    property real passwordEditOpenedBoxWidth: 425
    property real passwordEditClosedBoxWidth: 330
    property real passwordEditOpenedBoxHeight: 380
    property real passwordEditClosedBoxHeight: 65
    property real customNicknameOpenedBoxWidth: 412
    property real customNicknameClosedBoxWidth: 230
    property real customNicknameOpenedBoxHeight: 320
    property real customNicknameClosedBoxHeight: 65
    property real advancedAccountSettingsHeightMargin: 16.5

    property real cornerIconSize: 40

    property color wizardIconColor: darkTheme ? "#8c8c8c" : "#7f7f7f"

    // InfoBox
    property real infoBoxTitleFontSize: calcSize(13)
    property real infoBoxDescFontSize: calcSize(12)
    property color infoRectangleColor: JamiTheme.darkTheme ? "#143842" : "#e5eef5"

    // Tipbox
    property real tipBoxWidth: 200
    property real tipBoxTitleFontSize: calcSize(13)
    property real tipBoxContentFontSize: calcSize(12)
    property color tipBoxBackgroundColor: darkTheme ? blackColor : whiteColor
    property color tipBoxBorderColor: darkTheme ? "#123F4A" : "#A3C2DA"
    property color tooltipBackgroundColor: darkTheme ? "#66000000" : "#c4272727"
    property color tooltipShortCutBackgroundColor: darkTheme ? blackColor : "#2c2c2c"
    property color tooltipShortCutTextColor: "#a7a7a7"

    // SharePosition
    property real timerButtonsFontSize: calcSize(11)

    // Popups
    property real popuptextSize: calcSize(15)
    property real popupButtonsMargin: 20
    property real popupPhotoTextSize: calcSize(18)

    // MaterialLineEdit
    property real materialLineEditPointSize: calcSize(10 + fontSizeOffset)
    property real materialLineEditPixelSize: calcSize(15)
    property real materialLineEditSelectedPixelSize: calcSize(12)
    property real materialLineEditPadding: 16
    property real textEditError: calcSize(15)
    property real maximumCharacters: 50

    // PasswordTextEdit
    property color passwordEyeIconColor: "#5d5d5d"
    property color passwordBaselineColor: darkTheme ? "#6e6e6e" : "#9fbfd9"

    // MaterialButton
    property real buttontextPadding: 10
    property real buttontextWizzardPadding: 30
    property real buttontextHeightMargin: 21
    property real buttontextFontPixelSize: calcSize(15)

    // UsernameTextEdit
    property real usernameTextEditPointSize: calcSize(9 + fontSizeOffset)
    property real usernameTextEditlookupInterval: 200

    // JamiScrollBar
    property int scrollBarHandleSize: 6

    // KeyboardShortcutTable
    property int titleRectMargin: 25
    property int keyboardShortcutTabBarSize: 24
    property int keyboardShortcutDelegateSize: 50

    // Main application spec
    property real mainViewMinWidth: 490
    property real mainViewMinHeight: 500

    property real wizardViewMinWidth: 500
    property real wizardViewMinHeight: 600

    property real mainViewPreferredWidth: 730
    property real mainViewPreferredHeight: 600

    property real mainViewMargin: 25

    // Extras panel
    property real extrasPanelMinWidth: 300
    property int aboutBtnSize: 24

    // Messages point size
    property real contactEventPointSize: calcSize(10 + fontSizeOffset)
    property int contactMessageAvatarSize: 24

    // Settings
    property int settingMenuPixelSize: calcSize(13)
    property int settingToggleDescrpitonPixelSize: calcSize(13)
    property int settingsTitlePixelSize: calcSize(22)
    property int settingsHeaderPixelSize: calcSize(26)
    property int settingsDescriptionPixelSize: calcSize(15)
    property int settingsCategorySpacing: 15
    property int settingsCategoryAudioVideoSpacing: 6
    property int settingsBoxRadius: 5
    property int settingsBlockSpacing: 40
    property int settingsMenuChildrenButtonHeight: 30
    property int settingsMenuHeaderButtonHeight: 50
    property int settingsListViewsSpacing: 10

    // Link Device
    property color pinBackgroundColor: "#D6E4EF"

    // MaterialRadioButton
    property int radioImageSize: 30
    property color radioBackgroundColor: darkTheme ? "#303030" : "#F0EFEF"
    property color radioBorderColor: darkTheme ? "#03B9E9" : "#005699"
    property color lightThemeBackgroundColor: JamiTheme.whiteColor
    property color lightThemeCheckedColor: "#005699"
    property color lightThemeBorderColor: "#005699"
    property color darkThemeBackgroundColor: JamiTheme.darkTheme ? JamiTheme.blackColor : JamiTheme.bgDarkMode_
    property color darkThemeCheckedColor: "#03B9E9"
    property color darkThemeBorderColor: "#03B9E9"

    // Donation campaign
    property color donationButtonTextColor: "#005699"
    property color donationBackgroundColor: "#D5E4EF"
    property string donationUrl: "https://jami.net/whydonate/"

    //Connection monitoring
    property color connectionMonitoringTableColor1: darkTheme ? "#4D4D4D" : "#f0efef"
    property color connectionMonitoringTableColor2: darkTheme ? "#333333" : "#f6f5f5"
    property color connectionMonitoringHeaderColor: darkTheme ? "#6F6F6F" : "#d1d1d1"

    function setTheme(dark) {
        darkTheme = dark;
    }

    //Chat setting page
    property color chatSettingButtonBackgroundColor: darkTheme ? "#303030" : "#F0EFEF"
    property color chatSettingButtonBorderColor: darkTheme ? "#03B9E9" : "#005699"
    property color chatSettingButtonTextColor: textColor
}
