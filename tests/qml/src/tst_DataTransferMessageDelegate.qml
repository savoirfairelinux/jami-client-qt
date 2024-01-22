/*
 * Copyright (C) 2024 Savoir-faire Linux Inc.
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
import QtTest

import net.jami.Adapters 1.1
import net.jami.Models 1.1
import net.jami.Constants 1.1
import net.jami.Enums 1.1

import "../../../src/app/"
import "../../../src/app/mainview"
import "../../../src/app/mainview/components"
import "../../../src/app/commoncomponents"

DataTransferMessageDelegate {
    id: uut
    timestamp: 0
    transferStatus: Interaction.Status.TRANSFER_FINISHED
    author: ""
    body: ""

    TestCase {
        name: "Check basic visibility for header buttons"
        function test_checkBasicVisibility() {
            var buttonsLoader = findChild(uut, "buttonsLoader")
            uut.transferStatus = Interaction.Status.TRANSFER_AWAITING_HOST
            compare(buttonsLoader.iconSource, JamiResources.download_black_24dp_svg)
            uut.transferStatus = Interaction.Status.TRANSFER_FINISHED
            compare(buttonsLoader.iconSource, JamiResources.link_black_24dp_svg)
        }
    }
}