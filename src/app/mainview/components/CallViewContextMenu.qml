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
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import net.jami.Models 1.1
import net.jami.Enums 1.1
import "../../commoncomponents"
import "../../commoncomponents/contextmenu"
import "../js/screenrubberbandcreation.js" as ScreenRubberBandCreation

Popup {
    id: root

    signal screenshotTaken
    property bool screenshotButtonHovered: false

    property string hoveredOverlayUri: ""
    property string hoveredOverlaySinkId: ""
    property bool hoveredOverVideoMuted: true
    property bool isOnLocal: false

    property var listModel: ListModel {
        id: actionsModel
    }

    onAboutToShow: {
        actionsModel.clear();
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
    }

    onAboutToHide: {
        screenshotButtonHovered = false;
        hoveredOverlayUri = "";
        hoveredOverlaySinkId = "";
        hoveredOverVideoMuted = true;
        actionsModel.clear();
    }

    background: Rectangle {
        color: "transparent"
    }

    contentItem: Rectangle {
        id: container
        implicitWidth: 200
        implicitHeight: actionsModel.count * 45
        color: "#c4272727"
        radius: 4

        ListView {
            id: itemListView

            orientation: ListView.Vertical
            implicitWidth: 200
            implicitHeight: parent.height
            model: actionsModel

            delegate: ItemDelegate {
                id: menuItem

                width: 200
                height: 45

                background: Rectangle {
                    radius: 5
                    anchors.fill: parent
                    anchors.margins: 5
                    color: menuItem.down ? "#c4aaaaaa" : menuItem.hovered ? "#c4777777" : "transparent"
                }

                RowLayout {
                    anchors.fill: menuItem
                    ResponsiveImage {
                        Layout.leftMargin: JamiTheme.preferredMarginSize
                        source: IconSource
                        color: "white"
                        width: 20
                        height: 20
                    }
                    Text {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignLeft
                        verticalAlignment: Text.AlignVCenter
                        text: Name
                        elide: Text.ElideRight
                        font.pointSize: JamiTheme.participantFontSize
                        color: "white"
                    }
                }

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
            }
        }
    }
}
