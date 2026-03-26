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
import QtQuick.Controls.impl

import net.jami.Constants 1.1
import "../mainview/components"

BaseModalDialog {
    id: root

    property int errorCode: 0
    property string errorTitle: JamiStrings.sipResponse
    property string errorDescription: ""
    property string helpBoxTextValue: ""
    property bool showHelpBox: false
    property string showMoreTextValue: ""

    button1Role: DialogButtonBox.AcceptRole
    button1.text: JamiStrings.optionOk
    button1.onClicked: close()

    closeButtonVisible: false

    // Function to set error details based on the sip_call_status_code_map error code
    // List of SIP response codes: https://en.wikipedia.org/wiki/List_of_SIP_response_codes
    function showSIPCallStatusError(errorCode) {
        showHelpBox = false;
        helpBoxTextValue = "";
        showMoreTextValue = "";

        switch (errorCode) {
        case 400: // Bad Request
            errorDescription = JamiStrings.sipResponse400Description;
            break;
        case 401: // Unauthorized
            errorDescription = JamiStrings.sipResponse401Description;
            break;
        case 403: // Forbidden
            errorDescription = JamiStrings.sipResponse403Description;
            break;
        case 404: // Not Found
            errorDescription = JamiStrings.sipResponse404Description;
            break;
        case 407: // Proxy Authentication Required
            errorDescription = JamiStrings.sipResponse407Description;
            break;
        case 408: // Request Timeout
            errorDescription = JamiStrings.sipResponse408Description;
            break;
        case 415: // Unsupported Media Type
            errorDescription = JamiStrings.sipResponse415Description;
            showHelpBox = true;
            helpBoxTextValue = JamiStrings.sipResponseHowDoIChangeMyCodecs;
            showMoreTextValue = JamiStrings.sipResponseCodecsHowTo;
            break;
        case 480: // Temporarily Unavailable
            errorDescription = JamiStrings.sipResponse480Description;
            break;
        case 500: // Server Internal Error
            errorDescription = JamiStrings.sipResponse500Description;
            break;
        case 503: // Service Unavailable
            errorDescription = JamiStrings.sipResponse503Description;
            break;
        default:
            errorDescription = JamiStrings.sipResponseMessage;
            break;
        }
        open();
    }

    popupContent: ColumnLayout {
        Label {
            id: titleText

            text: errorTitle

            Layout.leftMargin: popupMargins
            Layout.rightMargin: popupMargins
            Layout.bottomMargin: 20
            Layout.topMargin: closeButtonVisible ? 0 : 30
            Layout.alignment: Qt.AlignLeft

            font.pointSize: JamiTheme.menuFontSize + 2
            color: JamiTheme.textColor
            font.bold: true

            visible: text.length > 0
        }

        Label {
            id: descriptionText

            text: JamiStrings.sipResponseGeneralErrorTemplate.arg(errorDescription)

            Layout.leftMargin: popupMargins
            Layout.rightMargin: popupMargins
            Layout.bottomMargin: 15
            Layout.fillWidth: true
            Layout.maximumWidth: maximumPopupWidth - (2 * popupMargins)
            Layout.alignment: Qt.AlignCenter

            font.pointSize: JamiTheme.textFontSize + 2
            color: JamiTheme.textColor
            wrapMode: Text.WordWrap
            textFormat: Text.RichText

            visible: text.length > 0
        }

        RowLayout {
            id: helpBox

            Layout.alignment: Qt.AlignHCenter

            visible: root.showHelpBox

            Text {
                id: helpBoxText
                Layout.fillWidth: true

                text: root.helpBoxTextValue
                color: JamiTheme.textColor
                horizontalAlignment: Text.AlignHCenter

                elide: Text.ElideRight
            }

            NewIconButton {
                Layout.alignment: Qt.AlignVCenter

                iconSize: JamiTheme.iconButtonSmall
                iconSource: JamiResources.bidirectional_help_outline_24dp_svg
                toolTipText: showMoreText.visible ? JamiStrings.showLess : JamiStrings.showMore

                checked: showMoreText.visible

                onClicked: showMoreText.visible = !showMoreText.visible
            }
        }

        Text {
            id: showMoreText

            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter

            text: root.showMoreTextValue
            horizontalAlignment: Text.AlignHCenter
            color: JamiTheme.textColor
            wrapMode: Text.WordWrap

            visible: false

            opacity: visible ? 1.0 : 0.0

            Behavior on opacity {
                NumberAnimation {
                    duration: JamiTheme.shortFadeDuration
                }
            }
        }

    }
}
