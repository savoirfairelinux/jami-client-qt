@conversations
Feature: Conversation Filtering and Sorting
  As a user of the client
  I want to filter and sort my conversation list
  So that I can quickly find specific conversations

  Background:
    Given the client is running
    And the user is authenticated with a valid account
    And the user has the following conversations:
      | title          | type    | last_activity |
      | Alice          | 1:1     | 5 minutes ago |
      | Bob            | 1:1     | 2 hours ago   |
      | Project Room   | swarm   | 1 hour ago    |
      | Team Chat      | swarm   | 3 hours ago   |
    And the user has the following pending invitations:
      | title          | from    |
      | External Group | PeerX   |

  # ── Text Search ────────────────────────────────────────────────────────────

  @smoke
  Scenario: Filtering conversations by search text narrows the list
    When the user enters "Pro" in the conversation search field
    Then the conversation list contains only conversations matching "Pro"
    And "Project Room" is visible in the conversation list
    And "Alice" is not visible in the conversation list

  @smoke
  Scenario: Search matches a conversation title
    When the user enters "Team" in the conversation search field
    Then "Team Chat" is visible in the conversation list

  @smoke
  Scenario: Search matches a participant name in a 1:1 conversation
    When the user enters "Alice" in the conversation search field
    Then the conversation with "Alice" is visible in the conversation list

  @regression
  Scenario: Search with no matching results shows an empty list
    When the user enters "zzznomatch" in the conversation search field
    Then the conversation list is empty
    And the client indicates no conversations were found

  @regression
  Scenario: Clearing the search filter restores the full conversation list
    Given the user has entered "Alice" in the conversation search field
    And the conversation list is filtered to show only matching entries
    When the user clears the search field
    Then the conversation list shows all conversations again

  @regression
  Scenario: Search filter persists while the user is viewing a conversation
    Given the user has entered "Alice" in the conversation search field
    When the user opens the conversation with "Alice"
    And the user returns to the conversation list
    Then the search field still contains "Alice"
    And the conversation list is still filtered to show only matching entries

  # ── Type Filter ────────────────────────────────────────────────────────────

  @smoke
  Scenario: Filtering by type "all" shows all conversations
    When the user sets the conversation type filter to "all"
    Then the conversation list contains both 1:1 conversations and group conversations

  @smoke
  Scenario: Filtering by type "requests" shows only pending invitations
    When the user sets the conversation type filter to "requests"
    Then the conversation list shows only pending invitations
    And "External Group" is visible in the conversation list
    And "Alice" is not visible in the conversation list
    And "Project Room" is not visible in the conversation list

  # ── Sorting ────────────────────────────────────────────────────────────────

  @smoke
  Scenario: Conversations are sorted by most recent activity by default
    When the user views the conversation list with the default sort order
    Then "Alice" appears above "Bob" in the conversation list
    And "Bob" appears above "Project Room" in the conversation list
    And "Project Room" appears above "Team Chat" in the conversation list

  @regression
  Scenario: A new message bumps a conversation to the top of the list
    Given "Team Chat" is at the bottom of the conversation list
    When the user receives a new message in "Team Chat"
    Then "Team Chat" moves to the top of the conversation list

  @regression
  Scenario Outline: Search is case-insensitive
    When the user enters "<search_term>" in the conversation search field
    Then "Project Room" is visible in the conversation list

    Examples:
      | search_term |
      | project     |
      | PROJECT     |
      | Project     |
      | pRoJeCt     |
