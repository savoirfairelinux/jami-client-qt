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

    //AudioCallPage {
    //    id: uut
    //}

    TestCase {
        id: audioCallPageTests
        name: "audioCallPageTests"
        when: windowShown

        //SignalSpy {
        //    id: callCancelBtn_Spy
        //    target: uut
        //    signalName: "callCancelButtonIsClicked"
        //}

        function test_callCancellButton() {
        }

        function test_CallStatusText() {
        }

        // UserInfoCallPage Tests
        function test_userInfoCallPageBackButton() {

        }

        function test_updateUI() {

        }
    }
}
