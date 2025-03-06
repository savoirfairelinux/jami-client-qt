/*
 * Copyright (C) 2020-2025 Savoir-faire Linux Inc.
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
import Qt.labs.platform
import net.jami.Constants 1.1

FileDialog {
    id: root

    // Use enum to avoid importing Qt.labs.platform when using JamiFileDialog.
    property int mode: JamiFileDialog.Mode.OpenFile

    signal fileAccepted(string file)
    signal filesAccepted(var files)

    Component.onCompleted: {
        JamiQmlUtils.openFileDialogCount++;
        console.warn("JamiFileDialog count: " << JamiQmlUtils.openFileDialogCount);
    }

    Component.onDestruction: {
        JamiQmlUtils.openFileDialogCount--;
        console.warn("JamiFileDialog count: " << JamiQmlUtils.openFileDialogCount);
    }

    onAccepted: {
        switch (fileMode) {
        case FileDialog.OpenFile:
            fileAccepted(file);
            break;
        case FileDialog.OpenFiles:
            filesAccepted(files);
            break;
        default:
            fileAccepted(file);
        }
    }

    enum Mode {
        OpenFile,
        OpenFiles,
        SaveFile
    }

    title: JamiStrings.selectFile

    onModeChanged: {
        switch (mode) {
        case JamiFileDialog.Mode.OpenFile:
            root.fileMode = FileDialog.OpenFile;
            break;
        case JamiFileDialog.Mode.OpenFiles:
            root.fileMode = FileDialog.OpenFiles;
            break;
        default:
            root.fileMode = FileDialog.SaveFile;
        }
    }
}
