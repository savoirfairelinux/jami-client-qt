import QtQuick 2.14
import QtTest 1.0
import QtQuick.Controls 2.14

import "../../src/mainview/components"
import "../../src/commoncomponents"

Item {
    id: root
    width: 800
    height: 600

    visible: true

    AboutPopUp {
        id: uut
        visible: true
        height: 800
        width: 600

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
        }
    }
}
