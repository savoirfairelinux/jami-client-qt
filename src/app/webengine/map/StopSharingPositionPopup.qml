/*
 * Copyright (C) 2022-2023 Savoir-faire Linux Inc.
 * Author: Nicolas Vengeon <nicolas.vengeon@savoirfairelinux.com>
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
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"

BaseModalDialog {
    id: root

    width: popupContent.width
    height: popupContent.height

    title: JamiStrings.stopSharingPopupBody

    button1.text: JamiStrings.stopConvSharing.arg(PositionManager.getmapTitle(attachedAccountId, CurrentConversation.id))
    button2.text: JamiStrings.stopAllSharings
    button2.contentColorProvider: JamiTheme.deleteButtonRed

    button1Clicked: function() {
        PositionManager.stopSharingPosition(attachedAccountId, CurrentConversation.id);
        root.close();
    }
    button2Clicked: function() {
        PositionManager.stopSharingPosition();
        root.close();
    }

    signal joinClicked
 }


