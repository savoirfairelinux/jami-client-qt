/*
 * Copyright (C) 2020-2023 Savoir-faire Linux Inc.
 * Author: Mingrui Zhang <mingrui.zhang@savoirfairelinux.com>
 * Author: Sébastien Blin <sebastien.blin@savoirfairelinux.com>
 * Author: Aline Gondim Santos <aline.gondimsantos@savoirfairelinux.com>
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
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import net.jami.Models 1.1
import net.jami.Enums 1.1
import "../../commoncomponents"
import "../../commoncomponents/contextmenu"
import "../js/screenrubberbandcreation.js" as ScreenRubberBandCreation

Popup {
    id: root
    property bool hoveredOverVideoMuted: true
    property string hoveredOverlaySinkId: ""
    property string hoveredOverlayUri: ""
    property bool isOnLocal: false
    property var listModel: ListModel {
        id: actionsModel
    }
    property bool screenshotButtonHovered: false

    signal screenshotTaken

    onAboutToHide: {
        screenshotButtonHovered = false;
        hoveredOverlayUri = "";
        hoveredOverlaySinkId = "";
        hoveredOverVideoMuted = true;
        actionsModel.clear();
    }
    onAboutToShow: {
        actionsModel.clear();
        actionsModel.append({
                "Top": true
            });
        if (root.isOnLocal)
            actionsModel.append({
                    "Name": JamiStrings.mirrorLocalVideo,
                    "IconSource": JamiResources.flip_24dp_svg
                });
        if (hoveredOverlayUri !== "" && hoveredOverVideoMuted === false)
            actionsModel.append({
                    "Name": JamiStrings.tileScreenshot,
                    "IconSource": JamiResources.screenshot_black_24dp_svg
                });
        actionsModel.append({
                "Name": JamiStrings.advancedInformation,
                "IconSource": JamiResources.informations_black_24dp_svg
            });
        actionsModel.append({
                "Bottom": true
            });
        itemListView.implicitHeight = 20 + 45 * (actionsModel.count - 2);
    }

    background: Rectangle {
        color: "transparent"
    }
    contentItem: Rectangle {
        id: container
        color: "#c4272727"
        height: childrenRect.height
        radius: 4
        width: childrenRect.width

        ColumnLayout {
            anchors.bottomMargin: 8
            anchors.topMargin: 8

            ListView {
                id: itemListView
                implicitHeight: 100
                implicitWidth: 200
                interactive: false
                model: actionsModel
                orientation: ListView.Vertical

                delegate: ItemDelegate {
                    id: menuItem
                    height: Top || Bottom ? 10 : 45
                    width: 200

                    onClicked: {
                        switch (Name) {
                        case JamiStrings.advancedInformation:
                            CallAdapter.startTimerInformation();
                            callInformationOverlay.open();
                            break;
                        case JamiStrings.tileScreenshot:
                            if (CallAdapter.takeScreenshot(videoProvider.captureRawVideoFrame(hoveredOverlaySinkId), UtilsAdapter.getDirScreenshot())) {
                                screenshotTaken();
                            }
                            break;
                        case JamiStrings.mirrorLocalVideo:
                            UtilsAdapter.setAppValue(Settings.FlipSelf, !UtilsAdapter.getAppValue(Settings.FlipSelf));
                            CurrentCall.flipSelf = UtilsAdapter.getAppValue(Settings.FlipSelf);
                            break;
                        }
                        root.close();
                    }
                    onHoveredChanged: {
                        if (Name === JamiStrings.tileScreenshot) {
                            screenshotButtonHovered = hovered;
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        visible: !Top && !Bottom

                        ResponsiveImage {
                            Layout.leftMargin: JamiTheme.preferredMarginSize
                            color: "white"
                            height: 20
                            source: IconSource
                            width: 20
                        }
                        Text {
                            Layout.fillWidth: true
                            color: "white"
                            elide: Text.ElideRight
                            font.pointSize: JamiTheme.participantFontSize
                            horizontalAlignment: Text.AlignLeft
                            text: Name
                            verticalAlignment: Text.AlignVCenter
                        }
                    }

                    background: Rectangle {
                        anchors.fill: parent
                        color: menuItem.down ? "#c4aaaaaa" : menuItem.hovered ? "#c4777777" : "transparent"
                        visible: !Top && !Bottom
                    }
                }
            }
        }
    }
}
