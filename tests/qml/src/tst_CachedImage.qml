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
import QtQuick.Controls
import QtQuick.Layouts

import QtTest

import net.jami.Adapters 1.1
import net.jami.Models 1.1
import net.jami.Constants 1.1
import net.jami.Enums 1.1
import net.jami.Helpers 1.1

import "../../../src/app/"
import "../../../src/app/mainview/components"

Item {

    width: 800
    height: 600

    CachedImage {
        id: cachedImage

        TestCase {
            name: "Test cachedImage"
            when: windowShown

            SignalSpy {
                id: spyDownloadSuccessful
                target: ImageDownloader
                signalName: "onDownloadImageSuccessful"
            }

            SignalSpy {
                id: spyDownloadFailed
                target: ImageDownloader
                signalName: "onDownloadImageFailed"
            }

            function test_goodDownLoad() {

                var localPath = UtilsAdapter.getStandardTempLocation()+"/"+Math.random().toString(36).substring(7)+".svg"

                cachedImage.localPath = localPath
                cachedImage.downloadUrl= "File://"+UtilsAdapter.createDummyImage()

                spyDownloadSuccessful.wait()

                compare(findChild(cachedImage,"image").source, Qt.url("file://"+localPath), "image source")

            }

            function test_failedDownLoad() {
                var imageUrl = "File:///dummy"

                var localPath = UtilsAdapter.getStandardTempLocation()+"/"+Math.random().toString(36).substring(7)+".svg"

                cachedImage.localPath = localPath
                cachedImage.downloadUrl= imageUrl

                spyDownloadFailed.wait()

                compare(findChild(cachedImage,"image").source,cachedImage.defaultImage, "image source")
            }
        }
    }
}
