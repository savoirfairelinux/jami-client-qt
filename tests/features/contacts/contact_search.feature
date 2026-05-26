@contacts @search
Feature: Contact Search
  As a user of the Jami client
  I want to search for contacts by name or Jami ID
  So that I can quickly find and connect with people

  Background:
    Given the client is running
    And the user has an active Jami account
    And the contact list contains the following contacts:
      | display_name  | jami_id                                                                  |
      | Alice Smith   | aaaa1111bbbb2222cccc3333dddd4444eeee5555ffff6666aaaa1111bbbb2222cccc3333 |
      | Bob Jones     | bbbb2222cccc3333dddd4444eeee5555ffff6666aaaa1111bbbb2222cccc3333dddd4444 |
      | Carol White   | cccc3333dddd4444eeee5555ffff6666aaaa1111bbbb2222cccc3333dddd4444eeee5555 |
      | Dave Brown    | dddd4444eeee5555ffff6666aaaa1111bbbb2222cccc3333dddd4444eeee5555ffff6666 |

  # ─── Local Search ──────────────────────────────────────────────────────────

  @smoke
  Scenario: Search contacts by display name filters the local list
    When the user types "Alice" in the contact search field
    Then the contact list shows only contacts whose names contain "Alice"
    And "Alice Smith" appears in the search results
    And "Bob Jones" does not appear in the search results

  @smoke
  Scenario: Search contacts by Jami ID filters the local list
    When the user types "bbbb2222" in the contact search field
    Then the contact list shows only contacts whose Jami IDs contain "bbbb2222"
    And "Bob Jones" appears in the search results
    And "Alice Smith" does not appear in the search results

  @regression
  Scenario: Search is case-insensitive for display names
    When the user types "carol" in the contact search field
    Then "Carol White" appears in the search results
    And the result count is at least one

  @regression
  Scenario: Search with a partial name matches multiple contacts
    When the user types "o" in the contact search field
    Then "Bob Jones" appears in the search results
    And "Carol White" appears in the search results
    And "Dave Brown" appears in the search results

  # ─── Nameserver Lookup ─────────────────────────────────────────────────────

  @smoke
  Scenario: Search for a registered username queries the nameserver
    When the user types "frank_jami" in the contact search field
    And "frank_jami" does not match any local contact
    Then the client sends a lookup request to the nameserver for "frank_jami"

  @smoke
  Scenario: Nameserver lookup returns a result
    Given the nameserver can resolve "grace_jami" to a valid Jami ID
    When the user types "grace_jami" in the contact search field
    Then the client emits a "registeredNameFound" signal with status "success"
    And a search result for "grace_jami" appears below the local contacts
    And the result displays "grace_jami"'s Jami ID

  @smoke
  Scenario: Nameserver lookup returns no result
    Given the nameserver has no record for "unknown_handle"
    When the user types "unknown_handle" in the contact search field
    Then the client emits a "registeredNameFound" signal with status "not found"
    And no nameserver result is shown in the search list
    And the client displays a "no results found" indicator for the nameserver query

  @regression
  Scenario: Nameserver lookup failure is handled gracefully
    Given the nameserver is unreachable
    When the user types "someone" in the contact search field
    Then the client emits a "userSearchEnded" signal
    And the client displays a network error indicator for the nameserver query
    And the local contact list results are still shown correctly

  # ─── Live / Incremental Search ─────────────────────────────────────────────

  @regression
  Scenario: Search results update incrementally as the user types
    When the user types "A" in the contact search field
    Then the contact list is filtered to contacts matching "A"
    When the user appends "li" so the query becomes "Ali"
    Then the contact list is filtered further to contacts matching "Ali"
    And "Alice Smith" appears in the search results
    And "Bob Jones" does not appear in the search results

  # ─── Selecting a Search Result ─────────────────────────────────────────────

  @smoke
  Scenario: Select a local search result to view the contact
    Given the search results contain "Alice Smith"
    When the user selects "Alice Smith" from the search results
    Then the client displays the contact detail view for "Alice Smith"
    And the detail view shows "Alice Smith"'s Jami ID and avatar

  @smoke
  Scenario: Select a nameserver search result to initiate adding a contact
    Given the nameserver search returned a result for "grace_jami"
    When the user selects the "grace_jami" result
    Then the client presents the option to add "grace_jami" as a contact
    And the displayed Jami ID matches the one returned by the nameserver

  # ─── Clear Search ──────────────────────────────────────────────────────────

  @smoke
  Scenario: Clearing the search field restores the full contact list
    Given the user has typed "Alice" in the contact search field
    And the contact list is filtered to show only matching results
    When the user clears the search field
    Then all contacts are shown in the contact list
    And the contact list matches its state before the search began

  @smoke
  Scenario: Empty search string shows all contacts
    When the user focuses the contact search field without typing
    Then all contacts in the local list are displayed
    And no nameserver query is initiated

  # ─── Parameterised Local Search ────────────────────────────────────────────

  @regression
  Scenario Outline: Local search returns expected contacts for various queries
    When the user types "<query>" in the contact search field
    Then the search result count is "<match_count>"
    And the first result display name contains "<first_result>"

    Examples:
      | query    | match_count | first_result |
      | Alice    | 1           | Alice Smith  |
      | Bob      | 1           | Bob Jones    |
      | Dave     | 1           | Dave Brown   |
      | zzz      | 0           |              |
