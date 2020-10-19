import QtQuick 2.4
import QtTest 1.0
import net.jami.Models 1.0
import net.jami.Adapters 1.0
import QtQuick.Controls 2.15

import "../mainview/components"
import "../commoncomponents"


SidePanel {
    id: uut
    visible: true

    TestCase {
        name: "SidePanelTests"
        when: windowShown

        property Item lblSearchStatus: findChild(uut, "lblSearchStatus")
        property Item searchStatusRect: findChild(uut, "searchStatusRect")
        property Item sidePanelTabBar: findChild(uut, "sidePanelTabBar")
        property Item tabConversations: findChild(sidePanelTabBar, "mouseAreaTabConversations")
        property Item tabRequests: findChild(sidePanelTabBar, "mouseAreaTabRequests")
        property Item tabOne: findChild(sidePanelTabBar, "tabOne")
        property Item searchBar: findChild(uut, "contactSearchBar")
        property Item searchBarTextField: findChild(searchBar, "contactSearchBarTextField")


        SignalSpy {
            id: returnPressed_Spy
            target: searchBar
            signalName: "returnPressedWhileSearching"
        }


        // Search bar functionalities

        SignalSpy {
            id: searchBarTextChanged_Spy
            target: searchBar
            signalName: "contactSearchBarTextChanged"
        }

        function test_searchBarChanged() {
            searchBarTextChanged_Spy.clear()
            searchBarTextField.text = "hola"
            console.error(searchBarTextChanged_Spy.count())
        }

        function test_searchBar() {
            compare(lblSearchStatus.text, "")
            verify(!searchStatusRect.visible)
            ConversationsAdapter.showSearchStatus("username")
            compare(lblSearchStatus.text, "username")
            verify(searchStatusRect.visible)
            uut.clearContactSearchBar()
            compare(lblSearchStatus.text, "")
        }

        function test_tabBar() {
            //filterChanged_Spy.clear()
            //compare(ConversationsAdapter.currentTypeFilter, 0)
            sidePanelTabBar.visible = true
            tabBarVisible = true
            mouseClick(tabRequests)
            mouseClick(tabConversations)

            compare(ConversationsAdapter.currentTypeFilter, Profile.Type.PENDING)
            //compare(filterChanged_Spy.count, 1)
            //mouseClick(tabConversations)
            //compare(ConversationsAdapter.currentTypeFilter, Profile.Type.RING)
            //compare(filterChanged_Spy.count, 2)

        }
    }
}
