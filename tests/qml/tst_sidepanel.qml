import QtQuick 2.14
import QtTest 1.0
import net.jami.Models 1.0
import net.jami.Adapters 1.0
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.14

import "../../src/mainview/components"
import "../../src/commoncomponents"


SidePanel {
   id: uut
    visible: true

    ContactSearchBar {
        id: contactSearchBar
    }
    //property Item contactSearchBar: findChild(uut, "contactSearchBar")

    SidePanelTabBar {
        id: sidePanelTabBar
    }

    TestCase {
        name: "sidePanelTests"
        when: windowShown


        property Item lblSearchStatus: findChild(uut, "lblSearchStatus")
        property Item searchStatusRect: findChild(uut, "searchStatusRect")
        //property Item sidePanelTabBar: findChild(uut, "sidePanelTabBar")

        property Item tabConversations: findChild(sidePanelTabBar, "mouseAreaTabConversations")
        property Item tabRequests: findChild(sidePanelTabBar, "mouseAreaTabRequests")
        property Item tabOne: findChild(sidePanelTabBar, "tabOne")
        property Item searchBarTextField: findChild(contactSearchBar, "contactSearchBarTextField")

        // Search bar functionalities
        SignalSpy {
            id: searchBarTextChanged_Spy
            target: contactSearchBar
            signalName: "contactSearchBarTextChanged"
        }

        function test_searchBarChanged() {
            searchBarTextChanged_Spy.clear()
            searchBarTextField.text = "tes"
            searchBarTextField.text = "test"
            compare(searchBarTextChanged_Spy.count, 2)
            contactSearchBar.clearText()
            compare(searchBarTextChanged_Spy.count, 3)
        }

        function test_searchStatus() {
            compare(lblSearchStatus.text, "")
            verify(!searchStatusRect.visible)
            ConversationsAdapter.showSearchStatus("username")
            compare(lblSearchStatus.text, "username")
            verify(searchStatusRect.visible)
        }
    }
}
