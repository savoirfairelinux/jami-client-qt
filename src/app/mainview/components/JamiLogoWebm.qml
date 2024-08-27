/*
 * Copyright (C) 2020-2024 Savoir-faire Linux Inc.
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
import QtQuick.Layouts
import QtMultimedia
import Qt5Compat.GraphicalEffects
import net.jami.Constants 1.1
import net.jami.Adapters 1.1


Item {
    id: jamiLogo

    Layout.alignment: Qt.AlignCenter | Qt.AlignTop
    Layout.preferredWidth: JamiTheme.welcomeLogoWidth
    Layout.preferredHeight: JamiTheme.welcomeLogoHeight

    Loader {
        id: videoPlayer

        property var mediaInfo: UtilsAdapter.getVideoPlayer(JamiTheme.darkTheme ? JamiResources.logo_dark_webm : JamiResources.logo_light_webm, JamiTheme.secondaryBackgroundColor)
        anchors.fill: parent
        anchors.margins: 2
        sourceComponent: WITH_WEBENGINE ? avMediaComp : basicPlayer

        Component {
            id: avMediaComp
            Loader {
                Component.onCompleted: {
                    var qml = "qrc:/webengine/VideoPreview.qml";
                    setSource(qml, {
                            "isVideo": mediaInfo.isVideo,
                            "html": mediaInfo.html
                        });
                }
            }
        }

        Component {
            id: basicPlayer

            Item {
                // NOTE: Seems to crash on snap for whatever reason. For now use VideoPreview in priority
                MediaPlayer {
                    id: mediaPlayer
                    source: JamiTheme.darkTheme ? JamiResources.logo_dark_webm : JamiResources.logo_light_webm
                    videoOutput: videoOutput
                    loops: MediaPlayer.Infinite
                }

                VideoOutput {
                    id: videoOutput
                    anchors.fill: parent
                }

                Component.onCompleted: {
                    mediaPlayer.play();
                }
            }
        }
    }
}
