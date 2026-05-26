@conversations
Feature: Conversation Creation
  As a user of the client
  I want to start conversations with contacts
  So that I can communicate via 1:1 dialogs and group swarm conversations

  Background:
    Given the client is running
    And the user is authenticated with a valid account
    And the user has at least one registered contact "Alice"

  # ── 1:1 Conversations ──────────────────────────────────────────────────────

  @smoke
  Scenario: Start a 1:1 conversation with a contact
    When the user initiates a new conversation with "Alice"
    Then a 1:1 conversation with "Alice" is opened
    And the conversation is ready to send messages

  @smoke
  Scenario: A new 1:1 conversation appears in the conversation list
    When the user initiates a new conversation with "Alice"
    Then the conversation list contains an entry for "Alice"
    And the entry shows "Alice" as the conversation title

  @regression
  Scenario: Opening the same contact again reuses the existing conversation
    Given the user has an existing 1:1 conversation with "Alice"
    When the user initiates a new conversation with "Alice"
    Then no duplicate conversation is created
    And the existing conversation with "Alice" is opened

  # ── Swarm / Group Conversations ────────────────────────────────────────────

  @smoke
  Scenario: Create a group conversation (swarm) with a single initial member
    Given the user has a registered contact "Bob"
    When the user creates a new group conversation with title "Team Chat"
    And the user adds "Bob" as an initial member
    Then a swarm conversation titled "Team Chat" is created
    And the conversation is ready to send messages

  @smoke
  Scenario: Create a swarm conversation with multiple initial members
    Given the user has registered contacts "Bob", "Carol", and "Dave"
    When the user creates a new group conversation with title "Project Room"
    And the user adds "Bob", "Carol", and "Dave" as initial members
    Then a swarm conversation titled "Project Room" is created
    And the member list contains "Bob", "Carol", and "Dave"

  @smoke
  Scenario: A new swarm conversation appears in the conversation list
    Given the user has a registered contact "Bob"
    When the user creates a new group conversation with title "Team Chat"
    And the user adds "Bob" as an initial member
    Then the conversation list contains an entry titled "Team Chat"

  @regression
  Scenario: Swarm creator is automatically assigned the admin role
    Given the user has a registered contact "Bob"
    When the user creates a new group conversation with title "Admins Only"
    And the user adds "Bob" as an initial member
    Then the user's role in "Admins Only" is "admin"
    And "Bob"'s role in "Admins Only" is "member"

  # ── Error / Edge Cases ─────────────────────────────────────────────────────

  @regression
  Scenario: Attempting to create a group conversation with no members selected is prevented
    When the user attempts to create a new group conversation with no members selected
    Then the creation is prevented
    And the client displays an error indicating at least one member is required

  @regression
  Scenario Outline: Create 1:1 conversations with contacts having various URI formats
    Given the user has a registered contact with URI "<contact_uri>"
    When the user initiates a new conversation with that contact
    Then a 1:1 conversation is opened successfully

    Examples:
      | contact_uri                                                      |
      | ring:abc123def456abc123def456abc123def456abc123def456abc123def456 |
      | jami:abc123def456abc123def456abc123def456abc123def456abc123def456 |
