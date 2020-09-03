/*
 * Copyright (C) 2020 by Savoir-faire Linux
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

import QtQuick 2.14
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.14

import "../../constant"
import "../../commoncomponents"

Row {
    id: root

    property int stages: 0
    property int currentStage: 0

    Repeater {
        model: stages

        Rectangle {
            color: {
                if (modelData === currentStage - 1)
                    return JamiTheme.accountCreationCurrentStageColor
                return JamiTheme.accountCreationPassedStageColor
            }
            radius: height / 2
            implicitHeight: 12
            implicitWidth: 12
        }
    }
}
