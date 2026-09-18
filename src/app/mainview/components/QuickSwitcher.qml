/*
 * Copyright (C) 2026 Savoir-faire Linux Inc.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <https://www.gnu.org/licenses/>.
 */

import QtQuick
import QtQuick.Controls
import QtQuick.Controls.impl
import QtQuick.Effects
import QtQuick.Layouts
import net.jami.Constants 1.1
import "../../commoncomponents"

Popup {
    id: root

    signal conversationActivated(string uid, string accountId, string peerUri)
    signal settingActivated(int index)

    readonly property int resultCount: resultsModel.count
    readonly property int selectedIndex: resultsList.currentIndex

    parent: Overlay.overlay
    anchors.centerIn: parent
    width: Math.min(640, parent ? parent.width - 40 : 640)
    height: Math.min(460, contentLayout.implicitHeight + 32)
    padding: 16
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    function settingAliases(index) {
        switch (index) {
        case 0: return "accounts identity username password export";
        case 1: return "profile avatar display name";
        case 2: return "devices link pairing";
        case 3: return "calls ringtone forwarding voicemail";
        case 4: return "privacy security encryption network proxy dht";
        case 5: return "permissions access bots";
        case 6: return "services integrations";
        case 7: return "general notifications startup language spellcheck api";
        case 8: return "theme colors font zoom";
        case 9: return "messages messaging links typing";
        case 10: return "map position";
        case 11: return "recording calls";
        case 12: return "logs diagnostics connectivity";
        case 13: return "update version";
        case 14: return "microphone speaker sound media";
        case 15: return "camera media";
        case 16: return "display monitor media";
        case 17: return "plugins extensions";
        default: return "";
        }
    }

    function matchToken(value, token) {
        const text = String(value || "").toLocaleLowerCase();
        if (text === token)
            return 0;
        if (text.startsWith(token))
            return 10;
        const words = text.split(/\s+/);
        for (let word of words) {
            if (word.startsWith(token))
                return 20;
        }
        return text.includes(token) ? 30 : -1;
    }

    function matchScore(item, query) {
        const normalized = query.trim().toLocaleLowerCase();
        if (!normalized)
            return 0;

        let total = 0;
        const tokens = normalized.split(/\s+/);
        for (let token of tokens) {
            let best = matchToken(item.title, token);
            for (let term of item.searchTerms) {
                const score = matchToken(term, token);
                if (score >= 0 && (best < 0 || score + 5 < best))
                    best = score + 5;
            }
            if (best < 0)
                return -1;
            total += best;
        }
        return total;
    }

    function rebuildResults() {
        const matches = [];
        for (let item of sourceItems) {
            const score = matchScore(item, searchBar.textContent);
            if (score >= 0)
                matches.push(Object.assign({}, item, { score: score }));
        }
        matches.sort(function(left, right) {
            if (left.score !== right.score)
                return left.score - right.score;
            if (left.timestamp !== right.timestamp)
                return right.timestamp - left.timestamp;
            return left.order - right.order;
        });

        const targetCount = Math.min(matches.length, 12);
        for (let i = 0; i < targetCount; ++i) {
            if (i < resultsModel.count)
                resultsModel.set(i, matches[i]);
            else
                resultsModel.append(matches[i]);
        }
        while (resultsModel.count > targetCount)
            resultsModel.remove(resultsModel.count - 1);
        resultsList.currentIndex = resultsModel.count ? 0 : -1;
    }

    function openSwitcher(conversations, settingGroups) {
        sourceItems = [];
        let order = 0;
        for (let conversation of conversations) {
            sourceItems.push({
                accountId: conversation.accountId,
                iconSource: conversation.isContact ? JamiResources.chat_24dp_svg
                                                   : JamiResources.groups_3_24dp_svg,
                kind: conversation.isContact ? JamiStrings.contact
                                             : JamiStrings.conversation,
                order: order++,
                peerUri: conversation.peerUri || "",
                searchTerms: conversation.searchTerms || [],
                settingIndex: -1,
                subtitle: conversation.subtitle || "",
                timestamp: Number(conversation.timestamp) || 0,
                title: conversation.title,
                uid: conversation.uid
            });
        }
        for (let group of settingGroups) {
            for (let setting of group.children) {
                if (setting.visible === false)
                    continue;
                sourceItems.push({
                    accountId: "",
                    iconSource: JamiResources.settings_24dp_svg,
                    kind: JamiStrings.settings,
                    order: order++,
                    searchTerms: [group.title, settingAliases(setting.id)],
                    settingIndex: setting.id,
                    subtitle: group.title,
                    timestamp: 0,
                    title: setting.title,
                    uid: ""
                });
            }
        }
        searchBar.clearText();
        rebuildResults();
        open();
    }

    function resultAt(index) {
        return resultsModel.get(index);
    }

    function activate(index) {
        if (index < 0 || index >= resultsModel.count)
            return;
        const item = resultsModel.get(index);
        const settingIndex = item.settingIndex;
        const uid = item.uid;
        const accountId = item.accountId;
        close();
        if (settingIndex >= 0)
            settingActivated(settingIndex);
        else
            conversationActivated(uid, accountId, item.peerUri || "");
    }

    property var sourceItems: []

    onOpened: searchBar.setTextAreaFocus()
    onClosed: searchBar.clearText()

    background: Rectangle {
        color: JamiTheme.globalIslandColor
        radius: JamiTheme.avatarBasedRadius
        border.width: 1
        border.color: JamiTheme.smartListHoveredColor

        layer.enabled: true
        layer.effect: MultiEffect {
            autoPaddingEnabled: true
            shadowEnabled: true
            shadowBlur: JamiTheme.shadowBlur
            shadowColor: JamiTheme.shadowColor
            shadowHorizontalOffset: JamiTheme.shadowHorizontalOffset
            shadowVerticalOffset: JamiTheme.shadowVerticalOffset
            shadowOpacity: JamiTheme.shadowOpacity
        }
    }

    contentItem: ColumnLayout {
        id: contentLayout
        spacing: 12

        Searchbar {
            id: searchBar

            Layout.fillWidth: true
            Layout.preferredHeight: JamiTheme.searchBarPreferredHeight
            placeHolderText: JamiStrings.quickSwitcherPlaceholder

            onSearchBarTextChanged: function(text) {
                root.rebuildResults();
            }

            textField.objectName: "quickSwitcherSearch"
            textField.Keys.onPressed: function(event) {
                if (event.key === Qt.Key_Down) {
                    resultsList.currentIndex = Math.min(resultsList.currentIndex + 1,
                                                        resultsModel.count - 1);
                    event.accepted = true;
                } else if (event.key === Qt.Key_Up) {
                    resultsList.currentIndex = Math.max(resultsList.currentIndex - 1, 0);
                    event.accepted = true;
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    root.activate(resultsList.currentIndex);
                    event.accepted = true;
                } else if (event.key === Qt.Key_Escape) {
                    root.close();
                    event.accepted = true;
                }
            }
        }

        JamiListView {
            id: resultsList
            objectName: "quickSwitcherResults"

            Layout.fillWidth: true
            Layout.rightMargin: -12
            Layout.preferredHeight: Math.min(contentHeight, 360)
            clip: true
            model: ListModel {
                id: resultsModel
            }
            currentIndex: count ? 0 : -1

            Binding {
                target: resultsList.verticalScrollBar
                property: "rightPadding"
                value: 0
            }

            delegate: ItemDelegate {
                id: resultDelegate
                objectName: "quickSwitcherResult-" + index

                required property int index
                required property string iconSource
                required property string kind
                required property string subtitle
                required property string title

                width: resultsList.width
                height: 56
                highlighted: ListView.isCurrentItem
                hoverEnabled: true

                leftPadding: contentRect.anchors.leftMargin + contentRect.radius - 8
                rightPadding: contentRect.anchors.rightMargin + contentRect.radius - 8

                onHoveredChanged: {
                    if (hovered)
                        resultsList.currentIndex = index;
                }
                onClicked: root.activate(index)

                background: Rectangle {
                    id: contentRect

                    anchors.fill: parent
                    anchors.topMargin: JamiTheme.itemMarginVertical
                    anchors.bottomMargin: JamiTheme.itemMarginVertical
                    anchors.leftMargin: 0
                    anchors.rightMargin: 12

                    radius: JamiTheme.avatarBasedRadius

                    color: resultDelegate.highlighted
                           ? JamiTheme.smartListSelectedColor
                           : (resultDelegate.hovered
                              ? JamiTheme.smartListHoveredColor
                              : JamiTheme.transparentColor)
                }

                contentItem: RowLayout {
                    spacing: 12

                    IconImage {
                        source: resultDelegate.iconSource
                        sourceSize.width: 24
                        sourceSize.height: 24
                        color: JamiTheme.textColor
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        Label {
                            Layout.fillWidth: true
                            text: resultDelegate.title
                            color: JamiTheme.textColor
                            elide: Text.ElideRight
                            font.weight: Font.DemiBold
                        }
                        Label {
                            Layout.fillWidth: true
                            visible: text.length > 0
                            text: resultDelegate.subtitle
                            color: JamiTheme.placeholderTextColor
                            elide: Text.ElideRight
                            font.pointSize: JamiTheme.smallFontSize
                        }
                    }

                    Label {
                        text: resultDelegate.kind
                        color: JamiTheme.placeholderTextColor
                        font.pointSize: JamiTheme.smallFontSize
                    }
                }
            }
        }

        Label {
            Layout.fillWidth: true
            visible: resultsModel.count === 0
            text: JamiStrings.searchResults + ": 0"
            color: JamiTheme.placeholderTextColor
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
