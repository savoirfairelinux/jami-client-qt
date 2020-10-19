import QtQuick 2.4
import QtTest 1.0
import net.jami.Models 1.0
import net.jami.Adapters 1.0
import QtQuick.Controls 2.15

import "../mainview/components"
import "../commoncomponents"

Item {
    id: root
    visible: true
    height: 800
    width: 600

    // Fake mainViewWindow for userInfoCallPage
    Item {
        id: mainViewWindow
        function showWelcomeView() {
            showWelcomeViewRequested = true
        }
        property bool showWelcomeViewRequested: false
        property bool sidePanelOnly: false
    }

    OutgoingCallPage {
        id: uut

        TestCase {
            id: outgoingCallPageTests
            name: "outgoingCallPageTests"
            when: windowShown

            SignalSpy {
                id: callCancelBtn_Spy
                target: uut
                signalName: "callCancelButtonIsClicked"
            }

            function test_callCancellButton() {
                var callCancelBtn = findChild(uut, "callCancelButton")
                callCancelBtn_Spy.clear()
                mouseClick(callCancelBtn)
                compare(callCancelBtn_Spy.count, 1)
            }

            function test_CallStatusText() {
                var callStatusText = findChild(uut, "callStatusText")
                uut.callStatus = 4
                compare(callStatusText.text, "Searching...")
            }

            // UserInfoCallPage Tests
            function test_userInfoCallPageBackButton() {
                var backButton = findChild(uut, "backButton")
                verify(!backButton.visible)
                mainViewWindow.sidePanelOnly = true
                verify(backButton.visible)

                verify(!mainViewWindow.showWelcomeViewRequested)
                mouseClick(backButton)
                verify(mainViewWindow.showWelcomeViewRequested)
            }

            function test_updateUI() {
                // TODO: fake Adapters?
                //uut.updateUI("")
            }
        }
    }
}
