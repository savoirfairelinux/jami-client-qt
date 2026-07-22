/*
 * Copyright (C) 2022-2026 Savoir-faire Linux Inc.
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
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1

BaseModalDialog {
    id: root

    property var previousBodies: undefined
    property bool showOriginal: false

    titleText: JamiStrings.edits

    popupContent: JamiListView {
        id: editsList

        width: 400 - 2 * root.popupMargins
        height: Math.min(contentHeight, 250)

        spacing: 8

        focus: true
        activeFocusOnTab: true

        model: root.previousBodies

        delegate: ItemDelegate {
            id: editDelegate

            width: editsList.width
            height: implicitHeight
            implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                                     implicitContentHeight + topPadding + bottomPadding,
                                     implicitIndicatorHeight + topPadding + bottomPadding)
            leftPadding: background.radius
            rightPadding: background.radius
            highlighted: ListView.isCurrentItem

            contentItem: Column {
                width: parent.width

                Row {
                    spacing: 4
                    ResponsiveImage {
                        anchors.verticalCenter: parent.verticalCenter
                        containerWidth: JamiTheme.iconButtonSmall * 1.5
                        containerHeight: JamiTheme.iconButtonSmall * 1.5
                        source: JamiResources.edit_24dp_svg
                        color: JamiTheme.buttonTintedGreyHovered
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: MessagesAdapter.getFormattedTime(modelData.timestamp)
                        color: JamiTheme.textColor
                    }

                    NewIconButton {
                        id: expandButton
                        anchors.verticalCenter: parent.verticalCenter

                        iconSize: JamiTheme.iconButtonSmall
                        iconSource: messageContainer.expanded ? JamiResources.expand_less_24dp_svg : JamiResources.expand_more_24dp_svg
                        toolTipText: messageContainer.expanded ? JamiStrings.showLess : JamiStrings.showMore

                        visible: messageContainer.hasOverflow

                        onClicked: messageContainer.expanded = !messageContainer.expanded
                    }
                }

                Item {
                    id: messageContainer

                    property bool expanded: false
                    property string displayText: {
                        const displayBody = (root.showOriginal && modelData.originalBody !== "") ? modelData.originalBody : modelData.body;
                        const messageBody = displayBody === "" ? JamiStrings.deletedMessage.arg(UtilsAdapter.getBestNameForUri(CurrentAccount.id, modelData.author)) : displayBody;
                        return messageBody.replace(/(`{1,3}[\s\S]*?`{1,3})|(\r?\n)/g, function(match, codeBlock) {
                            return codeBlock === undefined ? "<br/>" : codeBlock;
                        });
                    }
                    property bool hasOverflow: messageMeasure.contentWidth > width
                                               || messageMeasure.lineCount > 1
                                               || displayText.indexOf("<br/>") !== -1
                    property real collapsedPreviewHeight: hasOverflow ? messageFontMetrics.height * 1.5 : messageFontMetrics.height

                    width: parent.width
                    height: messageText.height
                    implicitHeight: height

                    TextEdit {
                        id: messageText

                        width: parent.width
                        height: messageContainer.expanded ? implicitHeight : messageContainer.collapsedPreviewHeight

                        readOnly: true
                        clip: true
                        wrapMode: TextEdit.WrapAtWordBoundaryOrAnywhere
                        textFormat: TextEdit.MarkdownText
                        text: messageContainer.displayText
                        color: JamiTheme.textColor
                    }

                    Rectangle {
                        anchors.left: messageText.left
                        anchors.right: messageText.right
                        anchors.bottom: messageText.bottom

                        height: messageFontMetrics.height / 2
                        visible: messageContainer.hasOverflow && !messageContainer.expanded

                        gradient: Gradient {
                            GradientStop {
                                position: 0.0
                                color: Qt.rgba(JamiTheme.globalBackgroundColor.r,
                                               JamiTheme.globalBackgroundColor.g,
                                               JamiTheme.globalBackgroundColor.b,
                                               0.25)
                            }
                            GradientStop {
                                position: 1.0
                                color: Qt.rgba(JamiTheme.globalBackgroundColor.r,
                                               JamiTheme.globalBackgroundColor.g,
                                               JamiTheme.globalBackgroundColor.b,
                                               0.85)
                            }
                        }
                    }

                    FontMetrics {
                        id: messageFontMetrics

                        font: messageText.font
                    }

                    TextEdit {
                        id: messageMeasure

                        visible: false
                        readOnly: true
                        wrapMode: TextEdit.NoWrap
                        textFormat: TextEdit.MarkdownText
                        text: messageContainer.displayText
                        font: messageText.font
                    }
                }
            }

            background: Rectangle {
                radius: 21
                color: JamiTheme.globalBackgroundColor
            }
        }
    }
}
