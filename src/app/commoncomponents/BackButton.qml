/*
 * Copyright (C) 2021-2024 Savoir-faire Linux Inc.
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
import QtQuick
import QtQuick.Controls
import net.jami.Constants 1.1

PushButton {
    id: root

    normalColor: "transparent"
    imageColor: JamiTheme.buttonTintedBlue
    radius: 5

    preferredSize: JamiTheme.wizardViewPageBackButtonSize
    preferredWidth: JamiTheme.wizardViewPageBackButtonWidth
    preferredHeight: JamiTheme.wizardViewPageBackButtonHeight
    hoveredColor: JamiTheme.hoveredButtonColorWizard

    mirror: Qt.application.layoutDirection === Qt.RightToLeft

    source: JamiResources.ic_arrow_back_24dp_svg
    toolTipText: JamiStrings.back

    Keys.onPressed: function (keyEvent) {
        if (keyEvent.key === Qt.Key_Enter || keyEvent.key === Qt.Key_Return) {
            clicked();
            keyEvent.accepted = true;
        }
    }
}
