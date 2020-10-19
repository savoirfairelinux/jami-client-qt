import QtQuick 2.14
import QtTest 1.0
import net.jami.Models 1.0
import net.jami.Adapters 1.0
import QtQuick.Controls 2.14

import "../../src/mainview/components"
import "../../src/commoncomponents"

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
        // TODO: Problems updateUI -> UtilsAdapter -> LRCInstance
        function test_callStack() {
            var callStackMainView = findChild(uut, "callStackMainView")

            uut.responsibleAccountId = "a"
            uut.responsibleConvUid = "b"

            uut.showOutgoingCallPage("a", "b")
            compare(callStackMainView.currentItem.stackNumber, CallStackView.OutgoingPageStack)
        }

        // OutgoingCallStatus
        function test_outgoingStatus() {
            var outgoingCallPage = findChild(uut, "outgoingCallPage")
            var callStatusText = findChild(outgoingCallPage, "callStatusText")
            uut.responsibleAccountId = "a"
            uut.responsibleConvUid = "b"
            callStatusChanged_Spy.clear()
            CallAdapter.callStatusChanged(Call.Status.SEARCHING, "a", "b")
            compare(callStatusText.text, "Searching...")
            compare(callStatusChanged_Spy.count, 1)
            CallAdapter.callStatusChanged(Call.Status.IN_PROGRESS, "a", "b")
            compare(callStatusText.text, "Talking...")
            compare(callStatusChanged_Spy.count, 2)
            CallAdapter.callStatusChanged(Call.Status.TIMEOUT, "a", "b")
            compare(callStatusText.text, "Timeout...")
            compare(callStatusChanged_Spy.count, 3)
        }
    }
//    }
}
