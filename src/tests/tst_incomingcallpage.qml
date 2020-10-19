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

    IncomingCallPage {
        id: uut
    }

    TestCase {
        id: incomingCallPageTests
        name: "incomingCallPageTests"
        when: windowShown

        SignalSpy {
            id: callAcceptBtn_Spy
            target: uut
            signalName: "callAcceptButtonIsClicked"
        }

        SignalSpy {
            id: callDeclineBtn_Spy
            target: uut
            signalName: "callCancelButtonIsClicked"
        }

        function test_incomingCallButtons() {
            var callAnswerBtn = findChild(uut, "callAnswerButton")
            callAcceptBtn_Spy.clear()
            compare(callAcceptBtn_Spy.count, 0)
            mouseClick(callAnswerBtn)
            compare(callAcceptBtn_Spy.count, 1)

            var callDeclineBtn = findChild(uut, "callDeclineButton")
            callDeclineBtn_Spy.clear()
            compare(callDeclineBtn_Spy.count, 0)
            mouseClick(callDeclineBtn)
            compare(callDeclineBtn_Spy.count, 1)
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

        function test_shortcuts() {
            keySequence("Ctrl+Shift+D")
        }
    }
}
