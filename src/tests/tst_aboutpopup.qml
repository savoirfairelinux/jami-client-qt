import QtQuick 2.4
import QtTest 1.0
import QtQuick.Controls 2.15

import "../mainview/components"
import "../commoncomponents"

Item {
    id: root

    AboutPopUp {
        id: uut
        visible: true
        height: 800
        width: 400

        TestCase {
            id: aboutPopUpTests
            name: "aboutPopUpTests"
            when: windowShown

            function test_changeLogButton() {
                var changeLogBtn = findChild(uut, "changeLogButton")
                var creditsBtn = findChild(uut, "creditsButton")
                var changeLogOrCreditsStack = findChild(uut, "changeLogOrCreditsStack")

                mouseClick(changeLogBtn)
                compare(changeLogOrCreditsStack.currentItem.objectName, "changeLogScrollView")
                mouseClick(creditsBtn)
                compare(changeLogOrCreditsStack.currentItem.objectName, "projectCreditsScrollView")
            }

            // TODO: Does not work
            /*
            SignalSpy {
                id: closeButton_Spy
                target: uut
                signalName: "closed"
            }

            ^function test_closeButton() {
                var closeButton = findChild(uut, "closeButton")
                closeButton_Spy.clear()
                mouseClick(closeButton)
                compare(closeButton_Spy.count, 1)
            }*/
        }
    }
}
