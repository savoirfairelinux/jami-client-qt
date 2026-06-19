import QtQuick
import QtTest

import net.jami.Adapters 1.1
import net.jami.Constants 1.1

import "../../../src/app/settingsview/components"

Item {
    width: 600
    height: 200

    Component {
        id: deviceDelegate

        DeviceItemDelegate {
            width: 600
            height: implicitHeight
            deviceName: "Linked device"
            deviceId: "device-id"
        }
    }

    Component {
        id: linkedDevices

        LinkedDevicesBase {
            width: 600
            height: implicitHeight
        }
    }

    Component {
        id: deviceModel

        ListModel {}
    }

    TestCase {
        name: "DeviceItemDelegate"
        when: windowShown

        function test_lastSync_data() {
            return [
                { tag: "never synced", lastSync: 0, isCurrent: false, visible: true },
                { tag: "synced", lastSync: 1700000000, isCurrent: false, visible: true },
                { tag: "current device", lastSync: 0, isCurrent: true, visible: false }
            ];
        }

        function test_lastSync(data) {
            const delegate = createTemporaryObject(deviceDelegate, parent, {
                lastSync: data.lastSync,
                isCurrent: data.isCurrent
            });
            verify(delegate);

            const label = findChild(delegate, "labelLastSync");
            verify(label);
            compare(label.visible, data.visible);
            if (!data.isCurrent) {
                const timestamp = data.lastSync === 0 ? JamiStrings.neverSynced : UtilsAdapter.formatTimestamp(data.lastSync);
                compare(label.text, JamiStrings.lastSync.arg(timestamp));
                waitForRendering(delegate);
                const position = label.mapToItem(delegate, 0, 0);
                verify(position.y >= 0);
                verify(position.y + label.height <= delegate.height);
            }
        }

        function test_listHeight() {
            const devices = createTemporaryObject(linkedDevices, parent);
            verify(devices);
            const list = findChild(devices, "settingsListView");
            verify(list);
            const model = createTemporaryObject(deviceModel, devices);
            verify(model);
            list.model = model;
            tryCompare(list, "height", 0);

            for (let count = 1; count <= 4; ++count) {
                model.append({ DeviceName: "Linked device", DeviceID: "device-" + count, LastSync: 0 });
                tryCompare(list, "count", count);
                waitForRendering(devices);
                const delegate = list.itemAtIndex(0);
                verify(delegate);
                const expectedHeight = Math.min(count, 3) * (delegate.height + list.spacing);
                tryCompare(list, "height", expectedHeight);
            }
        }
    }
}
