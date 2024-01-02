/*
 * Copyright (C) 2020-2024 Savoir-faire Linux Inc.
 * Author: Aline Gondim Santos  <aline.gondimsantos@savoirfairelinux.com>
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
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import net.jami.Adapters 1.1
import net.jami.Models 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"

SettingsPageBase {
    id: root
    title: JamiStrings.pluginSettingsTitle
    onWidthChanged: resolvePanes()
    flickableContent: RowLayout {
        width: parent.width
        anchors.left: parent.left
        anchors.leftMargin: JamiTheme.preferredSettingsMarginSize
        ColumnLayout {
            id: generalSettings
            Layout.maximumWidth: {
                let width = 0;
                if (JamiTheme.remotePluginDelegateWidth < JamiTheme.remotePluginMinimumDelegateWidth) {
                    width = 3 * (JamiTheme.remotePluginMinimumDelegateWidth + 20);
                } else if (JamiTheme.remotePluginDelegateWidth > JamiTheme.remotePluginMaximumDelegateWidth) {
                    width = 3 * (JamiTheme.remotePluginMaximumDelegateWidth + 20);
                } else {
                    width = 3 * (JamiTheme.remotePluginDelegateWidth + 20);
                }
                return pluginRemoteList.remotePluginHovered ? width + 10 : width;
            }
            Layout.minimumWidth: {
                let width = 0;
                if (JamiTheme.remotePluginDelegateWidth < JamiTheme.remotePluginMinimumDelegateWidth) {
                    width = JamiTheme.remotePluginMinimumDelegateWidth + 10;
                } else if (JamiTheme.remotePluginDelegateWidth > JamiTheme.remotePluginMaximumDelegateWidth) {
                    width = JamiTheme.remotePluginMaximumDelegateWidth + 10;
                } else {
                    width = JamiTheme.remotePluginDelegateWidth + 10;
                }
                return pluginRemoteList.remotePluginHovered ? width + 10 : width;
            }
            Layout.preferredWidth: parent.width
            Layout.rightMargin: 80
            spacing: JamiTheme.settingsBlockSpacing
            // View of installed plugins
            PluginListView {
                id: pluginList
                Layout.fillWidth: true
                Layout.rightMargin: 20
                Layout.preferredHeight: childrenRect.height
                Connections {
                    target: pluginPreferencesView
                    function onClosed() {
                        pluginList.currentIndex = -1;
                    }
                }
            }
            // View of available plugins in the store
            PluginStoreListView {
                id: pluginRemoteList
                Layout.alignment: Qt.AlignBottom | Qt.AlignHCenter
                Layout.fillWidth: true
            }
            InstallManuallyView {
                Layout.fillWidth: true
                spacing: 10
            }
        }
    }
    property real previousDetailsWidth: 500
    property real previousWidth: 500
    // This function governs the visibility of the plugin content and tracks the
    // the width of the SplitView and the details panel. This function should be
    // called when the width of the SplitView changes, when the SplitView is shown,
    // and when the details panel is shown. When called with force=true, it is being
    // called from a visibleChanged event, and we should not update the previous widths.
    function resolvePanes(force = false) {
        // If the details panel is not visible, then show the generalSettings.
        if (!pluginPreferencesView.visible) {
            pageContainer.visible = true;
            return;
        }
        // Next we compute whether the SplitView is expanding or shrinking.
        const isExpanding = width > previousWidth;
        //  width has a first bad state
        const preferencePreferredWidth = pluginPreferencesView.width === 0 ? 500 : pluginPreferencesView.width;
        // If the SplitView is not wide enough to show both the generalSettings
        // and the details panel, then hide the generalSettings.
        if (width < 522 + preferencePreferredWidth && (!isExpanding || force) && pageContainer.visible) {
            if (!force)
                previousDetailsWidth = pluginPreferencesView.width;
            pageContainer.visible = false;
        } else if (width >= JamiTheme.mainViewPaneMinWidth + previousDetailsWidth && (isExpanding || force) && !pageContainer.visible) {
            pageContainer.visible = true;
        }
        if (!force)
            previousWidth = width;
    }

    onResizingChanged: if (pageContainer.visible)
        pluginPreferencesView.previousWidth = pluginPreferencesView.width

    PluginPreferencesView {
        id: pluginPreferencesView
        SplitView.maximumWidth: root.width
        SplitView.minimumWidth: 500
        SplitView.preferredWidth: 500
        SplitView.fillHeight: true
        property int previousWidth: 500
        currentIndex: pluginList.currentIndex
        visible: pluginList.currentIndex != -1
        onVisibleChanged: root.resolvePanes(true)
    }
}
