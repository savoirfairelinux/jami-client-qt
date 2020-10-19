import QtQuick 2.4
import QtTest 1.0
import net.jami.Models 1.0
import net.jami.Adapters 1.0
import QtQuick.Controls 2.15

import "../mainview/components"
import "../commoncomponents"

CallStackView {
    id: uut
    visible: true

    TestCase {
        id: callStackViewTests
        name: "callStackViewTests"
        when: windowShown

        SignalSpy {
            id: callStatusChanged_Spy
            target: CallAdapter
            signalName: "callStatusChanged"
        }

        // Test stack order
        function test_callStack() {
            var callStackMainView = findChild(uut, "callStackMainView")

            // stackNumbers
            // Show audio, video, outgoing, incoming pages

            //callStackView.setLinkedWebview(communicationPageMessageWebView)
            uut.responsibleAccountId = "a"
            uut.responsibleConvUid = "b"
            //uut.updateCorrespondingUI()

            //uut.showIncomingCallPage("a", "b")
            //compare(callStackMainView.currentItem.stackNumber, CallStackView.IncomingPageStack)
            //uut.showOutgoingCallPage("a", "b")
            //compare(callStackMainView.currentItem.stackNumber, CallStackView.OutgoingPageStack)

        }

        // Update corresponding UI
        function test_updateUI() {
            // TODO: fake Adapters?
            //uut.updateUI("")
        }


        // Fake Call Adapter?
        function test_callAdapter() {
            var outgoingCallPage = findChild(uut, "outgoingCallPage")
            var callStatusText = findChild(outgoingCallPage, "callStatusText")
            uut.responsibleAccountId = "a"
            uut.responsibleConvUid = "b"
            callStatusChanged_Spy.clear()
            CallAdapter.callStatusChanged(4, "a", "b")
            compare(callStatusText.text, "Searching...")
            compare(callStatusChanged_Spy.count, 1)
        }
    }
//    }
}
