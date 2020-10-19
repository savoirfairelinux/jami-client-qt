import QtQuick 2.4
import QtTest 1.0
import QtQuick.Controls 2.15

import "../mainview/components"
import "../commoncomponents"

Item {
    id: root

    width: 800
    height: 600

    visible: true

    UserProfile {
        id: uut
        visible: true

        TestCase {
            id: userProfileTests
            name: "userProfileTests"
            when: windowShown

            SignalSpy {
                id: closeBtn_Spy
                target: uut
                signalName: "closed"
            }

            function test_closeButton() {
                var closeButton = findChild(uut, "userProfileBtnClose")
                closeBtn_Spy.clear()
                mouseClick(closeButton)
                verify(!uut.visible)
            }

            function test_information() {
                var contactQrImage = findChild(uut, "contactQrImage")
                var contactAlias = findChild(uut, "contactAlias")
                var contactDisplayName = findChild(uut, "contactDisplayName")
                var contactId = findChild(uut, "contactId")

                uut.responsibleConvUid = "fakeConvUid"
                uut.contactPicBase64 = ""
                uut.aliasText = "fakeAlias"
                uut.registeredNameText = "fakeRegisteredName"
                uut.idText = "fakeId"

                compare(contactQrImage.source.toString(), "image://qrimage/contact_fakeConvUid")
                compare(contactAlias.text, "fakeAlias")
                compare(contactDisplayName.text, "fakeRegisteredName")
                compare(contactId.text, "fakeId")
            }
        }
    }
}
