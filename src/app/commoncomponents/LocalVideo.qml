/*
 * Copyright (C) 2022-2023 Savoir-faire Linux Inc.
 * Author: Andreas Traczyk <andreas.traczyk@savoirfairelinux.com>
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
import QtMultimedia
import Qt5Compat.GraphicalEffects
import net.jami.Adapters 1.1

VideoView {
    id: root

    crop: true

    function startWithId(id, force = false) {
        if (id !== undefined && id.length === 0) {
            VideoDevices.stopDevice(rendererId);
            rendererId = id;
        } else {
            const forceRestart = rendererId === id;
            if (!forceRestart) {
                // Stop previous device
                VideoDevices.stopDevice(rendererId);
            }
            rendererId = VideoDevices.startDevice(id, forceRestart);
        }
    }
}
