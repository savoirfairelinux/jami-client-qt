@conversations
Feature: Conversation Settings and Preferences
  As a user of the client
  I want to view and update conversation settings
  So that I can personalise and control my communication experience

  Background:
    Given the client is running
    And the user is authenticated with a valid account
    And the user has an existing swarm conversation "Project Room" with members "Bob" and "Carol"
    And the user is an admin of "Project Room"
    And the user has an existing 1:1 conversation with "Alice"

  # ── Viewing Info ───────────────────────────────────────────────────────────

  @smoke
  Scenario: View conversation info for a swarm conversation
    When the user opens the settings panel for "Project Room"
    Then the settings panel displays the conversation title "Project Room"
    And the settings panel displays the current description
    And the settings panel displays the member count as 3

  @smoke
  Scenario: View conversation preferences
    When the user opens the settings panel for "Project Room"
    Then the notification preference setting is visible
    And the conversation color setting is visible

  # ── Updating Title and Description ────────────────────────────────────────

  @smoke
  Scenario: An admin can update the title of a swarm conversation
    When the user updates the title of "Project Room" to "New Project Room"
    Then the conversation is retitled to "New Project Room"
    And the conversation list entry reflects the new title "New Project Room"

  @smoke
  Scenario: An admin can update the description of a swarm conversation
    When the user updates the description of "Project Room" to "Our shared workspace"
    Then the conversation description is saved as "Our shared workspace"
    And the settings panel displays the updated description "Our shared workspace"

  @regression
  Scenario: A non-admin member cannot change the title or description
    Given "Bob" is a regular member of "Project Room"
    When the client is acting as "Bob"
    And the user attempts to update the title of "Project Room" to "Hijacked"
    Then the update is rejected
    And the conversation title remains "Project Room"
    And the client indicates the user does not have permission

  # ── Notification Preferences ──────────────────────────────────────────────

  @smoke @regression
  Scenario Outline: Set notification preference for a conversation
    When the user sets the notification preference for "Project Room" to "<preference>"
    Then the notification preference for "Project Room" is saved as "<preference>"
    And the settings panel reflects the "<preference>" setting

    Examples:
      | preference    |
      | all           |
      | mentions only |
      | none          |

  # ── Color / Theme ─────────────────────────────────────────────────────────

  @regression
  Scenario: Set a custom color for a conversation
    When the user sets the conversation color for "Project Room" to "#FF5733"
    Then the conversation color for "Project Room" is saved as "#FF5733"
    And the client applies the color to the conversation view

  # ── History ───────────────────────────────────────────────────────────────

  @regression
  Scenario: Clear conversation history removes displayed messages
    Given "Project Room" has existing messages in the message history
    When the user clears the conversation history for "Project Room"
    Then the message history for "Project Room" is no longer displayed
    And the conversation entry remains in the conversation list

  # ── 1:1 Settings Restrictions ─────────────────────────────────────────────

  @regression
  Scenario: Title and description settings are not available for 1:1 conversations
    When the user opens the settings panel for the 1:1 conversation with "Alice"
    Then the title edit field is not available
    And the description edit field is not available
